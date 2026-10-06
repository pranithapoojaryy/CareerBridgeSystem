// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

declare const Deno: any;

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

serve(async (req: Request) => {
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

    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY') || ''
    
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
        const errorText = await response.text()
        throw new Error(`Failed to send email to ${email}: ${errorText}`)
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
    const errorMessage = error instanceof Error ? error.message : String(error)
    console.error('Error sending bulk message:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: errorMessage 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})