# Project Synopsis

## 1.1 Title of the Project
**CareerBridge: Comprehensive Student-College Management & Placement Platform**

## 1.2 Objective of the Project
The primary objective of CareerBridge is to bridge the gap between academia and industry by creating a unified ecosystem that streamlines the placement process.
Key objectives include:
*   **Automation**: Automating manual tasks like student data collection, resume building, and eligibility filtering.
*   **Validation**: Ensuring the authenticity of student skills and certifications through a Verification Engine.
*   **Connectivity**: Providing a seamless communication channel between Colleges, Students, and Recruiters.
*   **Assessment**: Enabling fair and comprehensive skill evaluation through AI-generated assessments and trusted practice environments.
*   **Analytics**: empowering institutions with real-time data on placement performance and skill gaps.

## 1.3 Project Category
**Web Application / Educational Technology (EdTech) / Human Resources Technology (HRTech)**
Developed as a full-stack solution using modern web technologies.

## 1.4 Software and Hardware requirements

### Software Requirements
*   **Operating System**: Windows 10/11, macOS, or Linux.
*   **Development Framework**: Flutter SDK (Version 3.9.2 or higher).
*   **Programming Language**: Dart (Frontend), TypeScript (Backend Functions), SQL (Database).
*   **Database**: PostgreSQL (via Supabase).
*   **Backend Platform**: Supabase (Backend-as-a-Service).
*   **IDE**: Visual Studio Code or Android Studio.
*   **Browser**: Google Chrome, Microsoft Edge, or Safari (for testing and usage).
*   **Version Control**: Git & GitHub.
*   **External APIs**: Resend (Email), Certification Provider APIs (mocked or real).

### Hardware Requirements
*   **Server**: Cloud-hosted (Serverless architecture).
*   **Client (Development)**:
    *   Processor: Intel Core i5 / AMD Ryzen 5 or better.
    *   RAM: 8GB minimum (16GB recommended).
    *   Storage: 256GB SSD or higher.
    *   Network: Stable broadband internet connection.
*   **Client (User)**:
    *   Device: Desktop, Laptop, Tablet, or Smartphone.
    *   Network: Internet connection (3G/4G/5G/Wi-Fi).

## 1.5 Structure of the program

### 1.5.1 Analysis
*   **Problem Statement**: Traditional placement processes are plagued by manual data entry, unverified student claims, chaotic communication via scattered emails, and difficulty in matching the right student to the right job based on actual skills.
*   **Proposed System**: CareerBridge analyzes these pain points and offers a centralized solution. It integrates a "Trust Score" for certifications, uses AI to generate relevant practice questions, and provides a structured hierarchy (Department -> Program -> Batch) to mirror the physical college structure digitally. The system analyzes user inputs (resumes, test scores) to provide actionable insights.

### 1.5.2 Data Structures
The project utilizes a relational database (PostgreSQL) with support for JSONB to handle semi-structured data. Key data structures include:
*   **Profiles**: Hierarchical user data (Admins, Students, Recruiters) linked via Role-Based Access Control (RBAC).
*   **Organizations**: Nested structure for Colleges and Companies.
*   **Assessments**: structured data for Tests, Questions (MCQ, Coding), and Attempts (Scores, Time taken).
*   **Certifications**: Records linking Students to Providers with metadata like `issue_date`, `valid_until`, and `verification_status`.
*   **Events**: Time-bound objects for Placement Drives and Hackathons.
*   **Skill Trees**: Graph-like structure mapping skills to dependencies and proficiency levels.

### 1.5.3 Module Description
1.  **Authentication & Authorization Module**: Handles secure login, sign-up, email verification, and role-based routing.
2.  **College Management Module**: Allows admins to manage departments, batches, students, and publish events.
3.  **Student Profile & Resume Module**: Enables students to build detailed profiles, upload photos, and generate professional PDF resumes using AI suggestions.
4.  **Certification & Validation Engine**: A core module that validates external certifications (from 16+ providers), calculates skill points, and assigns trust scores.
5.  **Assessment & Practice Module**:
    *   **AI Question Generator**: Creates custom aptitude and technical questions.
    *   **Test Environment**: Secure interface for taking tests with timer libraries.
    *   **Scoring Engine**: auto-grades submissions and updates skill profiles.
6.  **Communication System**: Manages email templates, bulk sending capabilities via Resend, and notification logs.
7.  **Recruiter Portal**: Features for job posting, candidate search (filtering by skill/score), and application tracking.
8.  **Social Feed & Community Module**:
    *   **Student Feed**: Dynamic scrollable feed where students can share achievements, project updates, and certifications.
    *   **Post Interaction**: Supports likes, comments, and sharing to foster peer engagement.
    *   **Content Moderation**: Automated filtering of inappropriate content to maintain a professional environment.
9.  **Networking & Connect Module**:
    *   **Professional Connections**: Allows students to connect with peers, alumni, and recruiters similar to LinkedIn.
    *   **In-App Messaging**: Real-time chat system with socket.io/Supabase Realtime for instant communication.
    *   **Group Discussions**: Topic-based channels for study groups, project collaboration, and placement preparation.

## 1.6 Limitations
*   **Internet Connectivity**: The application requires an active internet connection for real-time features and database access; offline capabilities are currently limited to basic content viewing.
*   **API Dependencies**: Reliance on external APIs (like Resend or Certification Providers) means system functionality can be impacted by third-party downtime.
*   **AI Accuracy**: The relevance of AI-generated questions and resume suggestions depends on the underlying language model's training and may occasionally require manual review.
*   **Verification Scope**: Currently validates digital certificates from specific providers; manual verification is still needed for physical certificates or unsupported providers.

## 1.7 Future scope of the project
*   **Mobile Application**: Development of native iOS and Android apps for better mobile accessibility and push notifications.
*   **Offline Mode improvement**: implementing local database caching (e.g., Hive/Isar) to allow students to take assessments or view content without internet.
*   **Advanced AI Integration**: Implementing AI-driven mock interviews (video/audio) and predictive analytics to forecast placement probability.
*   **Blockchain Verification**: Moving the certification trust system to a blockchain ledger for immutable, decentralized proof of skills.
*   **LMS Integration**: Seamless integration with Learning Management Systems (Canvas, Moodle) to import academic records automatically.
