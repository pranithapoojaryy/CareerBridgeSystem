
-- Test Certificate Generation
DO $$
DECLARE
    new_cert_id UUID;
    v_student_id UUID;
BEGIN
    -- Get a valid student ID
    SELECT id INTO v_student_id FROM auth.users LIMIT 1;

    -- Insert a test certificate
    INSERT INTO public.student_certifications (
        student_id,
        certificate_name,
        provider_id,
        certificate_url,
        issue_date
    ) VALUES (
        v_student_id,
        'Test Certificate',
        NULL, -- Generic provider
        'https://example.com/cert/123',
        CURRENT_DATE
    ) RETURNING id INTO new_cert_id;

    -- Check the result
    RAISE NOTICE 'Certificate inserted with ID: %', new_cert_id;
END;
$$;
