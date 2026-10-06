-- Fixed Email System Migration - No Dependencies
-- This migration creates email tables without requiring other tables to exist

-- ============================================================================
-- EMAIL LOGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS email_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) NOT NULL, -- 'student_invitation', 'bulk_message', 'assessment_notification', 'event_invitation'
    recipients TEXT[] NOT NULL, -- Array of email addresses
    subject VARCHAR(500),
    college_name VARCHAR(255),
    sender_name VARCHAR(255),
    assessment_title VARCHAR(255),
    event_title VARCHAR(255),
    deadline TIMESTAMPTZ,
    event_date TIMESTAMPTZ,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'sent', -- 'sent', 'failed', 'bounced'
    error_message TEXT,
    metadata JSONB, -- Additional data like open rates, click rates, etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for email_logs
CREATE INDEX IF NOT EXISTS idx_email_logs_type ON email_logs(type);
CREATE INDEX IF NOT EXISTS idx_email_logs_sent_at ON email_logs(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_email_logs_status ON email_logs(status);
CREATE INDEX IF NOT EXISTS idx_email_logs_recipients ON email_logs USING GIN(recipients);

-- ============================================================================
-- INVITE CODES TABLE (No foreign key constraints)
-- ============================================================================
CREATE TABLE IF NOT EXISTS invite_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    college_id VARCHAR(255) NOT NULL, -- Changed from UUID with FK to simple VARCHAR
    code VARCHAR(20) NOT NULL UNIQUE,
    emails TEXT[] NOT NULL, -- Array of invited email addresses
    max_uses INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB, -- Additional tracking data
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255), -- Changed from UUID with FK to simple VARCHAR
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for invite_codes
CREATE INDEX IF NOT EXISTS idx_invite_codes_college ON invite_codes(college_id);
CREATE INDEX IF NOT EXISTS idx_invite_codes_code ON invite_codes(code);
CREATE INDEX IF NOT EXISTS idx_invite_codes_expires_at ON invite_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_invite_codes_is_active ON invite_codes(is_active);

-- ============================================================================
-- INVITE CODE USAGE TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS invite_code_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invite_code_id UUID NOT NULL REFERENCES invite_codes(id) ON DELETE CASCADE,
    user_id VARCHAR(255), -- Changed from UUID with FK to simple VARCHAR
    email VARCHAR(255) NOT NULL,
    used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    metadata JSONB
);

-- Indexes for invite_code_usage
CREATE INDEX IF NOT EXISTS idx_invite_code_usage_code ON invite_code_usage(invite_code_id);
CREATE INDEX IF NOT EXISTS idx_invite_code_usage_user ON invite_code_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_invite_code_usage_email ON invite_code_usage(email);

-- ============================================================================
-- COMMUNICATION TEMPLATES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS communication_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    college_id VARCHAR(255) NOT NULL, -- Changed from UUID with FK to simple VARCHAR
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'email', 'sms', 'notification'
    category VARCHAR(50) NOT NULL, -- 'invitation', 'reminder', 'announcement', 'assessment', 'event'
    subject VARCHAR(500),
    body TEXT NOT NULL,
    variables JSONB, -- Available template variables
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255), -- Changed from UUID with FK to simple VARCHAR
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by VARCHAR(255) -- Changed from UUID with FK to simple VARCHAR
);

-- Indexes for communication_templates
CREATE INDEX IF NOT EXISTS idx_comm_templates_college ON communication_templates(college_id);
CREATE INDEX IF NOT EXISTS idx_comm_templates_type ON communication_templates(type);
CREATE INDEX IF NOT EXISTS idx_comm_templates_category ON communication_templates(category);
CREATE INDEX IF NOT EXISTS idx_comm_templates_is_active ON communication_templates(is_active);

-- ============================================================================
-- STUDENT COMMUNICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS student_communications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id VARCHAR(255) NOT NULL, -- Changed from UUID with FK to simple VARCHAR
    college_id VARCHAR(255) NOT NULL, -- Changed from UUID with FK to simple VARCHAR
    type VARCHAR(50) NOT NULL, -- 'email', 'sms', 'notification', 'in_app'
    category VARCHAR(50) NOT NULL,
    subject VARCHAR(500),
    message TEXT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_by VARCHAR(255), -- Changed from UUID with FK to simple VARCHAR
    read_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'sent', -- 'sent', 'delivered', 'read', 'failed'
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for student_communications
CREATE INDEX IF NOT EXISTS idx_student_comms_student ON student_communications(student_id);
CREATE INDEX IF NOT EXISTS idx_student_comms_college ON student_communications(college_id);
CREATE INDEX IF NOT EXISTS idx_student_comms_type ON student_communications(type);
CREATE INDEX IF NOT EXISTS idx_student_comms_sent_at ON student_communications(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_student_comms_status ON student_communications(status);

-- ============================================================================
-- EMAIL PREFERENCES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS email_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255) NOT NULL UNIQUE, -- Changed from UUID with FK to simple VARCHAR
    receive_invitations BOOLEAN DEFAULT TRUE,
    receive_assessments BOOLEAN DEFAULT TRUE,
    receive_events BOOLEAN DEFAULT TRUE,
    receive_announcements BOOLEAN DEFAULT TRUE,
    receive_reminders BOOLEAN DEFAULT TRUE,
    receive_marketing BOOLEAN DEFAULT FALSE,
    email_frequency VARCHAR(20) DEFAULT 'immediate', -- 'immediate', 'daily', 'weekly'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for email_preferences
CREATE INDEX IF NOT EXISTS idx_email_prefs_user ON email_preferences(user_id);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

-- Trigger for email_logs
CREATE OR REPLACE FUNCTION update_email_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_email_logs_updated_at
    BEFORE UPDATE ON email_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_email_logs_updated_at();

-- Trigger for invite_codes
CREATE OR REPLACE FUNCTION update_invite_codes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invite_codes_updated_at
    BEFORE UPDATE ON invite_codes
    FOR EACH ROW
    EXECUTE FUNCTION update_invite_codes_updated_at();

-- Trigger for communication_templates
CREATE OR REPLACE FUNCTION update_communication_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_communication_templates_updated_at
    BEFORE UPDATE ON communication_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_communication_templates_updated_at();

-- Trigger for email_preferences
CREATE OR REPLACE FUNCTION update_email_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_email_preferences_updated_at
    BEFORE UPDATE ON email_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_email_preferences_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - Simplified
-- ============================================================================

-- Enable RLS
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_code_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_preferences ENABLE ROW LEVEL SECURITY;

-- Simple RLS Policies - Allow all operations for authenticated users
CREATE POLICY "Allow all for authenticated users" ON email_logs FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all for authenticated users" ON invite_codes FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all for authenticated users" ON invite_code_usage FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all for authenticated users" ON communication_templates FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all for authenticated users" ON student_communications FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all for authenticated users" ON email_preferences FOR ALL USING (auth.role() = 'authenticated');

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to check if invite code is valid
CREATE OR REPLACE FUNCTION is_invite_code_valid(code_input VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    code_record RECORD;
BEGIN
    SELECT * INTO code_record
    FROM invite_codes
    WHERE code = code_input
    AND is_active = TRUE
    AND expires_at > NOW()
    AND current_uses < max_uses;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to use invite code
CREATE OR REPLACE FUNCTION use_invite_code(
    code_input VARCHAR,
    user_email VARCHAR,
    user_id_input VARCHAR DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    code_record RECORD;
BEGIN
    -- Get the invite code
    SELECT * INTO code_record
    FROM invite_codes
    WHERE code = code_input
    AND is_active = TRUE
    AND expires_at > NOW()
    AND current_uses < max_uses
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if email is in the invited list
    IF NOT (user_email = ANY(code_record.emails)) THEN
        RETURN FALSE;
    END IF;
    
    -- Record the usage
    INSERT INTO invite_code_usage (invite_code_id, user_id, email)
    VALUES (code_record.id, user_id_input, user_email);
    
    -- Increment usage count
    UPDATE invite_codes
    SET current_uses = current_uses + 1
    WHERE id = code_record.id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SAMPLE DATA FOR TESTING
-- ============================================================================

-- Insert a sample communication template
INSERT INTO communication_templates (
    college_id,
    name,
    type,
    category,
    subject,
    body,
    variables,
    created_by
) VALUES (
    'demo-college',
    'Student Welcome Email',
    'email',
    'invitation',
    'Welcome to {{college_name}}',
    'Hello {{student_name}}, welcome to our platform!',
    '{"college_name": "string", "student_name": "string"}'::jsonb,
    'system'
) ON CONFLICT DO NOTHING;

-- Insert sample email preferences
INSERT INTO email_preferences (user_id) 
VALUES ('demo-user-1'), ('demo-user-2'), ('demo-user-3')
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if all tables were created
DO $$
BEGIN
    RAISE NOTICE 'Email system tables created successfully:';
    RAISE NOTICE '- email_logs: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'email_logs');
    RAISE NOTICE '- invite_codes: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'invite_codes');
    RAISE NOTICE '- invite_code_usage: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'invite_code_usage');
    RAISE NOTICE '- communication_templates: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'communication_templates');
    RAISE NOTICE '- student_communications: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'student_communications');
    RAISE NOTICE '- email_preferences: %', (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'email_preferences');
    RAISE NOTICE 'Email system setup completed successfully!';
END $$;