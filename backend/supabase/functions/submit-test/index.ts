import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface SubmitTestRequest {
    attempt_id: string;
    answers: Record<string, number>; // question_id -> selected_option_index
    time_per_question?: Record<string, number>;
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

        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
        const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

        // Client for Auth Verification (User context)
        const supabaseClient = createClient(
            supabaseUrl,
            supabaseAnonKey,
            { global: { headers: { Authorization: authHeader } } }
        );

        // Client for Database Operations (Admin context)
        const supabaseAdmin = createClient(
            supabaseUrl,
            supabaseServiceRoleKey
        );

        // Verify User
        const token = authHeader.replace(/^Bearer\s+/i, '');
        const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token);
        if (userError || !user) {
            console.error('Auth User Error:', userError);
            return new Response(
                JSON.stringify({ error: 'Unauthorized', details: userError?.message }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        const { attempt_id, answers, time_per_question }: SubmitTestRequest = await req.json();

        // Get attempt details
        const { data: attempt, error: attemptError } = await supabaseAdmin
            .from('aptitude_attempts')
            .select('*')
            .eq('id', attempt_id)
            .eq('student_id', user.id)
            .single();

        if (attemptError || !attempt) {
            return new Response(
                JSON.stringify({ error: 'Attempt not found' }),
                { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        if (attempt.status === 'completed' || attempt.status === 'submitted') {
            return new Response(
                JSON.stringify({ error: 'Test already submitted' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        // Get test details
        const { data: test, error: testError } = await supabaseAdmin
            .from('aptitude_tests')
            .select('*')
            .eq('id', attempt.test_id)
            .single();

        if (testError || !test) {
            return new Response(
                JSON.stringify({ error: 'Test not found' }),
                { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        // Get all questions with correct answers
        const questionIds = attempt.questions as string[];
        const { data: questions, error: questionsError } = await supabaseAdmin
            .from('aptitude_questions')
            .select('*')
            .in('id', questionIds);

        if (questionsError || !questions) {
            return new Response(
                JSON.stringify({ error: 'Questions not found' }),
                { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
        }

        // Calculate scores
        let correctAnswers = 0;
        let incorrectAnswers = 0;
        let attemptedQuestions = 0;

        const questionMap = new Map(questions.map(q => [q.id, q]));

        for (const questionId of questionIds) {
            const question = questionMap.get(questionId);
            if (!question) continue;

            const studentAnswer = answers[questionId];

            if (studentAnswer !== undefined && studentAnswer !== null) {
                attemptedQuestions++;

                if (studentAnswer === question.correct_answer) {
                    correctAnswers++;
                } else {
                    incorrectAnswers++;
                }
            }
        }

        const unanswered = attempt.total_questions - attemptedQuestions;

        // Calculate score
        let score = correctAnswers;

        // Apply negative marking if enabled
        if (test.negative_marking) {
            score -= incorrectAnswers * test.negative_marks_per_question;
            score = Math.max(0, score); // Don't allow negative total score
        }

        const maxScore = attempt.total_questions;
        const percentage = (score / maxScore) * 100;

        // Calculate duration
        const endTime = new Date();
        const startTime = new Date(attempt.start_time);
        const durationSeconds = Math.floor((endTime.getTime() - startTime.getTime()) / 1000);

        // Update attempt record
        const { data: updatedAttempt, error: updateError } = await supabaseAdmin
            .from('aptitude_attempts')
            .update({
                answers: answers,
                time_per_question: time_per_question || {},
                attempted_questions: attemptedQuestions,
                correct_answers: correctAnswers,
                incorrect_answers: incorrectAnswers,
                unanswered: unanswered,
                score: score,
                percentage: percentage,
                status: 'completed',
                end_time: endTime.toISOString(),
                submitted_at: endTime.toISOString(),
                duration_seconds: durationSeconds
            })
            .eq('id', attempt_id)
            .select()
            .single();

        if (updateError) {
            throw updateError;
        }

        // Prepare detailed results
        const results = questionIds.map(questionId => {
            const question = questionMap.get(questionId);
            const studentAnswer = answers[questionId];

            return {
                question_id: questionId,
                question_text: question?.question_text,
                options: question?.options,
                student_answer: studentAnswer,
                correct_answer: test.show_correct_answers ? question?.correct_answer : undefined,
                is_correct: studentAnswer === question?.correct_answer,
                explanation: test.show_correct_answers ? question?.explanation : undefined,
                time_spent: time_per_question?.[questionId] || 0
            };
        });

        return new Response(
            JSON.stringify({
                attempt_id: attempt_id,
                score: score,
                percentage: percentage.toFixed(2),
                correct_answers: correctAnswers,
                incorrect_answers: incorrectAnswers,
                unanswered: unanswered,
                total_questions: attempt.total_questions,
                duration_seconds: durationSeconds,
                test_type: attempt.test_type,
                results: test.show_results_immediately ? results : undefined,
                message: percentage >= test.passing_score
                    ? 'Congratulations! You passed the test.'
                    : 'Keep practicing to improve your score!'
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );

    } catch (error) {
        console.error('Error in submit-test function:', error);
        return new Response(
            JSON.stringify({ error: error.message || 'Internal server error' }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
    }
});
