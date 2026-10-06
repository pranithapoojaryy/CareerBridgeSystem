import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EventInvitationRequest {
  students: Array<{ email: string; full_name: string }>
  eventTitle: string
  eventDetails: string
  registrationLink: string
  eventDate: string
  collegeName: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { 
      students, 
      eventTitle, 
      eventDetails, 
      registrationLink, 
      eventDate, 
      collegeName 
    }: EventInvitationRequest = await req.json()

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    const eventDateTime = new Date(eventDate)
    const formattedEventDate = eventDateTime.toLocaleDateString('en-US', {
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
          <title>Event Invitation</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #A8E6CF 0%, #7FCDCD 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .event-info { background: white; padding: 20px; border-radius: 8px; border-left: 4px solid #A8E6CF; margin: 20px 0; }
            .button { display: inline-block; background: #A8E6CF; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .event-date { background: #e8f5e8; border: 1px solid #A8E6CF; padding: 15px; border-radius: 5px; margin: 20px 0; text-align: center; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🎉 You're Invited!</h1>
              <p>Join us for an exciting event</p>
            </div>
            <div class="content">
              <h2>Hello ${student.full_name}!</h2>
              <p>${collegeName} cordially invites you to participate in our upcoming event.</p>
              
              <div class="event-info">
                <h3>📅 Event Details</h3>
                <p><strong>Event:</strong> ${eventTitle}</p>
                <p><strong>Organized by:</strong> ${collegeName}</p>
                <div style="margin: 15px 0;">
                  <strong>Description:</strong><br>
                  ${eventDetails.replace(/\n/g, '<br>')}
                </div>
              </div>
              
              <div class="event-date">
                <h4>🕒 Event Schedule</h4>
                <p><strong>${formattedEventDate}</strong></p>
                <p>Mark your calendar and don't miss out!</p>
              </div>
              
              <div style="text-align: center;">
                <a href="${registrationLink}" class="button">🎯 Register Now</a>
              </div>
              
              <h3>🌟 Why Attend?</h3>
              <ul>
                <li>✅ <strong>Networking</strong> - Connect with industry professionals</li>
                <li>✅ <strong>Learning</strong> - Gain valuable insights and skills</li>
                <li>✅ <strong>Opportunities</strong> - Discover career prospects</li>
                <li>✅ <strong>Recognition</strong> - Showcase your talents</li>
                <li>✅ <strong>Fun</strong> - Enjoy engaging activities and competitions</li>
              </ul>
              
              <p><strong>Registration Required:</strong> Click the button above to secure your spot. Limited seats available!</p>
              
              <p><strong>Questions?</strong> Contact the event organizers or reply to this email for more information.</p>
            </div>
            <div class="footer">
              <p>This invitation was sent by ${collegeName} through CareerBridge</p>
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
          from: `${collegeName} Events <events@CareerBridge.app>`,
          to: [student.email],
          subject: `🎉 You're Invited: ${eventTitle} - ${eventDateTime.toLocaleDateString()}`,
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
      type: 'event_invitation',
      recipients: students.map(s => s.email),
      event_title: eventTitle,
      college_name: collegeName,
      event_date: eventDate,
      sent_at: new Date().toISOString(),
      status: 'sent',
    })

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Event invitations sent to ${students.length} students`,
        results 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('Error sending event invitations:', error)
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