import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { ChatGoogleGenerativeAI } from "https://esm.sh/@langchain/google-genai";
import { SystemMessage, HumanMessage, AIMessage } from "https://esm.sh/@langchain/core/messages";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ChatRequest {
    message: string;
    history?: { role: 'user' | 'assistant', content: string }[];
    currentPath?: string;
    think?: boolean;
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
            return new Response(JSON.stringify({ error: 'Missing authorization header' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
        }

        const supabaseUrl = Deno.env.get('SUPABASE_URL');
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const googleApiKey = Deno.env.get('GEMINI_API_KEY') || Deno.env.get('GOOGLE_API_KEY');

        if (!supabaseUrl || !supabaseServiceKey || !googleApiKey) {
            return new Response(JSON.stringify({ error: 'Server Misconfiguration (API Key missing)' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
        }

        const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);
        const token = authHeader.replace(/^Bearer\s+/i, '');
        const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);

        if (userError || !user) {
            return new Response(JSON.stringify({ error: 'Auth Failed' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
        }

        // Fetch User Profile for Role Awareness
        const { data: profile } = await supabaseClient
            .from('profiles')
            .select('role, full_name')
            .eq('id', user.id)
            .single();

        const userRole = profile?.role || 'student';
        const userName = profile?.full_name || 'User';

        const { message, history = [], currentPath, think = false }: ChatRequest = await req.json();

        // Initialize Gemini via LangChain
        const model = new ChatGoogleGenerativeAI({
            apiKey: googleApiKey,
            modelName: "gemini-1.5-pro",
            maxOutputTokens: 1024,
        });

        // Define Role-Aware System Prompts
        const rolePrompts: Record<string, string> = {
            student: `You are CareerBridge AI, a career-focused assistant for students on CareerBridge.
            Student Name: ${userName}
            
            YOUR CAPABILITIES:
            1. NAVIGATION: You can take students to sections. Use [NAVIGATE: /path].
               - Practice Arena (Aptitude/Mock Tests): "/interview-prep"
               - Learning Hub (Courses/Material): "/interview-learning"
               - Question Bank (Browse Questions): "/interview-question"
               - My Profile (Manage data/resume): "/student-profile"
               - Dashboard: "/dashboard"
            2. APP KNOWLEDGE:
               - "Practice Arena": Students can take module-based aptitude tests here.
               - "Mock Tests": Full-length simulated assessments.
               - "Proficiency": Students are scored on a professional scale (Gold, Platinum, etc.) based on test results.
            
            GUIDELINES:
            - If they ask "Where is the practice arena?", reply with help and [NAVIGATE: /interview-prep].
            - Be concise, professional, and helpful.`,

            college_admin: `You are CareerBridge AI, a high-level assistant for College Administrators.
            Admin Name: ${userName}
            
            YOUR CAPABILITIES:
            1. NAVIGATION:
               - Registration Hub (Management): "/college-admin/registrations"
               - Analytics Dashboard (Performance): "/"
               - Drive Management: "/college-admin/drives"
            2. APP KNOWLEDGE:
               - You manage student registrations and verification.
               - You monitor overall college performance and student proficiency scores.
               - You coordinate with recruiters for campus drives.
            
            GUIDELINES:
            - Focus on administrative efficiency and data insights.`,

            recruiter: `You are CareerBridge AI, an elite recruitment assistant for CareerBridge.
            Recruiter Name: ${userName}
            
            YOUR CAPABILITIES:
            1. NAVIGATION:
               - Talent Search (Candidates): "/recruiter/search"
               - Job Postings: "/recruiter/jobs"
               - Applications Review: "/recruiter/applications"
            2. APP KNOWLEDGE:
               - You can search for students based on their "Practice Arena" proficiency scores.
               - The matching algorithm analyzes resumes against job descriptions.
            
            GUIDELINES:
            - Help them find the right talent faster. Be direct and efficiency-oriented.`,
        };

        const systemPrompt = rolePrompts[userRole] || rolePrompts.student;
        let fullSystemPrompt = `${systemPrompt}\n\nCURRENT CONTEXT:\n- Path: ${currentPath || 'Unknown'}\n\nACTION CONTROL:\n1. NAVIGATION: [NAVIGATE: /path]\n2. QUESTION PREVIEW: If the student wants to see a sample question, include [PREVIEW_QUESTION: any] in your response.`;

        if (think) {
            fullSystemPrompt += `\n\nTHINK MODE ACTIVE:\n- You are in high-reasoning mode.\n- Provide detailed, step-by-step career guidance.\n- Use analytical frameworks (e.g., SWOT, SMART goals) if relevant.\n- Focus on LONG-TERM career strategy rather than just app navigation.`;
        }

        const messages = [
            new SystemMessage(fullSystemPrompt),
            ...history.map(m => m.role === 'user' ? new HumanMessage(m.content) : new AIMessage(m.content)),
            new HumanMessage(message)
        ];

        const aiResponse = await model.invoke(messages);
        let reply = aiResponse.content;
        let questionData = null;

        // If AI suggests a question preview, fetch a random one
        if (reply.includes('[PREVIEW_QUESTION:')) {
            const { data: question } = await supabaseClient
                .from('aptitude_questions')
                .select('id, question_text, options, difficulty')
                .limit(1)
                .single();

            if (question) {
                questionData = question;
                reply = reply.replace(/\[PREVIEW_QUESTION:.*?\]/, `[QUESTION_ID: ${question.id}]`);
            }
        }

        return new Response(
            JSON.stringify({
                reply: reply,
                question: questionData,
                role: userRole
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );

    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.error('Error in chat-assistant:', error);
        return new Response(JSON.stringify({ error: message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }
});
