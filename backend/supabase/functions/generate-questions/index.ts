import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
            return new Response(
                JSON.stringify({ error: 'Missing authorization header' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        const supabaseUrl = Deno.env.get('SUPABASE_URL');
        const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');

        if (!supabaseUrl || !supabaseAnonKey) {
            throw new Error('Missing SUPABASE_URL or SUPABASE_ANON_KEY');
        }

        const supabaseClient = createClient(
            supabaseUrl,
            supabaseAnonKey,
            { global: { headers: { Authorization: authHeader } } }
        );

        // Get user
        const token = authHeader.replace(/^Bearer\s+/i, '');
        const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);

        if (userError || !user) {
            console.error('Auth error:', userError);
            return new Response(
                JSON.stringify({ error: 'Unauthorized' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        const { module_id, count = 5, difficulty = 'medium' } = await req.json();

        if (!module_id) {
            throw new Error('Missing module_id');
        }

        // Get module details
        const { data: module, error: moduleError } = await supabaseClient
            .from('aptitude_modules')
            .select('*')
            .eq('id', module_id)
            .single();

        if (moduleError || !module) {
            throw new Error('Module not found');
        }

        // Check if enough questions already exist for this module and difficulty
        const { data: existingQuestions, count: existingCount } = await supabaseClient
            .from('aptitude_questions')
            .select('id', { count: 'exact' })
            .eq('module_id', module_id)
            .eq('difficulty', difficulty)
            .eq('is_active', true);

        if (existingCount && existingCount >= count) {
            console.log(`Found ${existingCount} existing questions for module ${module_id} and difficulty ${difficulty}. Skipping generation.`);

            // Return existing questions instead of just a message
            const { data: questions } = await supabaseClient
                .from('aptitude_questions')
                .select('*')
                .eq('module_id', module_id)
                .eq('difficulty', difficulty)
                .eq('is_active', true)
                .limit(count);

            return new Response(
                JSON.stringify({
                    success: true,
                    message: 'Questions already exist for this module and difficulty',
                    generated: false,
                    questions: questions
                }),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        console.log(`Only found ${existingCount || 0} questions. Generating ${count} new ones...`);

        // Get Gemini API key
        const geminiApiKey = Deno.env.get('GEMINI_API_KEY')?.trim()
            || Deno.env.get('GEMINI_API_KEY\r\n')?.trim()
            || Deno.env.get('GEMINI_API_KEY\n')?.trim();

        if (!geminiApiKey) {
            console.error('No Gemini API key found');
            throw new Error('Gemini API key not configured');
        }

        console.log('Generating questions with Gemini API...');

        // SIMPLE PIPE-DELIMITED FORMAT (no more JSON headaches!)
        const prompt = `Generate ${count} multiple choice questions for ${module.name} (${module.category}) at ${difficulty} difficulty level for aptitude testing.

Requirements:
- Each question must have exactly 4 options
- Questions should be professional and test analytical thinking
- Include a brief explanation for the correct answer

FORMAT (one question per line, pipe-separated):
QUESTION | Option A | Option B | Option C | Option D | CORRECT_INDEX | EXPLANATION

Where CORRECT_INDEX is 0, 1, 2, or 3 (the index of the correct option).

Example:
What is 2+2? | 3 | 4 | 5 | 6 | 1 | Simple addition: 2 plus 2 equals 4

IMPORTANT:
- Return ONLY the questions in this format
- One question per line
- Use | as the separator
- No extra text, no markdown, no explanations
- Return exactly ${count} questions

Begin:`;

        // Call Gemini API with retry logic for rate limits
        let geminiResponse: Response | undefined;
        let retryCount = 0;
        const maxRetries = 5; // Aggressive retries for rate limits

        while (retryCount <= maxRetries) {
            geminiResponse = await fetch(
                `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent`,
                {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'x-goog-api-key': geminiApiKey,
                    },
                    body: JSON.stringify({
                        contents: [{
                            parts: [{
                                text: prompt
                            }]
                        }]
                    }),
                }
            );

            // If successful or not a rate limit error, break
            if (geminiResponse.ok || geminiResponse.status !== 429) {
                break;
            }

            // Rate limited - wait and retry
            retryCount++;
            if (retryCount <= maxRetries) {
                // Aggressive backoff: 2s, 4s, 8s, 16s, 32s
                const waitTime = Math.pow(2, retryCount) * 1000;
                console.log(`Rate limited (429). Retrying in ${waitTime}ms (attempt ${retryCount}/${maxRetries})...`);
                await new Promise(resolve => setTimeout(resolve, waitTime));
            }
        }

        if (!geminiResponse.ok) {
            const errorBody = await geminiResponse.text();
            console.error('Gemini API Error:', {
                status: geminiResponse.status,
                statusText: geminiResponse.statusText,
                body: errorBody,
            });

            if (geminiResponse.status === 429) {
                throw new Error('Gemini API rate limit exceeded. Please wait a moment and try again.');
            }

            throw new Error(`Gemini API error: ${geminiResponse.statusText}`);
        }

        const geminiData = await geminiResponse.json();

        if (!geminiData.candidates?.[0]?.content?.parts?.[0]?.text) {
            console.error('Unexpected Gemini response:', geminiData);
            throw new Error('Invalid response from Gemini API');
        }

        const generatedText = geminiData.candidates[0].content.parts[0].text;

        // Parse the pipe-delimited response (SIMPLE!)
        let responseText = generatedText.trim();

        // Remove markdown code blocks if present
        if (responseText.startsWith('```')) {
            responseText = responseText.replace(/```[a-z]*\n?/g, '').trim();
        }

        console.log('Raw Gemini response:', responseText.substring(0, 500));

        // Parse each line as a question
        const lines = responseText.split('\n').filter(line => line.trim() && line.includes('|'));

        const generatedQuestions = lines.map(line => {
            const parts = line.split('|').map(p => p.trim());

            if (parts.length < 7) {
                console.error('Invalid line format:', line);
                return null;
            }

            return {
                question_text: parts[0],
                options: [parts[1], parts[2], parts[3], parts[4]],
                correct_answer: parseInt(parts[5]),
                explanation: parts[6]
            };
        }).filter(q => q !== null); // Remove any invalid questions

        console.log(`Successfully parsed ${generatedQuestions.length} questions`);

        if (generatedQuestions.length === 0) {
            throw new Error('No valid questions generated');
        }

        // Store questions in database
        const questionsToInsert = generatedQuestions.map((q: any) => ({
            module_id: module_id,
            question_text: q.question_text,
            options: q.options,
            correct_answer: q.correct_answer,
            explanation: q.explanation,
            difficulty: difficulty,
            source_metadata: {
                model: 'gemini-2.0-flash-exp',
                generated_at: new Date().toISOString(),
                prompt_version: '2.0-pipe-delimited',
            },
        }));

        const { data: insertedQuestions, error: insertError } = await supabaseClient
            .from('aptitude_questions')
            .insert(questionsToInsert)
            .select();

        if (insertError) {
            console.error('Insert error:', insertError);
            throw new Error(`Failed to store questions: ${insertError.message}`);
        }

        console.log(`Successfully generated and stored ${insertedQuestions.length} questions`);

        return new Response(
            JSON.stringify({
                success: true,
                message: `Generated ${insertedQuestions.length} questions`,
                questions: insertedQuestions,
                generated: true
            }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );

    } catch (error: any) {
        console.error('Error:', error);
        return new Response(
            JSON.stringify({
                error: error.message || 'Internal server error',
                details: error.toString()
            }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
    }
});
