-- Migration 005: Email System and Communication Features
-- This migration adds tables for email logging, invite codes, and communication tracking

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
-- INVITE CODES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS invite_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    college_id UUID NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
    code VARCHAR(20) NOT NULL UNIQUE,
    emails TEXT[] NOT NULL, -- Array of invited email addresses
    max_uses INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB, -- Additional tracking data
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id),
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
    user_id UUID REFERENCES profiles(id),
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
    college_id UUID NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'email', 'sms', 'notification'
    category VARCHAR(50) NOT NULL, -- 'invitation', 'reminder', 'announcement', 'assessment', 'event'
    subject VARCHAR(500),
    body TEXT NOT NULL,
    variables JSONB, -- Available template variables
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES profiles(id)
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
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    college_id UUID NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'email', 'sms', 'notification', 'in_app'
    category VARCHAR(50) NOT NULL,
    subject VARCHAR(500),
    message TEXT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_by UUID REFERENCES profiles(id),
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
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
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
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_code_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies for email_logs
CREATE POLICY "College admins can view their email logs"
    ON email_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM college_members cm
            WHERE cm.user_id = auth.uid()
            AND cm.role IN ('admin', 'placement_officer')
        )
    );

CREATE POLICY "College admins can insert email logs"
    ON email_logs FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM college_members cm
            WHERE cm.user_id = auth.uid()
            AND cm.role IN ('admin', 'placement_officer')
        )
    );

-- RLS Policies for invite_codes
CREATE POLICY "College members can view their invite codes"
    ON invite_codes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM college_members cm
            WHERE cm.user_id = auth.uid()
            AND cm.college_id = invite_codes.college_id
        )
    );

CREATE POLICY "College admins can manage invite codes"
    ON invite_codes FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM college_members cm
            WHERE cm.user_id = auth.uid()
            AND cm.college_id = invite_codes.college_id
            AND cm.role IN ('admin', 'placement_officer')
        )
    );

-- RLS Policies for communication_templates
CREATE POLICY "College members can view their templates"
    ON communication_templates FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM college_members cm
            WHERE cm.user_id = auth.uid()
            AND cm.college_id = communication_templates.college_id
        )
    );

CREATE POLICY "College admins can manage templates"
    ON communication_templates FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM college_members cm
            WHERE cm.user_id = auth.uid()
            AND cm.college_id = communication_templates.college_id
            AND cm.role IN ('admin', 'placement_officer')
        )
    );

-- RLS Policies for student_communications
CREATE POLICY "Students can view their own communications"
    ON student_communications FOR SELECT
    USING (student_id = auth.uid());

CREATE POLICY "College members can view their college communications"
    ON student_communications FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM college_members cm
            WHERE cm.user_id = auth.uid()
            AND cm.college_id = student_communications.college_id
        )
    );

CREATE POLICY "College admins can insert communications"
    ON student_communications FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM college_members cm
            WHERE cm.user_id = auth.uid()
            AND cm.college_id = student_communications.college_id
            AND cm.role IN ('admin', 'placement_officer')
        )
    );

-- RLS Policies for email_preferences
CREATE POLICY "Users can view their own email preferences"
    ON email_preferences FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can update their own email preferences"
    ON email_preferences FOR ALL
    USING (user_id = auth.uid());

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
    user_id_input UUID DEFAULT NULL
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
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Insert default email preferences for existing users
INSERT INTO email_preferences (user_id)
SELECT id FROM profiles
WHERE NOT EXISTS (
    SELECT 1 FROM email_preferences WHERE user_id = profiles.id
)
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE email_logs IS 'Logs all emails sent through the system';
COMMENT ON TABLE invite_codes IS 'Stores invitation codes for student onboarding';
COMMENT ON TABLE invite_code_usage IS 'Tracks usage of invitation codes';
COMMENT ON TABLE communication_templates IS 'Reusable templates for various communications';
COMMENT ON TABLE student_communications IS 'All communications sent to students';
COMMENT ON TABLE email_preferences IS 'User email notification preferences';

-- ============================================================================
-- GRANTS
-- ============================================================================

-- Grant appropriate permissions
GRANT SELECT, INSERT, UPDATE ON email_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE ON invite_codes TO authenticated;
GRANT SELECT, INSERT ON invite_code_usage TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON communication_templates TO authenticated;
GRANT SELECT, INSERT, UPDATE ON student_communications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON email_preferences TO authenticated;

-- Grant sequence permissions if needed
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
