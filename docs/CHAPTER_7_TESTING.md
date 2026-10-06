# Chapter 7: Testing

## 7.1 Introduction
Testing is a critical phase in the **CareerBridge** development lifecycle, ensuring that the platform operates reliably, securely, and in accordance with the user requirements. This chapter describes the testing strategy, including objectives, methodologies, and specific test cases used to validate the system's functionality and performance.

## 7.2 Testing Objectives
The primary objectives of the testing phase are:
- **Accuracy**: Ensuring the AI Matching Engine provides correct coverage scores and keyword insights.
- **Security**: Verifying that Row-Level Security (RLS) policies prevent unauthorized data access between roles.
- **Reliability**: Confirming that the platform handles real-time data synchronization via Supabase without data loss.
- **Usability**: Ensuring the user interface is intuitive and responsive across mobile, tablet, and desktop devices.
- **Performance**: Validating that PDF extraction and analysis occur within the target time frame (2-3 seconds).

## 7.3 Testing Methods
CareerBridge employed a combination of manual and automated testing methods:
- **Manual Testing**: Used for validating UI components, navigation flows, and user experience patterns. This involved interactive testing using the Flutter DevTools.
- **Automated Unit Testing**: Focused on business logic and service layers (e.g., scoring algorithms and data transformation functions).
- **Simulated Environment Testing**: Testing the system with diverse datasets (mock profiles, various resume formats) to ensure robust performance.
- **Beta Testing**: Internal testing by stakeholders acting as students, recruiters, and admins to identify real-world workflow issues.

## 7.4 Testing Steps

### 7.4.1 Unit Testing
Individual components and services were tested in isolation. For example, the `ResumeMatchingService` was verified with various requirement lists and resume strings to ensure the percentage calculation remained accurate to 2 decimal places.

### 7.4.2 Integration Testing
Focused on the interaction between modules and external services. This included:
- Verifying the flow from **Supabase Auth** status changes to UI redirection via the `authProvider`.
- Testing the connection between the **Student Profile** updates and the **Recruiter Search** results.

### 7.4.3 Validation Testing
Ensured that the system handles user input correctly:
- Validating email formats and password strength requirements during signup.
- Verifying that only text-searchable PDFs are accepted by the match engine.
- Checking that mandatory fields in job postings are enforced.

### 7.4.4 Output Testing
Validated the correctness of system-generated data:
- Checking the visual representation of "Match Score" chips.
- Ensuring the "Placement Analytics" charts accurately reflect the data in the `offers` table.
- Verifying the generated PDF resumes follow the selected templates.

### 7.4.5 User Acceptance Testing (UAT)
Final validation by end-users to ensure the system meets business needs.
- **Students**: Verified that job applications and practice tests follow a logical flow.
- **Recruiters**: Confirmed that screening candidates via AI insights significantly reduces manual effort.
- **Admins**: Validated the certificate approval workflow and institutional reporting.

## 7.5 Testing Cases

| Test Case ID | Feature | Description | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-01 | Auth | Login with valid Recruiter credentials. | Redirect to Recruiter Dashboard. | Redirected successfully. | Pass |
| TC-02 | AI Matcher| Upload resume with 5/10 matching keywords. | System should show a 50% match score. | Shown 50.0%. | Pass |
| TC-03 | Security | Student attempts to access Admin Drive settings. | Access should be denied by RLS/Routing. | Access Denied. | Pass |
| TC-04 | Job Post | Recruiter creates job without salary field. | System should show validation error. | Error "Salary Required".| Pass |
| TC-05 | Search | Search for "Flutter" in candidate database. | Should list all students with Flutter skill. | Listed 12 students. | Pass |
| TC-06 | Certificate| Student uploads pending certificate. | Status should show "Pending Verification". | Status: Pending. | Pass |
| TC-07 | Analytics | Mock interview completion. | Proficiency score should update instantly. | Score updated. | Pass |
| TC-08 | Learning | Enroll in "Advanced Dart" course. | Course added to "My Courses" list. | Course enrolled. | Pass |
| TC-09 | Mocks | Admin creates a "Technical Round" mock session. | Session appears in student's Prep Arena. | Session published. | Pass |
| TC-10 | Network | Student follows a Recruiter. | Recruiter's name appears in "Connections". | Followed successfully. | Pass |
| TC-11 | Feed | Post a project update to the campus feed. | Post visible to all department members. | Post visible. | Pass |
| TC-12 | Notify | Shortlist a student for an interview. | Automated email triggered to student. | Email received. | Pass |
| TC-13 | Resume | Export resume as "Modern Clean" PDF. | PDF content matches profile data perfectly. | PDF generated. | Pass |
| TC-14 | Identity | Change profile picture in settings. | New avatar reflects across all portals. | Avatar updated. | Pass |
| TC-15 | Drive | College admin closes an active drive. | Drive status updates to "Completed" globally. | Status updated. | Pass |
| TC-16 | CareerBridge AI | Ask "How to post a job?" or "Practice arena."| System should provide guide and offer navigation.| Guide shown & Navigated.| Pass |
| TC-17 | CareerBridge AI | Query for a specific student or course name. | AI should find entity and offer profile/details.| Entity found & Link offered.| Pass |
| TC-18 | Messaging | Send real-time message to a connected peer. | Message should appear instantly for the recipient.| Message received (WSS). | Pass |
