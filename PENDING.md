# Placement Connect — Project Progress & Pending Items Report

This document outlines the current state of **Placement Connect** (Flutter + Riverpod + Supabase), detailing what has been implemented and what remains pending according to the [Master Implementation Prompt](file:///e:/placement_connect/placement-connect-master-prompt.md).

---

## 📊 Summary of Project Status

| Module / Component | Status | Key Highlights |
| :--- | :---: | :--- |
| **Database & Supabase RLS** | 🟢 90% Complete | All core tables, enums, triggers, and RLS policies (00001-00006) defined. |
| **Auth & Routing** | 🟡 70% Complete | Login, Signup, OTP, Role-based routing configured. Pending Approval gate UI needed. |
| **Admin Module** | 🔴 35% Complete | TPO appointment backend ready. Academic cycle CRUD & NAAC/NBA reports pending. |
| **TPO Module** | 🔴 30% Complete | Core repository layer ready. Drive CRUD, Faculty appointment, CSV shortlist & offer upload UI pending. |
| **Faculty Coordinator Module**| 🔴 25% Complete | Basic repository & dashboard ready. Student approval queue & attendance views pending. |
| **Student Module** | 🔴 35% Complete | Application & Drive repositories ready. Profile setup, consent form, eligible drives UI, apply form pending. |
| **Offline Sync & Infrastructure** | 🟢 85% Complete | Drift local database queue, connectivity monitoring, and realtime listeners implemented with unit tests. |

---

## 📑 Detailed Pending Checklist

### 1. Auth & Onboarding Bootstrap
- [x] Supabase Auth integration (email/password & OTP verification).
- [x] Initial role assignment (`student` default on self-registration).
- [x] Post-login role-based routing (Admin, TPO, Faculty, Student dashboards).
- [ ] **[PENDING] Blocked/Waiting Screen for Students**: Post-login gate checking `approval_status == 'pending'`, showing a browse-only / "Awaiting Faculty Approval" screen with restricted actions.
- [ ] **[PENDING] Password Reset Flow**: Forgot password / update password mechanism.

---

### 2. Admin Module
- [x] Appoint TPO account functionality in `AdminAccountRepository`.
- [x] Basic Admin Dashboard layout.
- [ ] **[PENDING] Appoint TPO UI**: Form to create/assign TPO accounts.
- [ ] **[PENDING] Academic Cycle Management**:
  - UI for creating/editing academic cycles (year, eligible batch, branches).
  - Toggle active cycle status.
- [ ] **[PENDING] NAAC / NBA Institution-wide Reporting**:
  - UI to view rollup stats across all departments (`department_placement_stats` & `drive_stats`).
  - Export reports to **PDF** and **XLSX** formats.

---

### 3. TPO Module (Placement Cell)
- [x] `TpoRepository` methods for drive management and stats fetching.
- [x] Basic TPO Dashboard structure.
- [ ] **[PENDING] Faculty Coordinator Appointment UI**:
  - Assign 1 Faculty Coordinator per department.
  - Enforce duplicate check (prompt for reassignment if department already has a coordinator).
- [ ] **[PENDING] Company Management**: CRUD screens for managing onboarded companies (industry, contact HR details).
- [ ] **[PENDING] Drive Management & Eligibility**:
  - Create/Edit Drive form (role, CTC, JD, eligibility criteria, branches, CGPA cutoff, backlog limit, round counts, deadline).
  - Manual Eligibility Exceptions UI (manually add or remove student eligibility with required justification).
- [ ] **[PENDING] Drive Round Scheduling**: Schedule dates, times, venues/links for each round (Test/GD/Tech/HR).
- [ ] **[PENDING] Applicant List & Shortlist Upload**:
  - View list of applicants per drive.
  - Bulk CSV shortlist upload updating student application and round status.
- [ ] **[PENDING] Offer Upload & Management**: Form to upload final student offer details (CTC offered, offer letter, joining date).

---

### 4. Faculty Coordinator Module
- [x] `FacultyRepository` for department-scoped operations.
- [x] Basic Faculty Dashboard layout.
- [ ] **[PENDING] Student Pending Approval Queue**:
  - List students in the coordinator's department awaiting approval.
  - Approve or Reject student registration with mandatory rejection reason.
- [ ] **[PENDING] Department Placement History View**: Department-scoped statistics display based on `department_placement_stats`.
- [ ] **[PENDING] Department Drive Attendance View**: Track student attendance per drive round for the department.
- [ ] **[PENDING] Panel Interview Feedback Form**: Submit 1-5 rating, remarks, and recommendation for candidates during interview rounds.

---

### 5. Student Module
- [x] `StudentDriveRepository` & `StudentApplicationRepository`.
- [x] Student Entities (`Drive`, `Application`) and basic dashboard structure.
- [ ] **[PENDING] Multi-Step Profile Completion UI**:
  - Academic records (USN, 10th %, 12th/Diploma %, semester-wise CGPA, backlogs).
  - Resume & document upload links (ID proof, photos).
  - Skills, certifications, projects, achievements entry.
- [ ] **[PENDING] Student Placement Consent Form**:
  - Consent status selector (`opted_in` / `opted_out`).
  - Opt-out reason input (automatically excludes student from eligible drive lists).
- [ ] **[PENDING] Eligible Drives Screen**:
  - List drives where student is approved, opted-in, and meets criteria (or has explicit exception).
- [ ] **[PENDING] Drive Application Form**:
  - View drive details & submit application ("Why this role?", resume version choice).
  - Blocked completely if `approval_status != 'approved'`.
- [ ] **[PENDING] My Applications & Status Tracker**: Real-time status tracker (Applied → Shortlisted → Interview → Selected/Rejected).
- [ ] **[PENDING] Offer Management UI**: Review offer details, Accept or Decline offer.
- [ ] **[PENDING] Student Queries / Grievance Module**: Submit queries/tickets to placement cell and track resolution status.

---

### 6. Technical & Cross-Cutting Dependencies
- [x] Local SQLite/Drift offline queue database.
- [x] Network connectivity listener & sync provider.
- [x] RLS policies & recursive query bug fix (`00006_fix_profiles_rls_recursion.sql`).
- [ ] **[PENDING] PDF / XLSX Export Package**: Add dependencies (`pdf`, `excel`, `printing`) to `pubspec.yaml` for Admin reports.
- [ ] **[PENDING] CSV Parser Integration**: Add `csv` package for TPO shortlist uploads.
- [ ] **[PENDING] FCM Push Notification Triggers**: Handle notifications on application status changes and new drive postings.

---

## 🛠️ Next Recommended Development Steps

1. **Step 1: Complete Student Profile & Consent UI** (`lib/features/student/presentation/screens/`)
   - Build student profile setup wizard and consent form.
2. **Step 2: Implement Student Approval Queue for Faculty** (`lib/features/faculty/presentation/screens/`)
   - Allow Faculty Coordinators to approve/reject student registrations.
3. **Step 3: Drive Creation & Management Wizard for TPO** (`lib/features/tpo/presentation/screens/`)
   - Enable TPO to create drives, set criteria, schedule rounds, and upload shortlists.
4. **Step 4: Admin Reporting & Exporting** (`lib/features/admin/presentation/screens/`)
   - Implement NAAC/NBA institution-wide analytics and PDF/XLSX export.
