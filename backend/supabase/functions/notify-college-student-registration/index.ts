import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { studentId, collegeId, studentName, studentEmail } = await req.json()

    console.log('Notifying college about new student registration:', {
      studentId,
      collegeId,
      studentName,
      studentEmail
    })

    // Get college details
    const { data: college, error: collegeError } = await supabaseClient
      .from('organizations')
      .select('name, email')
      .eq('id', collegeId)
      .single()

    if (collegeError) {
      console.error('Error fetching college:', collegeError)
      throw collegeError
    }

    // Get college admin users
    const { data: admins, error: adminsError } = await supabaseClient
      .from('profiles')
      .select('id, full_name, email')
      .eq('organization_id', collegeId)
      .eq('role', 'college')

    if (adminsError) {
      console.error('Error fetching college admins:', adminsError)
      throw adminsError
    }

    console.log(`Found ${admins?.length || 0} college admins to notify`)

    // Create notification records for each admin
    const notifications = admins?.map(admin => ({
      user_id: admin.id,
      title: 'New Student Registration',
      message: `${studentName} (${studentEmail}) has registered for ${college.name}`,
      type: 'student_registration',
      data: {
        student_id: studentId,
        student_name: studentName,
        student_email: studentEmail,
        college_id: collegeId,
        college_name: college.name
      },
      created_at: new Date().toISOString()
    })) || []

    if (notifications.length > 0) {
      const { error: notificationError } = await supabaseClient
        .from('notifications')
        .insert(notifications)

      if (notificationError) {
        console.error('Error creating notifications:', notificationError)
        throw notificationError
      }

      console.log(`Created ${notifications.length} notifications`)
    }

    // Send email notification if college has email configured
    if (college.email) {
      try {
        // You can integrate with your email service here
        console.log(`Would send email to college: ${college.email}`)
        
        // Example: Send email using Resend or similar service
        // const emailResponse = await fetch('https://api.resend.com/emails', {
        //   method: 'POST',
        //   headers: {
        //     'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
        //     'Content-Type': 'application/json',
        //   },
        //   body: JSON.stringify({
        //     from: 'noreply@yourdomain.com',
        //     to: college.email,
        //     subject: 'New Student Registration',
        //     html: `
        //       <h2>New Student Registration</h2>
        //       <p>A new student has registered for ${college.name}:</p>
        //       <ul>
        //         <li><strong>Name:</strong> ${studentName}</li>
        //         <li><strong>Email:</strong> ${studentEmail}</li>
        //         <li><strong>Registration Time:</strong> ${new Date().toLocaleString()}</li>
        //       </ul>
        //       <p>Please review the student's profile in your dashboard.</p>
        //     `
        //   })
        // })
      } catch (emailError) {
        console.error('Error sending email:', emailError)
        // Don't throw here - notification creation is more important than email
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'College notified successfully',
        notificationsCreated: notifications.length
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Error in notify-college-student-registration:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        success: false 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})