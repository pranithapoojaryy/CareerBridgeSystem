# 🚀 CareerBridge Database Setup - Step by Step

## ⚠️ IMPORTANT: Run These in Order!

The database setup must be done in **3 simple steps** to avoid dependency issues.

---

## 📋 Step 1: Run Base Schema (REQUIRED FIRST)

This creates the foundation tables that everything else depends on.

**File:** `backend/setup_step_1_base.sql`

**What it creates:**
- ✅ organizations table
- ✅ profiles table (with organization_id)
- ✅ college_departments, college_programs, college_batches
- ✅ Basic RLS policies

**Run this in Supabase SQL Editor first!**

---

## 📋 Step 2: Run Feature Tables

After Step 1 completes successfully, run this.

**File:** `backend/setup_step_2_features.sql`

**What it creates:**
- ✅ Student profiles and related tables
- ✅ Events system
- ✅ Assessment system
- ✅ Skills catalog (with 25+ pre-loaded skills)
- ✅ All indexes for performance

---

## 📋 Step 3: Run Policies and Triggers

Finally, run this to secure everything.

**File:** `backend/setup_step_3_security.sql`

**What it creates:**
- ✅ All RLS policies
- ✅ Update triggers
- ✅ Helper functions

---

## ✅ Verification

After running all 3 steps, verify with:

```sql
-- Check tables created
SELECT COUNT(*) as total_tables 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'profiles', 'organizations', 'student_profiles', 
    'events', 'assessments', 'skills'
);
-- Should return: 6

-- Check skills loaded
SELECT COUNT(*) FROM public.skills;
-- Should return: 25+

-- Check RLS enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'events', 'assessments')
ORDER BY tablename;
-- All should show: t (true)
```

---

## 🚨 Troubleshooting

### If you get "column does not exist" errors:
- Make sure you ran Step 1 first and it completed successfully
- Check for any error messages in the Supabase SQL editor
- Try running each step again in order

### If you get "relation already exists" errors:
- This is OK! The scripts use `IF NOT EXISTS` to be safe
- Just continue to the next step

### If policies fail:
- Make sure the tables exist first (Step 1 and 2)
- Step 3 should be run last

---

## 🎯 Success!

When all 3 steps complete:
- ✅ 20+ tables created
- ✅ 25+ skills pre-loaded
- ✅ RLS enabled on all tables
- ✅ Flutter app can connect and work with real data

**You're ready to use CareerBridge! 🎉**