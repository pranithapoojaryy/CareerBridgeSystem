-- Seed Practice Tests for existing modules

DO $$
DECLARE
    logical_id UUID;
    quant_id UUID;
    verbal_id UUID;
    technical_id UUID;
BEGIN
    -- Get Module IDs
    SELECT id INTO logical_id FROM aptitude_modules WHERE name = 'Logical Reasoning' LIMIT 1;
    SELECT id INTO quant_id FROM aptitude_modules WHERE name = 'Quantitative Aptitude' LIMIT 1;
    SELECT id INTO verbal_id FROM aptitude_modules WHERE name = 'Verbal Ability' LIMIT 1;
    SELECT id INTO technical_id FROM aptitude_modules WHERE name = 'Technical Aptitude' LIMIT 1;

    -- Insert Practice Tests if they don't exist
    
    -- Logical Reasoning Practice
    IF logical_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM aptitude_tests WHERE module_id = logical_id AND test_type = 'practice') THEN
            INSERT INTO aptitude_tests (module_id, title, description, duration_minutes, total_questions, passing_score, test_type, difficulty)
            VALUES (logical_id, 'Logical Reasoning Practice', 'Standard practice test for logical reasoning.', 30, 10, 60, 'practice', 'medium');
        END IF;
    END IF;

    -- Quantitative Aptitude Practice
    IF quant_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM aptitude_tests WHERE module_id = quant_id AND test_type = 'practice') THEN
             INSERT INTO aptitude_tests (module_id, title, description, duration_minutes, total_questions, passing_score, test_type, difficulty)
            VALUES (quant_id, 'Quantitative Aptitude Practice', 'Standard practice test for quantitative aptitude.', 45, 15, 60, 'practice', 'medium');
        END IF;
    END IF;

    -- Verbal Ability Practice
    IF verbal_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM aptitude_tests WHERE module_id = verbal_id AND test_type = 'practice') THEN
             INSERT INTO aptitude_tests (module_id, title, description, duration_minutes, total_questions, passing_score, test_type, difficulty)
            VALUES (verbal_id, 'Verbal Ability Practice', 'Standard practice test for verbal ability.', 20, 10, 60, 'practice', 'medium');
        END IF;
    END IF;

    -- Technical Core Practice
    IF technical_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM aptitude_tests WHERE module_id = technical_id AND test_type = 'practice') THEN
             INSERT INTO aptitude_tests (module_id, title, description, duration_minutes, total_questions, passing_score, test_type, difficulty)
            VALUES (technical_id, 'Technical Aptitude Practice', 'Standard practice test for technical concepts.', 60, 20, 60, 'practice', 'medium');
        END IF;
    END IF;

    -- General Knowledge Practice
    DECLARE
        gk_id UUID;
    BEGIN
        SELECT id INTO gk_id FROM aptitude_modules WHERE name = 'General Knowledge' LIMIT 1;
        
        IF gk_id IS NOT NULL THEN
             IF NOT EXISTS (SELECT 1 FROM aptitude_tests WHERE module_id = gk_id AND test_type = 'practice') THEN
                 INSERT INTO aptitude_tests (module_id, title, description, duration_minutes, total_questions, passing_score, test_type, difficulty)
                VALUES (gk_id, 'General Knowledge Practice', 'Standard practice test for GK.', 15, 20, 50, 'practice', 'easy');
            END IF;
        END IF;
    END;

END $$;
