-- check_data_integrity.sql

-- 1. Check total interviews with mock link
select count(*) as interviews_with_mock_id 
from student_interviews 
where mock_attempt_id is not null;

-- 2. Check total mock attempts
select count(*) as total_mock_attempts from mock_attempts;

-- 3. Check Join (Interviews -> Mock Attempts)
select 
  si.id as interview_id,
  si.student_id,
  ma.id as mock_attempt_id,
  ma.mock_id
from student_interviews si
left join mock_attempts ma on si.mock_attempt_id = ma.id
where si.mock_attempt_id is not null
limit 5;

-- 4. Check Join (Mock Attempts -> Mock Definitions)
select 
  ma.id as mock_attempt_id,
  md.title
from mock_attempts ma
left join mock_definitions md on ma.mock_id = md.id
limit 5;
