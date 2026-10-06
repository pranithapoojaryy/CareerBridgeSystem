-- Create student_projects table
CREATE TABLE IF NOT EXISTS student_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  technologies TEXT[], -- Array of tech stack
  project_url TEXT, -- Live/demo link
  github_url TEXT,
  media_urls TEXT[], -- Images/videos stored in Supabase Storage
  start_date DATE,
  end_date DATE,
  is_ongoing BOOLEAN DEFAULT false,
  posted_to_feed BOOLEAN DEFAULT false,
  feed_post_id UUID REFERENCES feed_posts(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add index for faster queries
CREATE INDEX idx_student_projects_student_id ON student_projects(student_id);
CREATE INDEX idx_student_projects_created_at ON student_projects(created_at DESC);

-- Enable RLS
ALTER TABLE student_projects ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Students can view their own projects
CREATE POLICY "Students can view own projects"
  ON student_projects
  FOR SELECT
  USING (auth.uid() = student_id);

-- Students can create their own projects
CREATE POLICY "Students can create own projects"
  ON student_projects
  FOR INSERT
  WITH CHECK (auth.uid() = student_id);

-- Students can update their own projects
CREATE POLICY "Students can update own projects"
  ON student_projects
  FOR UPDATE
  USING (auth.uid() = student_id)
  WITH CHECK (auth.uid() = student_id);

-- Students can delete their own projects
CREATE POLICY "Students can delete own projects"
  ON student_projects
  FOR DELETE
  USING (auth.uid() = student_id);

-- Anyone can view projects that have been posted to feed (for social feed display)
CREATE POLICY "Anyone can view public projects"
  ON student_projects
  FOR SELECT
  USING (posted_to_feed = true);

-- Create storage bucket for project media
INSERT INTO storage.buckets (id, name, public)
VALUES ('project-media', 'project-media', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for project media
CREATE POLICY "Students can upload project media"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'project-media' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Students can update their project media"
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'project-media' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Students can delete their project media"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'project-media' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Anyone can view project media"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'project-media');
