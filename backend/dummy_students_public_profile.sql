-- Insert Dummy Students for CareerBridge Academy (6984606b-f491-40cb-9984-696ee22ef86d)
INSERT INTO public.profiles (id, email, role, full_name, headline, organization_id, is_verified, profile_completion, created_at, updated_at)
VALUES 
  (gen_random_uuid(), 'student1@CareerBridge.com', 'student', 'Aarav Patel', 'Aspiring Flutter Developer | CS Undergrad', '6984606b-f491-40cb-9984-696ee22ef86d', true, 80, NOW(), NOW()),
  (gen_random_uuid(), 'student2@CareerBridge.com', 'student', 'Zara Khan', 'AI/ML Enthusiast | Python Developer', '6984606b-f491-40cb-9984-696ee22ef86d', true, 60, NOW(), NOW()),
  (gen_random_uuid(), 'student3@CareerBridge.com', 'student', 'Vihaan Singh', 'Full Stack Web Developer (React/Node)', '6984606b-f491-40cb-9984-696ee22ef86d', false, 40, NOW(), NOW()),
  (gen_random_uuid(), 'student4@CareerBridge.com', 'student', 'Ananya Gupta', 'UI/UX Designer & Frontend Dev', '6984606b-f491-40cb-9984-696ee22ef86d', true, 90, NOW(), NOW()),
  (gen_random_uuid(), 'student5@CareerBridge.com', 'student', 'Rohan Das', 'Competitive Programmer | C++', '6984606b-f491-40cb-9984-696ee22ef86d', false, 50, NOW(), NOW());

-- Insert Dummy Students for Heartware (a8ab05df-8a33-4950-924f-3b5375c45a88)
INSERT INTO public.profiles (id, email, role, full_name, headline, organization_id, is_verified, profile_completion, created_at, updated_at)
VALUES 
  (gen_random_uuid(), 'student1@heartware.com', 'student', 'Emily Chen', 'Biomedical Engineering Student', 'a8ab05df-8a33-4950-924f-3b5375c45a88', true, 75, NOW(), NOW()),
  (gen_random_uuid(), 'student2@heartware.com', 'student', 'Michael Brown', 'Data Science Intern', 'a8ab05df-8a33-4950-924f-3b5375c45a88', true, 85, NOW(), NOW());
