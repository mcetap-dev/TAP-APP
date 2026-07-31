import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { ThemeToggle } from './ThemeToggle';
import { Sparkles, ArrowRight, ChevronDown, Menu, X, Users, Briefcase, GraduationCap, Building2 } from 'lucide-react';

export const FloatingGlassNavbar: React.FC = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [activeTab, setActiveTab] = useState('Home');
  const [activeMegaMenu, setActiveMegaMenu] = useState<string | null>(null);
  const [mobileDrawerOpen, setMobileDrawerOpen] = useState(false);

  const navItems = [
    { label: 'Home', href: '#hero', sectionId: 'hero' },
    { label: 'Statistics', href: '#stats', sectionId: 'stats' },
    { label: 'Partners', href: '#partners', sectionId: 'partners' },
    { label: 'Portals', href: '#modules', sectionId: 'modules', hasMenu: 'portals' },
    { label: 'Workflow', href: '#workflow', sectionId: 'workflow' },
    { label: 'FAQ', href: '#faq', sectionId: 'faq' },
    { label: 'Contact', href: '#contact', sectionId: 'contact' },
  ];

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);

      // Section scrollspy tracking
      const scrollPosition = window.scrollY + 200;

      for (let i = navItems.length - 1; i >= 0; i--) {
        const item = navItems[i];
        const el = document.getElementById(item.sectionId);
        if (el) {
          const top = el.offsetTop;
          if (scrollPosition >= top) {
            setActiveTab(item.label);
            break;
          }
        }
      }
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll(); // Initial evaluation
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <div className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-3 sm:px-6 md:px-8 pt-3 sm:pt-5 pointer-events-none">
      {/* 1. Standalone Left Section: Logo & Branding */}
      <motion.div
        initial={{ y: -30, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="pointer-events-auto flex items-center gap-2 group cursor-pointer"
      >
        <Link to="/" className="flex items-center gap-2.5">
          <div className="w-3 h-3 rounded-full bg-[var(--brass)] inline-block group-hover:scale-125 transition-transform shadow-md shadow-[var(--brass-soft)]" />
          <div className="flex flex-col">
            <span className="font-display font-semibold text-sm text-[var(--ink)] tracking-tight leading-none group-hover:text-[var(--brass)] transition-colors">
              Placement Connect
            </span>
            <span className="text-[10px] font-mono text-[var(--ink-muted)]">MCE Hassan</span>
          </div>
        </Link>
      </motion.div>

      {/* 2. Standalone Center Section: Floating Glass Pill Nav */}
      <motion.nav
        initial={{ y: -30, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.05 }}
        className={`pointer-events-auto hidden lg:flex items-center rounded-full p-1.5 transition-all duration-300 relative ${
          isScrolled
            ? 'bg-[#111214]/85 backdrop-blur-xl border border-[var(--brass-soft)] shadow-2xl shadow-black/80'
            : 'bg-[#111214]/60 backdrop-blur-md border border-[var(--border)] shadow-lg'
        }`}
      >
        {navItems.map((item) => {
          const isActive = activeTab === item.label;
          return (
            <div
              key={item.label}
              className="relative"
              onMouseEnter={() => item.hasMenu && setActiveMegaMenu(item.hasMenu)}
              onMouseLeave={() => item.hasMenu && setActiveMegaMenu(null)}
            >
              <a
                href={item.href}
                onClick={() => setActiveTab(item.label)}
                className={`relative z-10 px-4 py-1.5 text-xs font-semibold rounded-full transition-colors flex items-center gap-1 ${
                  isActive ? 'text-[#0A0A0B]' : 'text-[var(--ink-muted)] hover:text-[var(--ink)]'
                }`}
              >
                {item.label}
                {item.hasMenu && <ChevronDown className="w-3 h-3" />}
              </a>

              {/* Sliding Active Pill Indicator */}
              {isActive && (
                <motion.div
                  layoutId="activePill"
                  transition={{ type: 'spring', stiffness: 350, damping: 30 }}
                  className="absolute inset-0 bg-[var(--brass)] rounded-full shadow-md z-0"
                />
              )}

              {/* Mega Menu Dropdown */}
              <AnimatePresence>
                {activeMegaMenu === 'portals' && item.hasMenu === 'portals' && (
                  <motion.div
                    initial={{ opacity: 0, y: 10, scale: 0.95 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: 5, scale: 0.95 }}
                    transition={{ duration: 0.2 }}
                    className="absolute top-full left-1/2 -translate-x-1/2 mt-3 w-64 card-aureate p-3 shadow-2xl z-30 bg-[#111214]/95 backdrop-blur-xl border border-[var(--brass-soft)]"
                  >
                    <div className="text-[10px] font-mono uppercase text-[var(--brass)] mb-2 px-2">Role Portals</div>
                    <div className="space-y-1">
                      <Link to="/login" className="flex items-center gap-2.5 p-2 rounded-lg text-xs font-medium text-[var(--ink)] hover:bg-[var(--surface-alt)] hover:text-[var(--brass)] transition-all">
                        <GraduationCap className="w-4 h-4 text-[var(--info)]" /> Student Portal
                      </Link>
                      <Link to="/login" className="flex items-center gap-2.5 p-2 rounded-lg text-xs font-medium text-[var(--ink)] hover:bg-[var(--surface-alt)] hover:text-[var(--brass)] transition-all">
                        <Users className="w-4 h-4 text-[var(--success)]" /> Faculty Coordinator
                      </Link>
                      <Link to="/login" className="flex items-center gap-2.5 p-2 rounded-lg text-xs font-medium text-[var(--ink)] hover:bg-[var(--surface-alt)] hover:text-[var(--brass)] transition-all">
                        <Briefcase className="w-4 h-4 text-[var(--brass)]" /> TPO Department
                      </Link>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          );
        })}
      </motion.nav>

      {/* 3. Standalone Right Section: Glass Action Cluster */}
      <motion.div
        initial={{ y: -30, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1 }}
        className="pointer-events-auto hidden lg:flex items-center gap-2.5"
      >
        <ThemeToggle />

        <Link to="/ai" className="text-xs font-semibold text-[var(--brass)] bg-[var(--brass-soft)] px-3.5 py-1.5 rounded-full flex items-center gap-1.5 hover:opacity-90 transition-all border border-[var(--brass-soft)] backdrop-blur-md">
          <Sparkles className="w-3.5 h-3.5" />
          <span>AI Hub</span>
        </Link>

        {/* Floating Glass Auth Pill Capsule */}
        <div className={`flex items-center gap-1 rounded-full p-1.5 transition-all duration-300 ${
          isScrolled
            ? 'bg-[#111214]/85 backdrop-blur-xl border border-[var(--brass-soft)] shadow-2xl'
            : 'bg-[#111214]/60 backdrop-blur-md border border-[var(--border)] shadow-lg'
        }`}>
          <Link to="/login" className="text-xs font-semibold text-[var(--ink-muted)] hover:text-[var(--ink)] px-4 py-1.5 transition-all">
            Sign In
          </Link>
          <motion.div whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }}>
            <Link to="/login" className="btn-aureate-primary text-xs py-1.5 px-5 !rounded-full shadow-md">
              Get Started <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </motion.div>
        </div>
      </motion.div>

      {/* Mobile Menu Trigger */}
      <div className="pointer-events-auto flex lg:hidden items-center gap-2">
        <ThemeToggle />
        <button
          onClick={() => setMobileDrawerOpen(!mobileDrawerOpen)}
          className="p-2 text-[var(--ink)] hover:text-[var(--brass)] bg-[#111214]/80 rounded-full border border-[var(--border)]"
        >
          {mobileDrawerOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </div>

      {/* Mobile Drawer */}
      <AnimatePresence>
        {mobileDrawerOpen && (
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            className="pointer-events-auto absolute top-full left-4 right-4 mt-2 card-aureate p-4 bg-[#111214]/95 backdrop-blur-xl border border-[var(--brass-soft)] shadow-2xl lg:hidden"
          >
            <nav className="flex flex-col gap-2">
              {navItems.map((item) => (
                <a
                  key={item.label}
                  href={item.href}
                  onClick={() => {
                    setActiveTab(item.label);
                    setMobileDrawerOpen(false);
                  }}
                  className="px-3 py-2 text-sm font-medium text-[var(--ink-muted)] hover:text-[var(--ink)] rounded-lg hover:bg-[var(--surface-alt)]"
                >
                  {item.label}
                </a>
              ))}
              <div className="pt-2 border-t border-[var(--border)] flex flex-col gap-2">
                <Link to="/login" className="btn-aureate-primary text-xs py-2.5 justify-center rounded-full">
                  Get Started <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            </nav>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
