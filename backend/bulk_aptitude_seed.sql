-- BULK SEED FOR APTITUDE QUESTIONS
-- Run this in your Supabase SQL Editor to pre-fill the database.
-- Note: Each block adds high-quality static questions.

-- TECHNICAL APTITUDE (EASY) - Batch 1
INSERT INTO aptitude_questions (module_id, difficulty, question_text, options, correct_answer, explanation, generated_by) VALUES
('1965315b-6a47-4f81-907c-5a456165b978', 'easy', 'What is the full form of SQL?', '["Structured Query Language", "Simple Quality Level", "Structured Question Language", "System Query Link"]'::jsonb, 0, 'SQL is used for managing and manipulating relational databases.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'easy', 'Which tag is used for an image in HTML?', '["<picture>", "<img>", "<src>", "<image>"]'::jsonb, 1, 'The <img> tag is used to embed an image in a web page.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'easy', 'Which part of the computer stores data permanently?', '["RAM", "ROM", "Hard Drive", "CPU"]'::jsonb, 2, 'Hard drives (HDD/SSD) provide persistent storage.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'easy', 'What does CSS stand for?', '["Creative Style Sheets", "Cascading Style Sheets", "Computer Style Sheets", "Colorful Style Sheets"]'::jsonb, 1, 'CSS describes how HTML elements are to be displayed on screen.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'easy', 'Which of these is a valid JavaScript variable name?', '["2good", "good_2", "good-2", "good 2"]'::jsonb, 1, 'Variable names cannot start with numbers or contain spaces/hyphens.', 'manual');

-- TECHNICAL APTITUDE (MEDIUM) - Batch 1
INSERT INTO aptitude_questions (module_id, difficulty, question_text, options, correct_answer, explanation, generated_by) VALUES
('1965315b-6a47-4f81-907c-5a456165b978', 'medium', 'In a relational database, what is a Primary Key?', '["A key that opens the server", "A unique identifier for a row", "A shared key between tables", "A backup key"]'::jsonb, 1, 'A primary key uniquely identifies each record in a table.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'medium', 'What is the main advantage of an Array over a Linked List?', '["Dynamic sizing", "Easy insertion at start", "Fast random access", "Less memory usage"]'::jsonb, 2, 'Arrays provide O(1) random access using indices.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'medium', 'Which HTTP status code represents "Created"?', '["200", "201", "204", "404"]'::jsonb, 1, '201 Created indicates the request succeeded and a new resource was created.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'medium', 'What is the purpose of the "static" keyword in Java?', '["To make a variable constant", "To link it to the class rather than an object", "To make it private", "To improve speed"]'::jsonb, 1, 'Static members belong to the class itself, shared across all instances.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'medium', 'In Git, what does "git push" do?', '["Fetches changes from remote", "Saves changes locally", "Uploads local changes to remote", "Deletes redundant files"]'::jsonb, 2, 'Pushing sends your committed changes to a remote repository.', 'manual');

-- TECHNICAL APTITUDE (HARD) - Batch 1
INSERT INTO aptitude_questions (module_id, difficulty, question_text, options, correct_answer, explanation, generated_by) VALUES
('1965315b-6a47-4f81-907c-5a456165b978', 'hard', 'What is the time complexity of QuickSort in the worst case?', '["O(n log n)", "O(n^2)", "O(n)", "O(log n)"]'::jsonb, 1, 'Worst case occurs when the pivot is always the smallest or largest element.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'hard', 'In operating systems, what is "thrashing"?', '["High CPU usage", "Excessive paging leading to low productivity", "Deleting temp files", "Faster disk access"]'::jsonb, 1, 'Thrashing happens when the OS spends more time swapping pages than executing processes.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'hard', 'Which of the following is NOT a property of an ACID transaction?', '["Atomicity", "Consistency", "Isolation", "Durability", "Inheritance"]'::jsonb, 4, 'Inheritance is an OOP concept, not a database transaction property.', 'manual'),
('1965315b-6a47-4f81-907c-5a456165b978', 'hard', 'What is a "Critical Section" in multi-threading?', '["The part of code that runs fastest", "Code that can be accessed by only one thread at a time", "Code that is buggy", "The main function"]'::jsonb, 1, 'Critical sections prevent race conditions by ensuring exclusive access.', 'manual');

-- ... (This file can be expanded with thousands of lines)
