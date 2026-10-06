const supabaseAdmin = require('../config/supabaseAdmin');

// Simple Scoring Logic (Rule-Based)
const calculateScore = (transcript, durationSeconds, category, keywords) => {
    let score = {
        structure: 0,
        content: 0,
        confidence: 0,
        total: 0
    };

    // 1. Confidence (Duration based)
    // Ideal answer length: 60s - 180s
    if (durationSeconds < 30) {
        score.confidence = 4; // Too short
    } else if (durationSeconds >= 30 && durationSeconds < 60) {
        score.confidence = 7;
    } else if (durationSeconds >= 60 && durationSeconds <= 180) {
        score.confidence = 9;
    } else {
        score.confidence = 8; // Bit long
    }

    // 2. Content (Keyword Matching with Word Boundaries)
    if (keywords && keywords.length > 0 && transcript && transcript.trim().length > 0) {
        const normalizedTranscript = transcript.toLowerCase();
        let matchedCount = 0;

        keywords.forEach(keyword => {
            const normalizedKeyword = keyword.trim().toLowerCase();
            if (normalizedKeyword.length === 0) return;

            // Use word boundaries \b to ensure we match the whole word, not substrings
            // In JS Regex, \b is a word boundary.
            const regex = new RegExp(`\\b${normalizedKeyword}\\b`, 'i');
            if (regex.test(normalizedTranscript)) {
                matchedCount++;
            }
        });

        const matchPercentage = matchedCount / keywords.length;

        // Refined Content Score Thresholds
        if (matchPercentage >= 0.8) score.content = 10;
        else if (matchPercentage >= 0.6) score.content = 8;
        else if (matchPercentage >= 0.4) score.content = 6;
        else if (matchPercentage >= 0.2) score.content = 4;
        else score.content = 2;
    } else {
        // Fallback if no transcript/keywords
        score.content = 5;
    }

    // 3. Structure (Basic Length/Sentence check)
    if (transcript && transcript.split(/[.!?]/).length > 3) {
        score.structure = 8;
    } else {
        score.structure = 5;
    }

    // Calculate Total (Weighted)
    // Content: 40%, Confidence: 30%, Structure: 30%
    score.total = Math.round(
        (score.content * 4) + (score.confidence * 3) + (score.structure * 3)
    );

    // Feedback Generation
    let feedback = [];
    if (score.total >= 90) feedback.push("Outstanding response! You covered all key points with great structure.");
    else if (score.total >= 70) feedback.push("Solid answer. You demonstrated good knowledge of the topic.");
    else if (score.total >= 50) feedback.push("Good effort, but try to be more comprehensive and structured.");
    else feedback.push("Needs improvement. Focus on including more relevant technical terms and practicing your delivery.");

    if (durationSeconds < 30) feedback.push("Consider elongating your answer for more depth.");
    if (durationSeconds > 180) feedback.push("Try to keep your answer concise and within 3 minutes.");

    return { score, feedback: feedback.join(' ') };
};

exports.submitInterview = async (req, res) => {
    try {
        const { studentId, questionId, videoUrl, duration, transcript, categoryName } = req.body;

        if (!studentId || !questionId) {
            return res.status(400).json({ error: 'Missing studentId or questionId' });
        }

        // Fetch question details to get expected keywords
        const { data: questionData, error: qError } = await supabaseAdmin
            .from('interview_questions')
            .select('*')
            .eq('id', questionId)
            .single();

        if (qError) {
            console.error('Error fetching question:', qError);
            // Proceed with defaults if question not found (edge case)
        }

        const keywords = questionData?.expected_keywords || [];

        // Calculate Score
        const { score, feedback } = calculateScore(transcript, duration, categoryName, keywords);

        // Save to Database
        const { data, error } = await supabaseAdmin
            .from('student_interviews')
            .insert([
                {
                    student_id: studentId,
                    question_id: questionId,
                    video_url: videoUrl,
                    duration_seconds: duration,
                    score_json: score,
                    ai_feedback: feedback,
                    status: 'Evaluated'
                }
            ])
            .select();

        if (error) {
            console.error('Supabase Insert Error:', error); // Debug log
            throw error;
        }

        res.status(200).json({ success: true, data: data[0], score: score, feedback: feedback });

    } catch (error) {
        console.error('Interview Submission Error:', error);
        res.status(500).json({ error: 'Failed to process interview submission' });
    }
};

exports.getStudentHistory = async (req, res) => {
    try {
        const { studentId } = req.params;

        const { data, error } = await supabaseAdmin
            .from('student_interviews')
            .select(`
                *,
                interview_questions (
                    question_text,
                    difficulty,
                    interview_categories ( name )
                )
            `)
            .eq('student_id', studentId)
            .order('created_at', { ascending: false });

        if (error) throw error;

        res.status(200).json({ success: true, data: data });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
}
