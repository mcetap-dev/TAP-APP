import React, { useState } from 'react';
import { StatusThread } from '../components/StatusThread';
import { ThemeToggle } from '../components/ThemeToggle';
import { 
  Building2, Users, FileText, Download, Plus, Search, LogOut
} from 'lucide-react';
import * as XLSX from 'xlsx';

export const DashboardPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'drives' | 'applications' | 'reports' | 'students'>('drives');
  const [searchQuery, setSearchQuery] = useState('');

  // Sample Placement Drives Data
  const drives = [
    { company: 'Google', role: 'Software Engineer', ctc: '32 LPA', cgpa: 8.5, deadline: '2026-08-15', status: 'Ongoing', match: '95%' },
    { company: 'Microsoft', role: 'Support Engineer', ctc: '24 LPA', cgpa: 8.0, deadline: '2026-08-20', status: 'Published', match: '88%' },
    { company: 'Amazon', role: 'SDE-1', ctc: '28 LPA', cgpa: 8.2, deadline: '2026-08-25', status: 'Ongoing', match: '92%' },
  ];

  // Sample Applicants Data
  const applicants = [
    { usn: '4MC23IS001', name: 'John Doe', dept: 'ISE', status: 'Applied', cgpa: 8.9 },
    { usn: '4MC23IS002', name: 'Jane Smith', dept: 'CSE', status: 'Shortlisted', cgpa: 9.2 },
    { usn: '4MC23IS003', name: 'Alice Johnson', dept: 'ECE', status: 'Shortlisted', cgpa: 8.4 },
  ];

  const exportExcelReport = () => {
    const ws = XLSX.utils.json_to_sheet(drives);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Placement Stats");
    XLSX.writeFile(wb, "Placement_Report.xlsx");
  };

  return (
    <div className="min-h-screen bg-[var(--bg)] text-[var(--ink)] flex flex-col md:flex-row font-sans transition-colors duration-200">
      {/* Side Rail / Mobile Header Navigation */}
      <aside className="w-full md:w-60 border-b md:border-b-0 md:border-r border-[var(--border)] bg-[var(--surface)] p-4 flex flex-col justify-between">
        <div>
          <div className="flex items-center justify-between md:justify-start gap-2 font-display font-medium text-lg text-[var(--ink)] px-2 py-3 mb-4 md:mb-6 border-b border-[var(--border)]">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-[var(--brass)] inline-block" />
              <span>Placement Connect</span>
            </div>
            <div className="md:hidden">
              <ThemeToggle />
            </div>
          </div>

          <nav className="grid grid-cols-2 sm:grid-cols-4 md:flex md:flex-col gap-1">
            <button
              onClick={() => setActiveTab('drives')}
              className={`flex items-center gap-2 px-3 py-2.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'drives'
                  ? 'bg-[var(--brass-soft)] text-[var(--brass)]'
                  : 'text-[var(--ink-muted)] hover:bg-[var(--surface-alt)] hover:text-[var(--ink)]'
              }`}
            >
              <Building2 className="w-4 h-4 shrink-0" /> <span className="truncate">Placement Drives</span>
            </button>

            <button
              onClick={() => setActiveTab('applications')}
              className={`flex items-center gap-2 px-3 py-2.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'applications'
                  ? 'bg-[var(--brass-soft)] text-[var(--brass)]'
                  : 'text-[var(--ink-muted)] hover:bg-[var(--surface-alt)] hover:text-[var(--ink)]'
              }`}
            >
              <FileText className="w-4 h-4 shrink-0" /> <span className="truncate">Application Threads</span>
            </button>

            <button
              onClick={() => setActiveTab('students')}
              className={`flex items-center gap-2 px-3 py-2.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'students'
                  ? 'bg-[var(--brass-soft)] text-[var(--brass)]'
                  : 'text-[var(--ink-muted)] hover:bg-[var(--surface-alt)] hover:text-[var(--ink)]'
              }`}
            >
              <Users className="w-4 h-4 shrink-0" /> <span className="truncate">Student Approval Gate</span>
            </button>

            <button
              onClick={() => setActiveTab('reports')}
              className={`flex items-center gap-2 px-3 py-2.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'reports'
                  ? 'bg-[var(--brass-soft)] text-[var(--brass)]'
                  : 'text-[var(--ink-muted)] hover:bg-[var(--surface-alt)] hover:text-[var(--ink)]'
              }`}
            >
              <Download className="w-4 h-4 shrink-0" /> <span className="truncate">NAAC/NBA Reports</span>
            </button>
          </nav>
        </div>

        <div className="hidden md:space-y-3 md:block mt-6">
          <ThemeToggle />
          <a href="/" className="flex items-center gap-2 text-xs font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] px-2">
            <LogOut className="w-3.5 h-3.5" /> Sign Out
          </a>
        </div>
      </aside>

      {/* Main Content Stage */}
      <main className="flex-1 p-4 sm:p-6 md:p-8 overflow-y-auto">
        {/* Top Header */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8 pb-4 border-b border-[var(--border)]">
          <div>
            <h1 className="font-display text-xl sm:text-2xl font-medium text-[var(--ink)] capitalize">{activeTab.replace('_', ' ')} Overview</h1>
            <p className="text-xs text-[var(--ink-muted)] mt-1">Institutional Placement & Recruitment Operating Portal</p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="relative flex-1 sm:flex-initial">
              <Search className="w-4 h-4 text-[var(--ink-muted)] absolute left-3 top-2.5" />
              <input
                type="text"
                placeholder="Search drives, USN, companies..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="bg-[var(--surface-alt)] border border-[var(--border)] rounded-lg pl-9 pr-4 py-2 text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--brass)] w-full sm:w-60"
              />
            </div>
            {activeTab === 'drives' && (
              <button className="btn-aureate-primary text-xs py-2 px-4">
                <Plus className="w-4 h-4" /> Create Drive
              </button>
            )}
          </div>
        </header>

        {/* Drives Grid */}
        {activeTab === 'drives' && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {drives.map((d) => (
              <div key={d.company} className="card-aureate p-6 relative">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-display text-xl font-medium text-[var(--ink)]">{d.company}</h3>
                  <span className="badge-aureate badge-brass">
                    {d.match} Match
                  </span>
                </div>
                <p className="text-xs font-semibold text-[var(--ink)] mb-2">{d.role}</p>
                <div className="text-xs font-mono text-[var(--ink-muted)] space-y-1 mb-5">
                  <p>CTC: {d.ctc}</p>
                  <p>Min CGPA: {d.cgpa}</p>
                  <p>Deadline: {d.deadline}</p>
                </div>
                <button className="w-full btn-aureate-primary justify-center text-xs py-2">
                  One-Tap Quick Apply
                </button>
              </div>
            ))}
          </div>
        )}

        {/* Applications / Signature Thread Tab */}
        {activeTab === 'applications' && (
          <div className="space-y-6 max-w-4xl">
            <div className="card-aureate p-6">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <span className="text-[10px] font-mono text-[var(--brass)]">Active Application Thread</span>
                  <h3 className="font-display text-2xl font-medium text-[var(--ink)]">Google — Software Engineer</h3>
                </div>
                <span className="badge-aureate badge-success">
                  Shortlisted · Phase 3
                </span>
              </div>
              <StatusThread stages={['Applied', 'Aptitude Test', 'Technical Round', 'HR Round', 'Offer Letter']} currentIndex={2} />
            </div>
          </div>
        )}

        {/* Student Verification Gate Tab */}
        {activeTab === 'students' && (
          <div className="card-aureate overflow-hidden">
            <div className="p-4 border-b border-[var(--border)]">
              <h3 className="font-display text-lg font-medium text-[var(--ink)]">Department Verification Queue</h3>
            </div>
            <table className="w-full text-left text-xs">
              <thead className="bg-[var(--surface-alt)] text-[var(--ink-muted)] border-b border-[var(--border)]">
                <tr>
                  <th className="p-3 font-mono text-[11px]">USN</th>
                  <th className="p-3">Name</th>
                  <th className="p-3">Dept</th>
                  <th className="p-3">CGPA</th>
                  <th className="p-3">Status</th>
                  <th className="p-3 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[var(--border)]">
                {applicants.map((a) => (
                  <tr key={a.usn} className="hover:bg-[var(--surface-alt)]">
                    <td className="p-3 font-mono text-[var(--ink-muted)]">{a.usn}</td>
                    <td className="p-3 font-semibold text-[var(--ink)]">{a.name}</td>
                    <td className="p-3 text-[var(--ink-muted)]">{a.dept}</td>
                    <td className="p-3 text-[var(--ink-muted)]">{a.cgpa}</td>
                    <td className="p-3">
                      <span className="badge-aureate badge-brass">
                        {a.status}
                      </span>
                    </td>
                    <td className="p-3 text-right">
                      <button className="btn-aureate-primary text-xs py-1 px-3">
                        Verify
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* NAAC/NBA Reports Tab */}
        {activeTab === 'reports' && (
          <div className="card-aureate text-center py-12 px-6 max-w-xl mx-auto">
            <FileText className="w-12 h-12 text-[var(--brass)] mx-auto mb-4" />
            <h3 className="font-display text-2xl font-medium text-[var(--ink)] mb-2">Institutional Report Generator</h3>
            <p className="text-xs text-[var(--ink-muted)] max-w-md mx-auto mb-6">
              Download and share department-wise NAAC and NBA compliant placement metrics.
            </p>
            <button
              onClick={exportExcelReport}
              className="btn-aureate-primary text-sm px-6 py-3 inline-flex items-center gap-2"
            >
              <Download className="w-4 h-4" /> Export Placement Stats (.xlsx)
            </button>
          </div>
        )}
      </main>
    </div>
  );
};
