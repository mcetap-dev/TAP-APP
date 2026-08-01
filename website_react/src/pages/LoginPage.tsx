import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import type { UserRole } from '../types/database';
import { ThemeToggle } from '../components/ThemeToggle';
import { ShieldCheck, Mail, Lock, ArrowRight } from 'lucide-react';

export const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const [selectedRole, setSelectedRole] = useState<'student' | 'faculty'>('student');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const domain = selectedRole === 'student' ? '@ms.mcehassan.ac.in' : '@mcehassan.ac.in';

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const input = username.trim();
    const fullEmail = input.endsWith(domain) ? input : `${input}${domain}`;

    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email: fullEmail,
        password,
      });

      if (authError) throw authError;

      if (data.user) {
        navigate('/dashboard');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to authenticate');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[var(--bg)] text-[var(--ink)] flex flex-col justify-center items-center p-4 sm:p-6 font-sans transition-colors duration-200">
      <div className="absolute top-4 right-4 sm:top-6 sm:right-6">
        <ThemeToggle />
      </div>

      <div className="w-full max-w-sm card-aureate p-5 sm:p-8 shadow-xl relative">
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-[var(--brass-soft)] text-[var(--brass)] mb-3">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <h2 className="font-display text-xl sm:text-2xl font-medium text-[var(--ink)]">Placement Connect</h2>
          <p className="text-xs text-[var(--ink-muted)] mt-1">Select role & authenticate</p>
        </div>

        {/* Role Tabs */}
        <div className="flex bg-[var(--surface-alt)] rounded-lg p-1 mb-6 border border-[var(--border)]">
          <button
            type="button"
            onClick={() => setSelectedRole('student')}
            className={`flex-1 py-2 text-xs font-semibold rounded-md transition-all ${
              selectedRole === 'student'
                ? 'bg-[var(--brass)] text-black shadow-sm'
                : 'text-[var(--ink-muted)] hover:text-[var(--ink)]'
            }`}
          >
            Student
          </button>
          <button
            type="button"
            onClick={() => setSelectedRole('faculty')}
            className={`flex-1 py-2 text-xs font-semibold rounded-md transition-all ${
              selectedRole === 'faculty'
                ? 'bg-[var(--brass)] text-black shadow-sm'
                : 'text-[var(--ink-muted)] hover:text-[var(--ink)]'
            }`}
          >
            Faculty
          </button>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-[var(--alert-soft)] text-[var(--alert)] rounded-lg text-xs font-medium border border-[var(--alert)]">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-[11px] font-mono uppercase tracking-wider text-[var(--ink-muted)] mb-1">Email Username</label>
            <div className="relative flex items-center">
              <Mail className="w-4 h-4 text-[var(--ink-muted)] absolute left-3" />
              <input
                type="text"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder={selectedRole === 'student' ? '4mc21cs001' : 'faculty_name'}
                className="w-full bg-[var(--surface-alt)] border border-[var(--border)] rounded-lg pl-9 pr-32 py-2 text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--brass)]"
              />
              <span className="absolute right-3 text-xs font-mono font-semibold text-[var(--brass)] pointer-events-none">
                {domain}
              </span>
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-mono uppercase tracking-wider text-[var(--ink-muted)] mb-1">Password</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-[var(--ink-muted)] absolute left-3 top-3" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full bg-[var(--surface-alt)] border border-[var(--border)] rounded-lg pl-9 pr-3 py-2 text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--brass)]"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full btn-aureate-primary justify-center py-2.5 mt-2"
          >
            {loading ? 'Authenticating...' : `Sign in as ${selectedRole === 'student' ? 'Student' : 'Faculty / Staff'}`}
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        <div className="mt-6 text-center">
          <Link to="/" className="text-xs text-[var(--brass)] font-semibold hover:underline">
            ← Back to Main Web Page
          </Link>
        </div>
      </div>
    </div>
  );
};
