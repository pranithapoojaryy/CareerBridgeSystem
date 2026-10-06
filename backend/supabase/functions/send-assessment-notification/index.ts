import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AssessmentNotificationRequest {
  students: Array<{ email: string; full_name: string }>
  assessmentTitle: string
  assessmentLink: string
  deadline: string
  collegeName: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { 
      students, 
      assessmentTitle, 
      assessmentLink, 
      deadline, 
      collegeName 
    }: AssessmentNotificationRequest = await req.json()

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    const deadlineDate = new Date(deadline)
    const formattedDeadline = deadlineDate.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })

    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') || 're_YOUR_RESEND_API_KEY'
    
    if (!RESEND_API_KEY) {
      throw new Error('RESEND_API_KEY not configured')
    }

    const emailPromises = students.map(async (student) => {
      const emailTemplate = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>New Assessment Assignment</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #FF6B6B 0%, #FF8E53 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .assessment-info { background: white; padding: 20px; border-radius: 8px; border-left: 4px solid #FF6B6B; margin: 20px 0; }
            .button { display: inline-block; background: #FF6B6B; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .deadline { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>📝 New Assessment Assignment</h1>
              <p>You have been assigned a new skill assessment</p>
            </div>
            <div class="content">
              <h2>Hello ${student.full_name}!</h2>
              <p>${collegeName} has assigned you a new assessment to complete.</p>
              
              <div class="assessment-info">
                <h3>📋 Assessment Details</h3>
                <p><strong>Title:</strong> ${assessmentTitle}</p>
                <p><strong>Assigned by:</strong> ${collegeName}</p>
                <p><strong>Status:</strong> Pending</p>
              </div>
              
              <div class="deadline">
                <h4>⏰ Important Deadline</h4>
                <p><strong>Complete by:</strong> ${formattedDeadline}</p>
                <p>Make sure to submit your assessment before the deadline to avoid any penalties.</p>
              </div>
              
              <div style="text-align: center;">
                <a href="${assessmentLink}" class="button">🚀 Start Assessment</a>
              </div>
              
              <h3>💡 Tips for Success:</h3>
              <ul>
                <li>✅ Read all instructions carefully before starting</li>
                <li>✅ Ensure stable internet connection</li>
                <li>✅ Complete in a quiet environment</li>
                <li>✅ Submit before the deadline</li>
                <li>✅ Contact support if you face any technical issues</li>
              </ul>
              
              <p><strong>Need Help?</strong> Contact your college placement cell or reply to this email for assistance.</p>
            </div>
            <div class="footer">
              <p>This assessment was assigned by ${collegeName} through CareerBridge</p>
              <p>© 2024 CareerBridge. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `

      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: `${collegeName} <assessments@CareerBridge.app>`,
          to: [student.email],
          subject: `📝 New Assessment: ${assessmentTitle} - Due ${deadlineDate.toLocaleDateString()}`,
          html: emailTemplate,
        }),
      })

      if (!response.ok) {
        const error = await response.text()
        throw new Error(`Failed to send email to ${student.email}: ${error}`)
      }

      return response.json()
    })

    const results = await Promise.all(emailPromises)

    await supabaseClient.from('email_logs').insert({
      type: 'assessment_notification',
      recipients: students.map(s => s.email),
      assessment_title: assessmentTitle,
      college_name: collegeName,
      deadline: deadline,
      sent_at: new Date().toISOString(),
      status: 'sent',
    })

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Assessment notifications sent to ${students.length} students`,
        results 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('Error sending assessment notifications:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})