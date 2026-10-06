import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface StartTestRequest {
    test_id: string;
    test_type: 'practice' | 'assignment';
    assignment_id?: string;
}

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
        const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        if (!supabaseServiceRoleKey) {
            console.error('Missing SUPABASE_SERVICE_ROLE_KEY');
            // Fallback or error? For now, proceed but it might fail if RLS is the issue.
            // Actually, throw error to be safe.
            throw new Error('Server configuration error: Missing Service Role Key');
        }

        if (!supabaseUrl || !supabaseAnonKey) {
            return new Response(
                JSON.stringify({ error: 'Server Misconfiguration: Missing environment variables' }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        const supabaseClient = createClient(
            supabaseUrl,
            supabaseAnonKey,
            { global: { headers: { Authorization: authHeader } } }
        );

        const adminClient = createClient(
            supabaseUrl,
            supabaseServiceRoleKey
        );

        // Get user - Explicitly pass token to avoid "Auth session missing"
        const token = authHeader.replace(/^Bearer\s+/i, '');
        const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);

        if (userError || !user) {
            console.error('Auth error:', userError);
            return new Response(
                JSON.stringify({ error: 'Auth Failed', details: userError?.message ?? 'No user found' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        const { test_id, test_type, assignment_id }: StartTestRequest = await req.json();

        // Get test details (Use Admin Client to ensure we can see it)
        const { data: test, error: testError } = await adminClient
            .from('aptitude_tests')
            .select('*')
            .eq('id', test_id)
            .single();

        if (testError || !test) {
            return new Response(
                JSON.stringify({ error: 'Test not found' }),
                { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        // Check if assignment test and validate assignment
        if (test_type === 'assignment' && assignment_id) {
            const { data: assignment, error: assignmentError } = await supabaseClient
                .from('test_assignments')
                .select('*')
                .eq('id', assignment_id)
                .single();

            if (assignmentError || !assignment) {
                return new Response(
                    JSON.stringify({ error: 'Assignment not found' }),
                    { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
                );
            }

            // Check deadline
            if (assignment.deadline && new Date(assignment.deadline) < new Date()) {
                return new Response(
                    JSON.stringify({ error: 'Assignment deadline has passed' }),
                    { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
                );
            }

            // Check max attempts
            const { data: attempts, error: attemptsError } = await supabaseClient
                .from('aptitude_attempts')
                .select('attempt_number')
                .eq('test_id', test_id)
                .eq('student_id', user.id)
                .eq('assignment_id', assignment_id);

            if (attemptsError) {
                console.error('Error checking attempts:', attemptsError);
                return new Response(
                    JSON.stringify({ error: 'Failed to verify attempt limit' }),
                    { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
                );
            }

            if (attempts && attempts.length >= (assignment.max_attempts || 1)) {
                return new Response(
                    JSON.stringify({ error: 'You have already completed this assessment.' }),
                    { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
                );
            }
        }

        // STRATEGY: 
        // 1. Try to find questions explicitly linked to this test (created via Test Creator)
        // 2. If none found, fallback to random questions from module (Practice Mode)

        let questionIds: string[] = [];
        let explicitQuestionsFound = false;

        // 1. Check for specific questions (Use Admin Client to bypass RLS)
        // NEW: specific column 'linked_test_id' is much more robust than tags
        const { data: linkedQuestions } = await adminClient
            .from('aptitude_questions')
            .select('id')
            .eq('linked_test_id', test_id)
            .eq('is_active', true);

        if (linkedQuestions && linkedQuestions.length > 0) {
            console.log(`Found ${linkedQuestions.length} specific questions for test ${test_id}`);
            questionIds = linkedQuestions.map((q: any) => q.id);
            explicitQuestionsFound = true;
        } else {
            console.log(`No specific questions found for ${test_id}, falling back to random module selection.`);

            // 2. Fallback: Fetch available questions for this module and difficulty (Admin Client)
            const { data: availableQuestions } = await adminClient
                .from('aptitude_questions')
                .select('id')
                .eq('module_id', test.module_id)
                .eq('difficulty', test.difficulty)
                .eq('is_active', true);

            if (!availableQuestions || availableQuestions.length === 0) {
                console.error(`No questions found for module ${test.module_id} and difficulty ${test.difficulty}`);
                return new Response(
                    JSON.stringify({ error: 'No questions available for this module yet. Please contact administrator.' }),
                    { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
                );
            }

            // Use available questions (pick random subsets)
            const countToPick = Math.min(test.total_questions, availableQuestions.length);
            console.log(`Available: ${availableQuestions.length}, Requested: ${test.total_questions}, Picking: ${countToPick}`);

            questionIds = availableQuestions
                .sort(() => Math.random() - 0.5) // Randomize selection
                .slice(0, countToPick)
                .map((q: any) => q.id);
        }

        // Calculate attempt number
        const { data: previousAttempts } = await supabaseClient
            .from('aptitude_attempts')
            .select('attempt_number')
            .eq('test_id', test_id)
            .eq('student_id', user.id)
            .order('attempt_number', { ascending: false })
            .limit(1);

        const attemptNumber = previousAttempts && previousAttempts.length > 0
            ? previousAttempts[0].attempt_number + 1
            : 1;

        // Shuffle questions if enabled
        if (test.shuffle_questions) {
            questionIds = questionIds.sort(() => Math.random() - 0.5);
        }

        // Create attempt record
        const { data: attempt, error: attemptError } = await supabaseClient
            .from('aptitude_attempts')
            .insert({
                test_id: test_id,
                assignment_id: assignment_id || null,
                student_id: user.id,
                test_type: test_type,
                module_name: test.title,
                difficulty: test.difficulty,
                attempt_number: attemptNumber,
                questions: questionIds,
                total_questions: questionIds.length,
                status: 'in_progress',
                start_time: new Date().toISOString()
            })
            .select()
            .single();

        if (attemptError) {
            console.error('Error creating attempt:', attemptError);
            throw attemptError;
        }

        // Fetch question details (without correct answers)
        const { data: questions, error: questionsError } = await supabaseClient
            .from('aptitude_questions')
            .select('id, question_text, options, difficulty')
            .in('id', questionIds);

        if (questionsError || !questions) {
            console.error('Error fetching questions:', questionsError);
            throw new Error(questionsError?.message || 'Failed to fetch question details');
        }

        // Preserve question order as stored in attempt and filter out any missing ones
        const orderedQuestions = questionIds
            .map((id: string) => questions.find((q: any) => q.id === id))
            .filter(Boolean);

        // Shuffle options if enabled
        if (test.shuffle_options) {
            orderedQuestions.forEach((q: any) => {
                if (q && q.options && Array.isArray(q.options)) {
                    q.shuffled_indices = [...Array(q.options.length).keys()].sort(() => Math.random() - 0.5);
                    q.options = q.shuffled_indices.map((i: number) => q.options[i]);
                }
            });
        }

        return new Response(
            JSON.stringify({
                attempt: {
                    id: attempt.id,
                    test_id: test.id,
                    test_title: test.title,
                    duration_minutes: test.duration_minutes,
                    total_questions: questionIds.length,
                    status: 'in_progress',
                    start_time: attempt.start_time
                },
                questions: orderedQuestions,
                settings: {
                    shuffle_options: test.shuffle_options,
                    negative_marking: test.negative_marking,
                    show_results_immediately: test.show_results_immediately
                }
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );

    } catch (error) {
        console.error('Error in start-test function:', error);
        return new Response(
            JSON.stringify({ error: error.message || 'Internal server error' }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
    }
});
