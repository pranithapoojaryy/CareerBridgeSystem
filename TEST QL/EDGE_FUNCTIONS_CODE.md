# 📧 Edge Functions Code - Copy & Paste for Supabase Cloud

## 🎯 Instructions

For each function below:
1. Go to **Edge Functions** in Supabase Dashboard
2. Click **Create new function**
3. Enter the function name
4. Copy and paste the code
5. Click **Deploy function**

---

## 📧 Function 1: send-student-invites

**Function Name**: `send-student-invites`

**Code**:
```typescript
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
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { emails, collegeName, inviteLink, customMessage }: InviteRequest = await req.json()

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

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
```

---

## 💬 Function 2: send-bulk-message

**Function Name**: `send-bulk-message`

**Code**:
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BulkMessageRequest {
  emails: string[]
  subject: string
  message: string
  senderName: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { emails, subject, message, senderName }: BulkMessageRequest = await req.json()

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    const emailTemplate = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>${subject}</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #6EC9F5 0%, #4A90E2 100%); color: white; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .message { background: white; padding: 20px; border-radius: 5px; border-left: 4px solid #6EC9F5; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📢 Message from ${senderName}</h1>
          </div>
          <div class="content">
            <div class="message">
              ${message.replace(/\n/g, '<br>')}
            </div>
            <p style="margin-top: 20px; color: #666;">
              <strong>From:</strong> ${senderName}<br>
              <strong>Sent:</strong> ${new Date().toLocaleDateString()}
            </p>
          </div>
          <div class="footer">
            <p>This message was sent through CareerBridge</p>
            <p>© 2024 CareerBridge. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `

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
          from: `${senderName} <noreply@CareerBridge.app>`,
          to: [email],
          subject: subject,
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

    await supabaseClient.from('email_logs').insert({
      type: 'bulk_message',
      recipients: emails,
      subject: subject,
      sender_name: senderName,
      sent_at: new Date().toISOString(),
      status: 'sent',
    })

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Message sent to ${emails.length} recipients`,
        results 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('Error sending bulk message:', error)
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
```

---

## 📝 Function 3: send-assessment-notification

**Function Name**: `send-assessment-notification`

**Code**:
```typescript
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
```

---

## 🎉 Function 4: send-event-invitation

**Function Name**: `send-event-invitation`

**Code**:
```typescript
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
```

---

## ✅ After Creating All Functions

1. **Set Environment Variables** in Settings → Edge Functions:
   - `RESEND_API_KEY` = `re_YOUR_RESEND_API_KEY`
   - `EMAIL_FROM_DOMAIN` = `CareerBridge.app`
   - `EMAIL_FROM_NAME` = `CareerBridge`
   - `APP_URL` = `https://CareerBridge.app`

2. **Test Each Function** using the Invoke button with sample data

3. **Check Email Delivery** in Resend dashboard: https://resend.com/emails

4. **Verify Database Logs** in SQL Editor:
   ```sql
   SELECT * FROM email_logs ORDER BY sent_at DESC LIMIT 10;
   ```

**Your email system is now ready! 🎉**