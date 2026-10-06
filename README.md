<h1 align="center">
  <br>
  🚀 CareerBridge -AI Powered Placement and Netwroking system.
  <br>
</h1>

<h3 align="center">Comprehensive Student–College Management & Placement Platform</h3>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9.2+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Deployed%20on-Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" />
</p>

<p align="center">
  <b>CareerBridge</b> bridges the gap between academia and industry — a unified AI-enhanced ecosystem where students build career identities, colleges manage placements, and recruiters discover verified talent.
</p>

---

## 📋 Table of Contents

- [About the Project](#-about-the-project)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Modules Overview](#-modules-overview)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Documentation](#-documentation)
- [Future Scope](#-future-scope)
- [Contributing](#-contributing)

---

## 🌟 About the Project

CareerBridge is a **full-stack EdTech / HRTech web application** that replaces fragmented, manual placement processes with a streamlined, data-driven platform. It serves three distinct user types from a single unified interface:

| Role | What They Can Do |
|---|---|
| 🎓 **Students** | Build professional profiles, validate skills, discover careers, take AI-powered assessments |
| 🏛️ **College Admins** | Manage placement drives, verify certifications, track analytics, broadcast announcements |
| 💼 **Recruiters** | Post jobs, screen candidates via AI Resume Insights, track applications |

> **Project Category**: Web Application · Educational Technology (EdTech) · HR Technology (HRTech)

---

## ✨ Key Features

### 🤖 AI-Powered Matching Engine
- Custom-built `ResumeMatchingService` — performs real-time PDF text extraction and intelligent keyword tokenization (**no external AI APIs required** for core matching).
- Weighted algorithmic scoring prioritising recruiter requirements, with a job-description fallback.
- On-screen **Match Chip** and **Skills Breakdown dialog** (Matched vs. Missing keywords).

### 🧠 CareerBridge AI Career Assistant
- Conversational chatbot for platform navigation and real-time data retrieval.
- Powered by **OpenRouter LLM** integration with a local heuristic fallback layer.
- Role-aware responses for Students, Admins, and Recruiters.

### 📄 Resume Builder
- Template-based resume generator that pulls **validated data** directly from the user's profile.
- AI-assisted content suggestions for summary and bullet-point generation.
- PDF export support via Syncfusion toolkit.

### 🏆 Certification & Validation Engine
- Supports **16+ certificate providers** with automated status tracking.
- Trust Score Calculator assigns weighted skill points per verified certification.
- College Admin validation workflow (Approve / Reject) with email notification.

### 🎯 Aptitude & Assessment Center
- AI Question Generator creates custom aptitude and technical questions.
- Secure test environment with timer support and auto-scoring.
- Skill profile automatically updated post-assessment.

### 📊 Institutional Analytics
- Real-time placement statistics, department-wise skill gap reports.
- Drive management and bulk email broadcasting via **Resend API**.

### 🌐 Networking & Feed
- LinkedIn-like connection system between students and recruiters.
- Real-time messaging (Supabase Realtime).
- Student achievement and project share feed.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Web / Desktop / Mobile), Dart |
| **State Management** | Riverpod (Notifier / Provider) |
| **Design System** | Material Design 3 · Google Fonts (Outfit) |
| **Backend Platform** | Supabase (BaaS) |
| **Database** | PostgreSQL (with JSONB & RLS) |
| **Serverless Logic** | Supabase Edge Functions (Deno / TypeScript) |
| **Authentication** | Supabase Auth (JWT-based) |
| **Storage** | Supabase Storage (resumes, photos, media) |
| **Email Service** | Resend API |
| **AI / LLM** | OpenRouter API |
| **PDF Processing** | Syncfusion Flutter PDF |
| **Hosting** | Vercel (Frontend) · Supabase Cloud (Backend) |
| **Version Control** | Git & GitHub |

---

## 🏗️ Architecture

CareerBridge follows a modern **3-tier, Modular Feature-Based Architecture**:

```
┌─────────────────────────────────────────────────────┐
│                PRESENTATION LAYER                   │
│   Flutter Web/App  →  Riverpod State  →  Routing    │
└───────────────────────┬─────────────────────────────┘
                        │ HTTPS / WSS
┌───────────────────────▼─────────────────────────────┐
│            BACKEND & PLATFORM LOGIC                 │
│  Supabase Auth  │  PostgREST API  │  Realtime Engine │
│  PostgreSQL (RLS Policies)        │  Supabase Storage│
│  AI Matching Engine (Local)                         │
└───────────────────────┬─────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────┐
│           EXTERNAL SERVICES & LOGIC                 │
│  Supabase Edge Functions  →  Resend Email API       │
│  OpenRouter LLM API       →  Syncfusion PDF Parser  │
└─────────────────────────────────────────────────────┘
```

**Internal layers:**
- **Presentation Layer** — Flutter widgets by feature (Auth, Student, Recruiter, College…)
- **Domain Layer** — Services & logic (`ResumeMatchingService`, `IdentityHelper`)
- **Data Layer** — Repositories communicating with Supabase via PostgREST & Auth APIs
- **External Integration** — Edge Functions as bridges to third-party services

---

## 📦 Modules Overview

| Module | Core Functionality | Key Components |
|---|---|---|
| **Authentication & Identity** | Secure, role-based entry & session management | Supabase Auth, JWT, Role Routing |
| **Student & Career** | Career identity and skill development | Resume Builder, Project Cards, Practice Arena |
| **Recruiter & Job Insights** | Talent acquisition and AI screening | Job Management, AI Resume Insights |
| **College & Placement** | Institutional oversight and drive management | Placement Tracker, Certificate Verification |
| **Skill & Certification** | Validation and trust scoring | Trust Score Calculator, Dept. Validation |
| **AI Career Assistant** | Natural language help and navigation | CareerBridge AI (OpenRouter + Local Heuristics) |
| **Networking & Communication** | Professional community and messaging | Connections, Realtime Feed & Chat |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.9.2 — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (bundled with Flutter)
- **Supabase** project (free tier works for development)
- **Node.js** (for backend/Edge Functions development)
- **Git**

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/CareerBridge.git
cd CareerBridge

# 2. Navigate to the frontend
cd frontend

# 3. Install Flutter dependencies
flutter pub get

# 4. Configure environment
# Create a .env file (or update lib/core/config/supabase_config.dart)
# with your Supabase URL and anon key

# 5. Run the application
flutter run -d chrome          # Web
flutter run -d windows         # Desktop (Windows)
```

### Environment Variables

Create `frontend/lib/core/config/supabase_config.dart` (or use your preferred env approach):

```dart
const String supabaseUrl    = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
const String openRouterApiKey = 'YOUR_OPENROUTER_KEY'; // for CareerBridge AI
```

### Backend (Supabase Edge Functions)

```bash
cd backend
# Deploy edge functions via Supabase CLI
supabase functions deploy
```

> See [`docs/`](./docs/) for detailed setup instructions, database schema, and deployment guides.

---

## 📁 Project Structure

```
CareerBridge/
├── frontend/                  # Flutter application
│   ├── lib/
│   │   ├── core/              # App-wide config, theme, routing
│   │   ├── features/          # Feature-first modules
│   │   │   ├── auth/          # Authentication & identity
│   │   │   ├── student/       # Student portal
│   │   │   ├── recruiter/     # Recruiter portal
│   │   │   ├── college/       # College admin portal
│   │   │   ├── resume/        # Resume builder
│   │   │   ├── aptitude/      # Assessment center
│   │   │   ├── certifications/# Certification engine
│   │   │   └── ai_assistant/  # CareerBridge AI chatbot
│   │   └── main.dart
│   └── test/
├── backend/                   # Supabase Edge Functions (TypeScript)
├── docs/                      # Full project documentation
│   ├── CHAPTER_1_SYNOPSIS.md
│   ├── CHAPTER_2_SRS.md
│   ├── CHAPTER_3_SYSTEM_DESIGN.md
│   ├── CHAPTER_4_DATABASE_DESIGN.md
│   ├── CHAPTER_5_DETAILED_DESIGN.md
│   ├── CHAPTER_6_CODING.md
│   ├── CHAPTER_7_TESTING.md
│   ├── CHAPTER_8_SCREENSHOTS.md
│   ├── CHAPTER_9_CONCLUSION.md
│   ├── CHAPTER_10_BIBLIOGRAPHY.md
│   └── INDEX.md
└── README.md
```

---

## 📚 Documentation

All project documentation is available in the [`docs/`](./docs/) folder:

| Chapter | Topic |
|---|---|
| [Chapter 1 – Synopsis](./docs/CHAPTER_1_SYNOPSIS.md) | Project title, objectives, category & structure |
| [Chapter 2 – SRS](./docs/CHAPTER_2_SRS.md) | Functional & non-functional requirements |
| [Chapter 3 – System Design](./docs/CHAPTER_3_SYSTEM_DESIGN.md) | Architecture, use cases & module design |
| [Chapter 4 – Database Design](./docs/CHAPTER_4_DATABASE_DESIGN.md) | Schema, relationships & RLS policies |
| [Chapter 5 – Detailed Design](./docs/CHAPTER_5_DETAILED_DESIGN.md) | DFDs, sequence diagrams & data flow |
| [Chapter 6 – Coding](./docs/CHAPTER_6_CODING.md) | Implementation details & code references |
| [Chapter 7 – Testing](./docs/CHAPTER_7_TESTING.md) | Test strategy, cases & results |
| [Chapter 8 – Screenshots](./docs/CHAPTER_8_SCREENSHOTS.md) | UI walkthroughs & screen captures |
| [Chapter 9 – Conclusion](./docs/CHAPTER_9_CONCLUSION.md) | Achievements & future enhancements |
| [Chapter 10 – Bibliography](./docs/CHAPTER_10_BIBLIOGRAPHY.md) | References & external resources |

---

## 🔮 Future Scope

- 🤖 **Advanced LLM Integration** — AI-driven mock interviews with sentiment analysis & resume tailoring
- 📹 **Video Interview & Proctoring** — Built-in peer-to-peer video conferencing with AI assistance
- ⛓️ **Blockchain Credential Verification** — Immutable, decentralised proof of academic credentials
- 📱 **Native Mobile Apps** — Fully optimised Android & iOS apps with push notifications
- 📈 **Corporate Training Module** — Post-hiring onboarding and continuous upskilling
- 🌍 **Multi-Language Support** — Regional and international language localisation

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Open a **Pull Request**

Please ensure your code follows the existing Dart/Flutter conventions and includes relevant tests.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](./LICENSE) file for details.

---

<p align="center">
  Made with ❤️ by the CareerBridge Team &nbsp;·&nbsp;
  <a href="./docs/INDEX.md">📖 Full Docs</a>
</p>
