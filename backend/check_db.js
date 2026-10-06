const supabase = require('./src/config/supabase');

async function checkSetup() {
    console.log('Checking Supabase connection...');

    try {
        // Check if we can connect and if 'profiles' table exists
        const { data: profiles, error: profilesError } = await supabase
            .from('profiles')
            .select('count')
            .limit(1);

        if (profilesError) {
            console.error('❌ Error accessing "profiles" table:', profilesError.message);
        } else {
            console.log('✅ "profiles" table is accessible.');
        }

        // Check if 'student_profiles' table exists
        const { data: students, error: studentsError } = await supabase
            .from('student_profiles')
            .select('count')
            .limit(1);

        if (studentsError) {
            console.error('❌ Error accessing "student_profiles" table:', studentsError.message);
        } else {
            console.log('✅ "student_profiles" table is accessible.');
        }

    } catch (err) {
        console.error('❌ Unexpected error:', err);
    }
}

checkSetup();
