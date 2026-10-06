# Chapter 2: Software Requirements Specification (SRS)

## 2.1 Introduction
The Software Requirements Specification (SRS) document provides a comprehensive description of the **CareerBridge** platform. It outlines the platform's purpose, functional and non-functional requirements, technical stack, and overall system architecture. This document serves as a blueprint for developers, testers, and stakeholders to ensure the final product aligns with the project's vision of bridging the gap between academia and industry.

## 2.2 Purpose
The purpose of CareerBridge is to provide a unified, AI-enhanced ecosystem where:
- **Students** can build professional identities, validate skills, and discover careers.
- **Colleges** can manage placement activities, track student progress, and verify credentials.
- **Recruiters** can search for verified talent and automate the initial screening process.
The primary goal is to replace fragmented, manual processes with a streamlined, data-driven automation engine.

## 2.3 Scope
The scope includes a full-stack web application featuring an AI Career Assistant (CareerBridge AI), an automated Resume Matching Engine, a Certification Validation system, and a role-based dashboard for three distinct user types.

## 2.4 Functional Requirements
Functional requirements define the specific behaviors and features of the system.

### 2.4.1 Authentication & Identity Module
- **Secure Role-Based Access**: Multi-portal support for Students, College Admins, and Recruiters.
- **Identity Verification**: Email-based registration with role-specific verification steps.

### 2.4.2 Student & Career Module
- **Profile & Digital Identity**: Dynamic profile management including academic history and projects.
- **Verifiable Resume Builder**: Template-based builder that pulls validated data directly from the user profile.
- **Certification Engine**: Support for 16+ certificate providers with automated status tracking.
- **Aptitude Center**: Interactive practice environment with real-time scoring and difficulty adjustment.

### 2.4.3 College & Placement Module
- **Student Data Management**: Bulk management of student records and department-wise reporting.
- **Event Scheduling**: Creation and tracking of Placement Drives and Workshops.
- **Validation Workflow**: A dedicated interface for college admins to approve or reject student certifications.

### 2.4.4 Recruiter & Job Insights Module
- **Job Lifecycle Management**: Tools for posting, editing, and closing job opportunities.
- **AI Matching (Resume Insights)**: Automated analysis of candidate resumes against job-specific requirements using a custom tokenization engine.
- **CareerBridge AI Assistant**: A conversational interface for navigating the platform and fetching real-time data.

### 2.4.5 Networking & Communication Module
- **Connection System**: Professional networking capabilities between students and recruiters.
- **Automated Messaging**: Bulk email notifications (via Resend) for drive updates and application status.

## 2.5 Non-Functional Requirements
Non-functional requirements specify the quality attributes and constraints of the system.

- **Performance**: The platform must handle real-time PDF text extraction and custom algorithmic analysis within 2-3 seconds.
- **Scalability**: The backend (Supabase) must support horizontal scaling as student and job data volumes increase.
- **Reliability**: Use of PostgreSQL transactions to ensure data integrity during complex multi-table updates.
- **Usability**: Responsive design following Material Design 3 principles, ensuring accessibility on mobile, tablet, and desktop.
- **Security**: Row-Level Security (RLS) policies to ensure users can only access data relevant to their role and permissions.

## 2.6 Software Requirements

### 2.6.1 Frontend Technologies
- **Framework**: Flutter (Web/Desktop/Mobile).
- **Language**: Dart.
- **State Management**: Riverpod (Notifier/Provider).
- **Design System**: Material Design 3 with Google Fonts (Outfit).

### 2.6.2 Backend Technologies
- **Cloud Platform**: Supabase (BaaS).
- **Database**: PostgreSQL (Structured data with JSONB support).
- **Serverless Logic**: Deno-based Edge Functions for heavy AI processing and email delivery.
- **Auth**: Supabase Auth (JWT-based).
- **Storage**: Supabase Storage for resumes, profile photos, and project media.

### 2.6.3 Development & Deployment Tools
- **Version Control**: Git and GitHub.
- **CI/CD & Hosting**: Vercel (Frontend), Supabase (Backend).
- **Email Service**: Resend API.
- **Environment**: Visual Studio Code, Flutter DevTools.

## 2.7 System Architecture
CareerBridge follows a **Modular Feature-Based Architecture**:
- **Presentation Layer**: Flutter widgets organized by feature (Auth, Student, Recruiter, etc.).
- **Domain Layer**: Services and logic (e.g., `ResumeMatchingService`, `IdentityHelper`).
- **Data Layer**: Repositories communicating with Supabase via PostgREST and Auth APIs.
- **External Integration**: Edge Functions acting as bridges to third-party services (e.g., Email APIs).

## 2.8 Assumptions and Constraints
- **Reliability of PDF Text**: It is assumed that uploaded PDF resumes are text-searchable and not just image-based scans.
- **Internet Connectivity**: Constant internet access is required as the platform relies heavily on real-time database sync and serverless functions.
- **Browser Compatibility**: Optimized for modern evergreen browsers (Chrome, Safari, Edge).
- **Storage Limits**: Rely on Supabase Free Tier limits unless scaled for production.
