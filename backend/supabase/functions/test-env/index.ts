// Quick test to verify if GEMINI_API_KEY is accessible
// Deploy this as a temporary edge function to test

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        // Check if GEMINI_API_KEY is accessible
        const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
        const supabaseUrl = Deno.env.get('SUPABASE_URL');
        const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');

        return new Response(
            JSON.stringify({
                status: 'Environment Check',
                gemini_key_exists: !!geminiApiKey,
                gemini_key_length: geminiApiKey ? geminiApiKey.length : 0,
                gemini_key_preview: geminiApiKey ? `${geminiApiKey.substring(0, 10)}...` : 'NOT SET',
                supabase_url_exists: !!supabaseUrl,
                supabase_anon_key_exists: !!supabaseAnonKey,
                all_env_vars: Object.keys(Deno.env.toObject()).sort(),
            }, null, 2),
            {
                status: 200,
                headers: {
                    ...corsHeaders,
                    'Content-Type': 'application/json'
                }
            }
        );
    } catch (error) {
        return new Response(
            JSON.stringify({
                error: error.message,
                stack: error.stack
            }),
            {
                status: 500,
                headers: {
                    ...corsHeaders,
                    'Content-Type': 'application/json'
                }
            }
        );
    }
});
