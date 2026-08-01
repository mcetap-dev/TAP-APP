import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { motion, useScroll, useSpring, AnimatePresence } from 'framer-motion';
import { FloatingGlassNavbar } from '../components/FloatingGlassNavbar';
import { StatusThread } from '../components/StatusThread';
import { TiltCard } from '../components/TiltCard';
import { PartnerLogoCard } from '../components/PartnerLogoCard';
import { COMPANY_LOGOS } from '../assets/companyLogos';
import {
  ShieldCheck, UserCheck, Briefcase, GraduationCap, ArrowRight, FileSpreadsheet,
  ChevronDown, Building, HelpCircle, Mail, MapPin, Phone, Shield
} from 'lucide-react';

export const LandingPage: React.FC = () => {
  const [openFaq, setOpenFaq] = useState<number | null>(null);
  const [activeCategory, setActiveCategory] = useState<number>(1);

  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30, restDelta: 0.001 });

  const stats = [
    { label: 'Students Registered', val: '2,500+' },
    { label: 'Drives Conducted', val: '180+' },
    { label: 'Recruitment Partners', val: '60+' },
    { label: 'Highest Package', val: '32 LPA' },
    { label: 'Departments Covered', val: '8 Depts' },
    { label: 'Years of Excellence', val: '60+ Years' },
  ];

  const partnersData = {
    1: [
      { name: 'Mercedes-Benz', cat: 'Product & Tech Leader', logoUrl: COMPANY_LOGOS['Mercedes-Benz'] },
      { name: 'Samsung', cat: 'Product & Tech Leader', logoUrl: COMPANY_LOGOS['Samsung'] },
      { name: 'IBM', cat: 'Global Technology Leader', logoUrl: COMPANY_LOGOS['IBM'] },
      { name: 'GE HealthCare', cat: 'Product & MedTech', logoUrl: COMPANY_LOGOS['GE HealthCare'] },
      { name: 'Target', cat: 'Global Retail Tech', logoUrl: COMPANY_LOGOS['Target'] },
      { name: 'Schneider Electric', cat: 'Energy & Automation', logoUrl: COMPANY_LOGOS['Schneider Electric'] },
      { name: 'Bosch', cat: 'Automotive & Engg', logoUrl: COMPANY_LOGOS['Bosch'] },
      { name: 'Tata Elxsi', cat: 'Design & Tech', logoUrl: COMPANY_LOGOS['Tata Elxsi'] },
      { name: 'Fidelity Investments', cat: 'FinTech & Software', logoUrl: COMPANY_LOGOS['Fidelity Investments'] },
      { name: 'Keyence', cat: 'Sensors & Automation', logoUrl: COMPANY_LOGOS['Keyence'] }
    ],
    2: [
      { name: 'Ather Energy', cat: 'EV Engineering', logoUrl: COMPANY_LOGOS['Ather Energy'] },
      { name: 'Mu Sigma', cat: 'Data Analytics', logoUrl: COMPANY_LOGOS['Mu Sigma'] },
      { name: 'Accolite Digital', cat: 'Digital Products', logoUrl: COMPANY_LOGOS['Accolite Digital'] },
      { name: 'HashedIn', cat: 'Cloud Product Engg', logoUrl: COMPANY_LOGOS['HashedIn'] },
      { name: 'Quest Global', cat: 'Engineering Services', logoUrl: COMPANY_LOGOS['Quest Global'] },
      { name: 'Sasken', cat: 'Telecom & Embedded', logoUrl: COMPANY_LOGOS['Sasken'] },
      { name: 'Evertz', cat: 'Broadcast Hardware', logoUrl: COMPANY_LOGOS['Evertz'] },
      { name: 'Saankhya Labs', cat: 'Semiconductors', logoUrl: COMPANY_LOGOS['Saankhya Labs'] }
    ],
    3: [
      { name: 'Accenture', cat: 'IT Services & Consulting', logoUrl: COMPANY_LOGOS['Accenture'] },
      { name: 'Cognizant', cat: 'IT Services', logoUrl: COMPANY_LOGOS['Cognizant'] },
      { name: 'TCS', cat: 'Global IT Leader', logoUrl: COMPANY_LOGOS['TCS'] },
      { name: 'Siemens', cat: 'Industrial Automation', logoUrl: COMPANY_LOGOS['Siemens'] },
      { name: 'Tech Mahindra', cat: 'Digital Transformation', logoUrl: COMPANY_LOGOS['Tech Mahindra'] },
      { name: 'Happiest Minds', cat: 'NextGen Tech', logoUrl: COMPANY_LOGOS['Happiest Minds'] },
      { name: 'Sonata Software', cat: 'Enterprise Solutions', logoUrl: COMPANY_LOGOS['Sonata Software'] }
    ],
    4: [
      { name: 'Toyota Kirloskar', cat: 'Automotive OEM', logoUrl: COMPANY_LOGOS['Toyota Kirloskar'] },
      { name: 'Kennametal', cat: 'Industrial Materials', logoUrl: COMPANY_LOGOS['Kennametal'] },
      { name: 'Exide Industries', cat: 'Battery Storage', logoUrl: COMPANY_LOGOS['Exide Industries'] },
      { name: 'Indo-MIM', cat: 'Precision Metal', logoUrl: COMPANY_LOGOS['Indo-MIM'] },
      { name: 'ACE Designers', cat: 'Machine Tools', logoUrl: COMPANY_LOGOS['ACE Designers'] },
      { name: 'DiFACTO Robotics', cat: 'Robotics & Automation', logoUrl: COMPANY_LOGOS['DiFACTO Robotics'] }
    ],
    5: [
      { name: 'Kalpataru Projects', cat: 'EPC & Infrastructure', logoUrl: COMPANY_LOGOS['Kalpataru Projects'] },
      { name: 'Sobha Realty', cat: 'Infrastructure & Realty', logoUrl: COMPANY_LOGOS['Sobha Realty'] },
      { name: 'MEIL', cat: 'Infrastructure', logoUrl: COMPANY_LOGOS['MEIL'] },
      { name: 'Aarbee Structures', cat: 'Structural Engineering', logoUrl: COMPANY_LOGOS['Aarbee Structures'] },
      { name: 'Reliance Industries', cat: 'Energy & Retail', logoUrl: COMPANY_LOGOS['Reliance Industries'] }
    ]
  };

  const workflowSteps = [
    { title: 'Student Registration', desc: 'Students register with USN and profile details.' },
    { title: 'Eligibility Verification', desc: 'Faculty Coordinator approves student account.' },
    { title: 'Drive Publication', desc: 'TPO publishes placement drive with CGPA & backlog criteria.' },
    { title: 'Student Application', desc: 'Eligible & approved students apply in one tap.' },
    { title: 'Multi-Round Selection', desc: 'Aptitude, Technical, and HR rounds tracked live.' },
    { title: 'Offer Letter Generation', desc: 'TPO uploads verified offer letters for acceptance.' }
  ];

  const faqs = [
    { q: "How do students register on Placement Connect?", a: "Students register using their college credentials. Accounts start in a pending state until approved by their Department Faculty Coordinator." },
    { q: "What is the role of the Faculty Coordinator?", a: "Faculty Coordinators verify student profile data (CGPA, backlogs, department) and approve or reject accounts for placement drive eligibility." },
    { q: "How are eligibility cutoffs enforced?", a: "The platform's eligibility engine automatically checks CGPA, active backlogs, branch, and consent status before allowing a student to apply." },
    { q: "Can TPOs export NAAC/NBA compliance reports?", a: "Yes, TPOs and Administrators can generate and export complete institution-wide NAAC/NBA placement statistics in PDF and Excel (.xlsx) formats." },
    { q: "Is passkey & OTP login supported?", a: "Yes, Placement Connect supports email OTP verification and passkey authentication for administrative and TPO access." },
    { q: "How do students track their application status?", a: "Students monitor their application progress in real-time using the signature Status Thread tracker across Aptitude, Technical, HR, and Offer phases." }
  ];

  return (
    <div className="min-h-screen bg-[var(--bg)] text-[var(--ink)] flex flex-col font-sans transition-colors duration-200 selection:bg-[var(--brass)] selection:text-black">
      {/* Scroll Progress Bar */}
      <motion.div
        className="fixed top-0 left-0 right-0 h-1 bg-[var(--brass)] z-50 origin-left"
        style={{ scaleX }}
      />

      {/* Floating Glass Navbar Inspired by Fly.io */}
      <FloatingGlassNavbar />

      {/* 2. Hero Section */}
      <section id="hero" className="max-w-6xl mx-auto px-6 pt-20 pb-16 text-center flex flex-col items-center">
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="badge-aureate badge-brass mb-6"
        >
          <ShieldCheck className="w-3.5 h-3.5" /> Malnad College of Engineering · Training & Placement Dept
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="font-display text-4xl md:text-6xl font-medium tracking-tight max-w-4xl leading-tight mb-6 text-[var(--ink)]"
        >
          Your Campus. Your Career. <span className="text-[var(--brass)]">One Unified Placement Platform.</span>
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="text-base md:text-lg text-[var(--ink-muted)] max-w-2xl leading-relaxed mb-10"
        >
          Empowering MCE Hassan students, recruiters, faculty coordinators, and TPO leadership with automated eligibility, live thread status, and NAAC/NBA compliance exports.
        </motion.p>

        <div className="flex flex-col sm:flex-row gap-4 mb-24">
          <Link to="/login" className="btn-aureate-primary text-sm px-8 py-3 shadow-lg">
            Get Started <ArrowRight className="w-4 h-4" />
          </Link>
          <a href="#partners" className="btn-aureate-secondary text-sm px-8 py-3">
            Explore 60+ Recruitment Partners
          </a>
        </div>

        {/* Animated Scroll Down Indicator Button */}
        <motion.a
          href="#stats"
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: [0, 8, 0] }}
          transition={{
            y: { repeat: Infinity, duration: 2, ease: 'easeInOut' },
            opacity: { duration: 0.5 }
          }}
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-[var(--surface-alt)] border border-[var(--border)] text-xs font-semibold text-[var(--ink-muted)] hover:text-[var(--ink)] hover:border-[var(--brass)] transition-all shadow-md"
        >
          <span>Scroll to Explore</span>
          <ChevronDown className="w-4 h-4 text-[var(--brass)]" />
        </motion.a>
      </section>

      {/* 3. Trusted Statistics Section */}
      <section id="stats" className="border-y border-[var(--border)] bg-[var(--surface)] py-10">
        <div className="max-w-6xl mx-auto px-6 grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-6 text-center">
          {stats.map((s) => (
            <motion.div
              key={s.label}
              whileHover={{ scale: 1.05 }}
              className="p-2"
            >
              <span className="font-display text-3xl font-medium text-[var(--brass)] block">{s.val}</span>
              <span className="text-xs text-[var(--ink-muted)] font-medium mt-1 block">{s.label}</span>
            </motion.div>
          ))}
        </div>
      </section>

      {/* 4. Recruitment Partners Section */}
      <section id="partners" className="max-w-6xl mx-auto px-6 py-20">
        <div className="text-center mb-12">
          <div className="badge-aureate badge-brass mb-3">Our Recruitment Partners</div>
          <h2 className="font-display text-3xl md:text-4xl font-medium text-[var(--ink)] mb-4">
            Trusted by 60+ Global & Product Leaders
          </h2>
          <p className="text-xs text-[var(--ink-muted)] max-w-lg mx-auto">
            Top recruiters across product engineering, IT consulting, automotive, manufacturing, and core infrastructure sectors hiring from MCE Hassan. Hover over logos to reveal company category.
          </p>
        </div>

        {/* Partner Categories */}
        <div className="flex flex-wrap justify-center gap-2 mb-8">
          {[
            { id: 1, label: 'Product & Tech Leaders' },
            { id: 2, label: 'High Growth Product & Engg' },
            { id: 3, label: 'IT Services & Consulting' },
            { id: 4, label: 'Core Engg & Automotive' },
            { id: 5, label: 'Construction & Emerging' }
          ].map((cat) => (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id)}
              className={`px-4 py-2 rounded-lg text-xs font-semibold transition-all ${activeCategory === cat.id
                  ? 'bg-[var(--brass)] text-[#0A0A0B]'
                  : 'bg-[var(--surface-alt)] text-[var(--ink-muted)] hover:text-[var(--ink)]'
                }`}
            >
              {cat.label}
            </button>
          ))}
        </div>

        {/* Responsive Partner Logo Grid with Viewport Entrance & Tooltip */}
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {partnersData[activeCategory as keyof typeof partnersData].map((company) => (
            <PartnerLogoCard key={company.name} name={company.name} category={company.cat} domain={company.domain} logoUrl={company.logoUrl} />
          ))}
        </div>
      </section>

      {/* 5. 4-Portal Governance Modules */}
      <section id="modules" className="bg-[var(--surface)] border-y border-[var(--border)] py-20">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="font-display text-3xl md:text-4xl font-medium text-[var(--ink)] mb-4">
              4-Role Institutional Governance
            </h2>
            <p className="text-xs text-[var(--ink-muted)] max-w-md mx-auto">
              Role-isolated dashboards ensuring privacy, compliance, and automated recruitment lifecycle control.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <TiltCard className="card-aureate p-6">
              <GraduationCap className="w-8 h-8 text-[var(--info)] mb-4" />
              <h3 className="font-display text-lg font-medium text-[var(--ink)] mb-2">Student Portal</h3>
              <p className="text-xs text-[var(--ink-muted)] leading-relaxed">Profile setup, opt-in consent, eligible drive discovery, and live thread tracking.</p>
            </TiltCard>

            <TiltCard className="card-aureate p-6">
              <UserCheck className="w-8 h-8 text-[var(--success)] mb-4" />
              <h3 className="font-display text-lg font-medium text-[var(--ink)] mb-2">Faculty Portal</h3>
              <p className="text-xs text-[var(--ink-muted)] leading-relaxed">Department-scoped student approval gate, verification, and drive attendance metrics.</p>
            </TiltCard>

            <TiltCard className="card-aureate p-6">
              <Briefcase className="w-8 h-8 text-[var(--brass)] mb-4" />
              <h3 className="font-display text-lg font-medium text-[var(--ink)] mb-2">TPO Portal</h3>
              <p className="text-xs text-[var(--ink-muted)] leading-relaxed">End-to-end drive onboarding, drag-and-drop round scheduling, CSV shortlists, and offers.</p>
            </TiltCard>

            <TiltCard className="card-aureate p-6">
              <FileSpreadsheet className="w-8 h-8 text-[var(--alert)] mb-4" />
              <h3 className="font-display text-lg font-medium text-[var(--ink)] mb-2">Admin Portal</h3>
              <p className="text-xs text-[var(--ink-muted)] leading-relaxed">Appoint TPOs, configure academic cycles, and export institution-wide NAAC/NBA reports.</p>
            </TiltCard>
          </div>
        </div>
      </section>

      {/* 6. Placement Workflow */}
      <section id="workflow" className="max-w-6xl mx-auto px-6 py-20">
        <div className="text-center mb-16">
          <h2 className="font-display text-3xl md:text-4xl font-medium text-[var(--ink)] mb-4">
            End-to-End Placement Workflow
          </h2>
          <p className="text-xs text-[var(--ink-muted)] max-w-md mx-auto">
            From student registration to final offer letter acceptance in 6 seamless phases.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {workflowSteps.map((step, idx) => (
            <TiltCard key={step.title} className="card-aureate p-6">
              <span className="font-mono text-xs font-bold text-[var(--brass)] mb-2 block">PHASE 0{idx + 1}</span>
              <h3 className="font-display text-lg font-medium text-[var(--ink)] mb-2">{step.title}</h3>
              <p className="text-xs text-[var(--ink-muted)] leading-relaxed">{step.desc}</p>
            </TiltCard>
          ))}
        </div>
      </section>

      {/* 7. Enterprise Security */}
      <section className="bg-[var(--surface)] border-y border-[var(--border)] py-20">
        <div className="max-w-6xl mx-auto px-6 text-center">
          <Shield className="w-10 h-10 text-[var(--brass)] mx-auto mb-4" />
          <h2 className="font-display text-3xl font-medium text-[var(--ink)] mb-4">Enterprise Grade Security & Compliance</h2>
          <p className="text-xs text-[var(--ink-muted)] max-w-lg mx-auto mb-12">
            Protected by Supabase Row Level Security (RLS), email OTP verification, passkeys, and encrypted document storage.
          </p>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-left">
            <TiltCard className="card-aureate p-6">
              <h4 className="font-display text-base font-medium text-[var(--ink)] mb-1">Passkey & OTP Login</h4>
              <p className="text-xs text-[var(--ink-muted)]">Secure passwordless authentication for administrative personnel.</p>
            </TiltCard>
            <TiltCard className="card-aureate p-6">
              <h4 className="font-display text-base font-medium text-[var(--ink)] mb-1">RLS Data Isolation</h4>
              <p className="text-xs text-[var(--ink-muted)]">Department coordinators see only their assigned department records.</p>
            </TiltCard>
            <TiltCard className="card-aureate p-6">
              <h4 className="font-display text-base font-medium text-[var(--ink)] mb-1">Encrypted Vault</h4>
              <p className="text-xs text-[var(--ink-muted)]">Resumes, ID proofs, and offer letters stored with cryptographic security.</p>
            </TiltCard>
            <TiltCard className="card-aureate p-6">
              <h4 className="font-display text-base font-medium text-[var(--ink)] mb-1">Audit Trail Logs</h4>
              <p className="text-xs text-[var(--ink-muted)]">Complete historical logging of approval status and shortlisting changes.</p>
            </TiltCard>
          </div>
        </div>
      </section>

      {/* 8. FAQs */}
      <section id="faq" className="max-w-4xl mx-auto px-6 py-20">
        <div className="text-center mb-16">
          <HelpCircle className="w-10 h-10 text-[var(--brass)] mx-auto mb-4" />
          <h2 className="font-display text-3xl font-medium text-[var(--ink)] mb-3">Frequently Asked Questions</h2>
          <p className="text-xs text-[var(--ink-muted)]">Everything you need to know about Placement Connect at MCE Hassan.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {faqs.map((f, idx) => {
            const isOpen = openFaq === idx;
            return (
              <div
                key={f.q}
                className={`card-aureate h-40 flex flex-col justify-between p-5 transition-all duration-300 ${
                  isOpen ? 'border-[var(--brass)] shadow-lg shadow-[var(--brass-soft)]' : ''
                }`}
              >
                <div className="flex items-start justify-between gap-3">
                  <h3 className={`font-display text-sm font-medium transition-colors ${
                    isOpen ? 'text-[var(--brass)]' : 'text-[var(--ink)]'
                  }`}>
                    {f.q}
                  </h3>
                  <button
                    onClick={() => setOpenFaq(isOpen ? null : idx)}
                    className="p-1 rounded-full hover:bg-[var(--surface-alt)] transition-colors shrink-0"
                  >
                    <motion.div
                      animate={{ rotate: isOpen ? 180 : 0 }}
                      transition={{ duration: 0.2 }}
                    >
                      <ChevronDown className="w-4 h-4 text-[var(--ink-muted)]" />
                    </motion.div>
                  </button>
                </div>

                <div className="flex-1 mt-2 overflow-y-auto no-scrollbar">
                  {isOpen ? (
                    <motion.p
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      transition={{ duration: 0.2 }}
                      className="text-xs text-[var(--ink-muted)] leading-relaxed"
                    >
                      {f.a}
                    </motion.p>
                  ) : (
                    <p className="text-xs text-[var(--ink-muted)] line-clamp-2 opacity-60">
                      {f.a}
                    </p>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* 9. Contact TPO Office */}
      <section id="contact" className="bg-[var(--surface)] border-t border-[var(--border)] py-16">
        <div className="max-w-6xl mx-auto px-6 grid grid-cols-1 md:grid-cols-2 gap-10">
          <div>
            <span className="badge-aureate badge-brass mb-3">Get In Touch</span>
            <h2 className="font-display text-3xl font-medium text-[var(--ink)] mb-4">Training & Placement Office</h2>
            <p className="text-xs text-[var(--ink-muted)] leading-relaxed mb-6">
              Malnad College of Engineering, No. 225, Salagame Road, Hassan, Karnataka - 573202.
            </p>

            <div className="space-y-3 text-xs font-mono text-[var(--ink)]">
              <div className="flex items-center gap-3"><MapPin className="w-4 h-4 text-[var(--brass)]" /> MCE Campus, Hassan</div>
              <div className="flex items-center gap-3"><Mail className="w-4 h-4 text-[var(--brass)]" /> placement@mcehassan.ac.in</div>
              <div className="flex items-center gap-3"><Phone className="w-4 h-4 text-[var(--brass)]" /> +91 (08172) 245317</div>
            </div>
          </div>

          <TiltCard className="card-aureate p-6">
            <h3 className="font-display text-lg font-medium text-[var(--ink)] mb-4">Contact Placement Cell</h3>
            <form onSubmit={(e) => e.preventDefault()} className="space-y-4">
              <input type="text" placeholder="Your Name / Recruiter Name" className="w-full bg-[var(--surface-alt)] border border-[var(--border)] rounded-lg p-2.5 text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--brass)]" />
              <input type="email" placeholder="Official Email Address" className="w-full bg-[var(--surface-alt)] border border-[var(--border)] rounded-lg p-2.5 text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--brass)]" />
              <textarea placeholder="Inquiry details..." rows={3} className="w-full bg-[var(--surface-alt)] border border-[var(--border)] rounded-lg p-2.5 text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--brass)]" />
              <button type="submit" className="btn-aureate-primary text-xs py-2 px-6 w-full justify-center">
                Submit Inquiry
              </button>
            </form>
          </TiltCard>
        </div>
      </section>

      {/* 10. Final Call To Action */}
      <section className="max-w-6xl mx-auto px-6 py-20 text-center">
        <TiltCard className="card-aureate p-12 relative overflow-hidden bg-gradient-to-b from-[var(--surface)] to-[var(--surface-alt)] border-[var(--brass-soft)]">
          <h2 className="font-display text-3xl md:text-5xl font-medium text-[var(--ink)] mb-4">
            Ready to Launch Your Placement Drive?
          </h2>
          <p className="text-xs text-[var(--ink-muted)] max-w-md mx-auto mb-8">
            Access Malnad College of Engineering's unified campus recruitment ecosystem today.
          </p>

          <div className="flex flex-wrap justify-center gap-4">
            <Link to="/login" className="btn-aureate-primary text-sm px-8 py-3 shadow-lg">
              Get Started <ArrowRight className="w-4 h-4" />
            </Link>
            <a href="#contact" className="btn-aureate-secondary text-sm px-8 py-3">
              Recruit With Us
            </a>
          </div>
        </TiltCard>
      </section>

      {/* 11. Footer */}
      <footer className="border-t border-[var(--border)] bg-[var(--surface)] py-12 px-6">
        <div className="max-w-6xl mx-auto grid grid-cols-2 md:grid-cols-5 gap-8 text-xs mb-12">
          <div>
            <span className="font-display font-medium text-sm text-[var(--ink)] block mb-3">Placement Connect</span>
            <p className="text-[var(--ink-muted)] leading-relaxed">Official Placement Portal of MCE Hassan.</p>
          </div>
          <div>
            <span className="font-mono text-[11px] uppercase text-[var(--brass)] block mb-3">Portals</span>
            <ul className="space-y-2 text-[var(--ink-muted)]">
              <li><Link to="/login" className="hover:text-[var(--ink)]">Student Login</Link></li>
              <li><Link to="/login" className="hover:text-[var(--ink)]">Faculty Login</Link></li>
              <li><Link to="/login" className="hover:text-[var(--ink)]">TPO Login</Link></li>
              <li><Link to="/login" className="hover:text-[var(--ink)]">Admin Login</Link></li>
            </ul>
          </div>
          <div>
            <span className="font-mono text-[11px] uppercase text-[var(--brass)] block mb-3">Platform</span>
            <ul className="space-y-2 text-[var(--ink-muted)]">
              <li><a href="#features" className="hover:text-[var(--ink)] font-medium">Features</a></li>
              <li><a href="#modules" className="hover:text-[var(--ink)] font-medium">Governance</a></li>
              <li><a href="#workflow" className="hover:text-[var(--ink)] font-medium">Workflow</a></li>
            </ul>
          </div>
          <div>
            <span className="font-mono text-[11px] uppercase text-[var(--brass)] block mb-3">Compliance</span>
            <ul className="space-y-2 text-[var(--ink-muted)]">
              <li><span>NAAC Accredited</span></li>
              <li><span>NBA Approved</span></li>
              <li><span>RLS Protected</span></li>
            </ul>
          </div>
          <div>
            <span className="font-mono text-[11px] uppercase text-[var(--brass)] block mb-3">Institution</span>
            <p className="text-[var(--ink-muted)] leading-relaxed">Malnad College of Engineering, Hassan, Karnataka.</p>
          </div>
        </div>

        <div className="max-w-6xl mx-auto border-t border-[var(--border)] pt-6 flex flex-col sm:flex-row items-center justify-between text-[11px] text-[var(--ink-muted)]">
          <p>© 2026 Training & Placement Department, MCE Hassan. All rights reserved.</p>
          <p className="font-mono">Built with Aureate Technical Design System</p>
        </div>
      </footer>
    </div>
  );
};
