# CareerBridge Database Setup Guide

## 🚀 Quick Setup (Recommended)

### Option 1: Complete Setup (One Command)
Run this single file in your Supabase SQL Editor:

```sql
-- Copy and paste the entire content of setup_database_complete.sql
-- This will create all tables, indexes, policies, and initial data
```

**File to run:** `setup_database_complete.sql`

---

## 📋 Step-by-Step Setup (Alternative)

If you prefer to run migrations step by step:

### Step 1: Base Tables
```sql
-- Run: migration_001_base_tables.sql
-- Creates: organizations, profiles, college structure
```

### Step 2: Student System
```sql
-- Run: migration_002_student_system.sql  
-- Creates: student profiles, academic records, projects, achievements
```

### Step 3: Events & Assessments
```sql
-- Run: migration_003_events_assessments.sql
-- Creates: skills, events, assessments, questions, attempts
```

### Step 4: Communication & Analytics
```sql
-- Run: migration_004_communication_analytics.sql
-- Creates: announcements, messages, mock interviews, learning paths, analytics
```

---

## 🗄️ Database Schema Overview

### Core Tables (20+ tables created)

#### **User Management**
- `profiles` - Enhanced user profiles with role-based access
- `organizations` - College/University information
- `college_departments` - Academic departments
- `college_programs` - Degree programs
- `college_batches` - Student batches/years

#### **Student System**
- `student_profiles` - Comprehensive student data
- `student_academic_records` - Academic history (10th, 12th, UG, PG)
- `student_external_profiles` - GitHub, LeetCode, etc. integrations
- `student_projects` - Project portfolio
- `student_achievements` - Certifications, awards, competitions

#### **Events Management**
- `events` - Hackathons, workshops, guest lectures
- `event_registrations` - Student registrations and attendance

#### **Skill Assessment**
- `skills` - Master skills catalog (25+ pre-loaded)
- `assessments` - Skill tests and evaluations
- `questions` - Question bank for assessments
- `assessment_attempts` - Student test attempts
- `student_skill_validations` - Verified skills

#### **Learning & Development**
- `learning_paths` - Structured learning tracks
- `learning_modules` - Course content and materials
- `student_learning_progress` - Progress tracking

#### **Communication**
- `announcements` - College announcements
- `messages` - Direct messaging system
- `mock_interviews` - Interview practice sessions

#### **Analytics**
- `student_activity_logs` - Activity tracking
- `college_analytics` - Performance metrics

---

## 🔐 Security Features

### Row Level Security (RLS)
- **Enabled on all tables** for data protection
- **Role-based access control** (Student, College Admin, Recruiter)
- **Organization-level isolation** (colleges can only see their data)

### Key Policies
- Students can only access their own data
- College admins can manage their college's data
- Cross-organization data is protected
- Public data (skills, published events) is accessible to all

---

## 📊 Pre-loaded Data

### Skills Catalog (25+ skills)
- **Programming:** Python, Java, JavaScript, C++, TypeScript
- **Web Development:** React, Angular, Vue.js, Node.js, Django
- **Mobile:** Flutter, React Native, Android, iOS
- **Data Science:** Machine Learning, Pandas, NumPy
- **Databases:** SQL, MySQL, PostgreSQL, MongoDB
- **Soft Skills:** Communication, Leadership, Problem Solving, Teamwork

---

## 🔧 Performance Optimizations

### Indexes Created
- **Search optimization** on names, emails, skills
- **Filter optimization** on departments, batches, status
- **Date range queries** for events and analytics
- **Foreign key relationships** for joins

### Triggers
- **Auto-update timestamps** on record changes
- **Profile completion calculation** 
- **Activity logging** for analytics

---

## 🧪 Testing the Setup

### 1. Verify Tables Created
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%student%' OR table_name LIKE '%event%' OR table_name LIKE '%assessment%'
ORDER BY table_name;
```

### 2. Check Skills Data
```sql
SELECT name, category, subcategory 
FROM public.skills 
ORDER BY category, name;
```

### 3. Verify RLS Policies
```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

---

## 🚨 Troubleshooting

### Common Issues

#### 1. "Column does not exist" Error
**Solution:** Run the complete setup file instead of individual migrations, or ensure you run migrations in order.

#### 2. "Permission denied" Error  
**Solution:** Make sure you're running the SQL as a database admin in Supabase.

#### 3. "Relation already exists" Error
**Solution:** This is normal - the script uses `IF NOT EXISTS` to handle existing tables safely.

#### 4. Foreign Key Constraint Error
**Solution:** Ensure base tables (organizations, profiles) exist before running dependent migrations.

### Verification Commands

```sql
-- Check if all main tables exist
SELECT COUNT(*) as table_count 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'profiles', 'organizations', 'student_profiles', 
    'events', 'assessments', 'skills', 'messages'
);
-- Should return 7

-- Check skills data loaded
SELECT COUNT(*) as skills_count FROM public.skills;
-- Should return 25+

-- Check RLS enabled
SELECT COUNT(*) as rls_enabled_tables
FROM information_schema.tables t
JOIN pg_class c ON c.relname = t.table_name
WHERE t.table_schema = 'public' 
AND c.relrowsecurity = true;
-- Should return 20+
```

---

## 🎯 Next Steps

After successful database setup:

1. **Test the Flutter App** - Events and Assessments should now work with real data
2. **Create Sample Data** - Add test events, assessments, and students
3. **Configure Authentication** - Ensure user roles are properly set
4. **Test Features** - Create events, assessments, manage students

---

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify you're using the latest Supabase version
3. Ensure proper database permissions
4. Check the Supabase logs for detailed error messages

---

## 🎉 Success Indicators

✅ **Database Setup Complete When:**
- All 20+ tables created successfully
- 25+ skills pre-loaded
- RLS policies active on all tables
- No foreign key constraint errors
- Flutter app connects without errors

**You're now ready to use the full CareerBridge platform! 🚀**