export type UserRole = 'admin' | 'tpo' | 'faculty_coordinator' | 'student';
export type ApprovalStatus = 'pending' | 'approved' | 'rejected';
export type ConsentStatus = 'not_set' | 'opted_in' | 'opted_out';
export type DriveStatus = 'draft' | 'published' | 'ongoing' | 'completed' | 'cancelled';
export type ApplicationStatus = 'applied' | 'shortlisted' | 'rejected' | 'offered' | 'accepted' | 'declined';

export interface Profile {
  id: string;
  email: string;
  role: UserRole;
  full_name: string;
  department?: string;
  usn?: string;
  batch?: string;
  cgpa?: number;
  active_backlogs?: number;
  approval_status?: ApprovalStatus;
  consent_status?: ConsentStatus;
  avatar_url?: string;
  created_at: string;
}

export interface Drive {
  id: string;
  company_name: string;
  role_title: string;
  ctc_or_stipend: string;
  cgpa_cutoff: number;
  max_backlogs: number;
  allowed_branches: string[];
  status: DriveStatus;
  application_deadline: string;
  created_at: string;
}

export interface Application {
  id: string;
  drive_id: string;
  student_id: string;
  status: ApplicationStatus;
  applied_at: string;
  drives?: Drive;
  profiles?: Profile;
}
