import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface InviteRequest {
  emails: string[]
  collegeName: string
  inviteLink: string
  customMessage?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { emails, collegeName, inviteLink, customMessage }: InviteRequest = await req.json()

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    // Email template
    const emailTemplate = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Welcome to CareerBridge</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #6EC9F5 0%, #4A90E2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .button { display: inline-block; background: #6EC9F5; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎓 Welcome to CareerBridge!</h1>
            <p>Your journey to career excellence starts here</p>
          </div>
          <div class="content">
            <h2>You're Invited to Join ${collegeName}</h2>
            <p>Hello!</p>
            <p>${collegeName} has invited you to join CareerBridge - the comprehensive platform for skill development, assessments, and placement preparation.</p>
            
            ${customMessage ? `<div style="background: #e3f2fd; padding: 15px; border-radius: 5px; margin: 20px 0;"><strong>Message from ${collegeName}:</strong><br>${customMessage}</div>` : ''}
            
            <h3>🚀 What you'll get:</h3>
            <ul>
              <li>✅ <strong>Skill Assessments</strong> - Validate your technical skills</li>
              <li>✅ <strong>Learning Paths</strong> - Structured skill development</li>
              <li>✅ <strong>Mock Interviews</strong> - AI-powered interview practice</li>
              <li>✅ <strong>Resume Builder</strong> - ATS-friendly resume templates</li>
              <li>✅ <strong>Event Participation</strong> - Hackathons, workshops, and more</li>
              <li>✅ <strong>Placement Tracking</strong> - Monitor your placement journey</li>
            </ul>
            
            <div style="text-align: center;">
              <a href="${inviteLink}" class="button">🎯 Join CareerBridge Now</a>
            </div>
            
            <p><strong>Next Steps:</strong></p>
            <ol>
              <li>Click the button above to create your account</li>
              <li>Complete your profile with academic details</li>
              <li>Take skill assessments to validate your abilities</li>
              <li>Start your learning journey!</li>
            </ol>
            
            <p>Need help? Contact your college placement cell or reply to this email.</p>
          </div>
          <div class="footer">
            <p>This invitation was sent by ${collegeName} through CareerBridge</p>
            <p>© 2024 CareerBridge. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `

    // Send emails using Resend
    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') || 're_YOUR_RESEND_API_KEY'
    
    if (!RESEND_API_KEY) {
      throw new Error('RESEND_API_KEY not configured')
    }

    const emailPromises = emails.map(async (email) => {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: `${collegeName} <noreply@CareerBridge.app>`,
          to: [email],
          subject: `🎓 Welcome to CareerBridge - Invitation from ${collegeName}`,
          html: emailTemplate,
        }),
      })

      if (!response.ok) {
        const error = await response.text()
        throw new Error(`Failed to send email to ${email}: ${error}`)
      }

      return response.json()
    })

    const results = await Promise.all(emailPromises)

    // Log the invitation in database
    await supabaseClient.from('email_logs').insert({
      type: 'student_invitation',
      recipients: emails,
      college_name: collegeName,
      sent_at: new Date().toISOString(),
      status: 'sent',
    })

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Invitations sent to ${emails.length} students`,
        results 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('Error sending invitations:', error)
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