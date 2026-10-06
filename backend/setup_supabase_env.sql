-- Setup Supabase Environment Variables for Email System
-- Run this in your Supabase SQL Editor or via CLI

-- Set the Resend API key as a Supabase secret
-- This will be available to Edge Functions as process.env.RESEND_API_KEY
SELECT vault.create_secret(
    'RESEND_API_KEY',
    're_YOUR_RESEND_API_KEY',
    'Resend API key for email sending'
);

-- Set other email-related configuration
SELECT vault.create_secret(
    'EMAIL_FROM_DOMAIN',
    'CareerBridge.app',
    'Default domain for sending emails'
);

SELECT vault.create_secret(
    'EMAIL_FROM_NAME',
    'CareerBridge',
    'Default sender name for emails'
);

-- Set app configuration
SELECT vault.create_secret(
    'APP_URL',
    'https://CareerBridge.app',
    'Base URL for the application'
);

-- Verify secrets were created
SELECT name, description, created_at 
FROM vault.secrets 
WHERE name IN ('RESEND_API_KEY', 'EMAIL_FROM_DOMAIN', 'EMAIL_FROM_NAME', 'APP_URL');