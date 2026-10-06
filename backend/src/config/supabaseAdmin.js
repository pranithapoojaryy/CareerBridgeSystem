const { createClient } = require('@supabase/supabase-js');
const dotenv = require('dotenv');

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceRoleKey) {
    console.warn('⚠️ Missing SUPABASE_SERVICE_ROLE_KEY. Some admin features might fail.');
}

// Client with Service Role (Bypasses RLS) - Use with caution!
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey || 'missing-key');

module.exports = supabaseAdmin;
