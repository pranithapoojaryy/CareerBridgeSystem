# Chapter 1: Synopsis

## 1.1 Title of the Project
**CareerBridge: Comprehensive Student-College Management & Placement Platform**

## 1.2 Objective of the Project
The primary objective of CareerBridge is to bridge the gap between academia and industry by creating a unified ecosystem that streamlines the placement process.
Key objectives include:
*   **Automation**: Automating manual tasks like student data collection, resume building, and eligibility filtering.
*   **Validation**: Ensuring the authenticity of student skills and certifications through a Verification Engine.
*   **Connectivity**: Providing a seamless communication channel between Colleges, Students, and Recruiters.
*   **Assessment**: Enabling fair and comprehensive skill evaluation through AI-generated assessments and trusted practice environments.
*   **Analytics**: Empowering institutions with real-time data on placement performance and skill gaps.

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
The CareerBridge platform follows a feature-based architecture with separate frontend and backend layers:

### 1.5.1 Frontend Architecture
Built with **Flutter**, the frontend uses:
- **Riverpod** for robust state management.
- **Feature-based structure** for scalability (Auth, College, Student, Resume, Aptitude, etc.).
- **Material Design 3** for a modern, responsive UI.

### 1.5.2 Module Description
1.  **Authentication & Identity Module**: Handles secure login, sign-up, email verification, and role-based routing.
2.  **College & Placement Module**: Allows admins to manage departments, batches, students, and publish events.
3.  **Student & Career Module**:
    *   **Profile Management**: Comprehensive profile with academic records, skills, and project information.
    *   **Resume Builder**: In-built, predefined templates with AI-assisted content suggestions.
    *   **Aptitude Center**: Access to practice quizzes with dynamically generated questions based on skill gaps.
    *   **Job Discovery**: Single interface for viewing and applying to college-posted and recruiter-posted opportunities.
    *   **Certificate Management**: Uploading and managing certifications with category-based validation status and skill point calculation.
    *   **AI Job Analyzer**: Advanced custom-built tools including "AI Resume Insights" for job matching and "Ask CareerBridge AI" career assistant.
        *   **Matching Engine**: A proprietary algorithmic engine that tokenizes resume text and job requirements to calculate a coverage-based score locally, without external AI APIs.
        *   **Self-Screening**: Real-time feedback for students allowing them to identify skill gaps against recruiter-posted requirements before applying.
        *   **Recruiter Integration**: Deeply integrated into the recruiter portal, allowing for automated candidate screening based on objective data.
4.  **Certification & Validation Engine**: A core module that validates external certifications (from 16+ providers), calculates skill points, and assigns trust scores.
5.  **Assessment & Practice Module**:
    *   **AI Question Generator**: Creates custom aptitude and technical questions.
    *   **Test Environment**: Secure interface for taking tests with timer libraries.
    *   **Scoring Engine**: auto-grades submissions and updates skill profiles.
6.  **Communication System**: Manages email templates, bulk sending capabilities via Resend, and notification logs.
7.  **Recruiter & Job Insights Module**: Features for job posting, candidate search (filtering by skill/score), and application tracking.
8.  **AI-Powered Job Matching & Insights System**:
    *   **Core Engine**: A `ResumeMatchingService` performing real-time PDF text extraction and custom keyword tokenization (strictly internal).
    *   **Intelligent Scoring**: Weighted algorithmic matching prioritizing recruiter requirements with fallback to job description context.
    *   **Actionable Insights**: High-visibility UI feedback via a Match Chip and Skills Breakdown dialog (Matched vs. Missing Keywords).
9.  **Networking & Communication Module**:
    *   **Student Feed**: Dynamic scrollable feed where students can share achievements and project updates.
    *   **Networking**: LinkedIn-like connections and real-time messaging.

## 1.7 Future scope of the project
*   **Mobile Application**: Development of native iOS and Android apps for better mobile accessibility and push notifications.
*   **Offline Mode improvement**: Implementing local database caching to allow students to take assessments or view content without internet.
*   **Advanced AI Integration**: Implementing AI-driven mock interviews and predictive analytics for placement success.
*   **Blockchain Verification**: Moving the certification trust system to a blockchain ledger for immutable proof of skills.
*   **LMS Integration**: Seamless integration with existing Learning Management Systems (Canvas, Moodle) for automatic record synchronization.
