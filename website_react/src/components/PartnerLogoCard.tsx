import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface LogoItemProps {
  name: string;
  category: string;
  logoUrl?: string;
  domain?: string;
}

export const PartnerLogoCard: React.FC<LogoItemProps> = ({ name, category, logoUrl }) => {
  const [hovered, setHovered] = useState(false);
  const [imgError, setImgError] = useState(false);

  return (
    <motion.div
      onHoverStart={() => setHovered(true)}
      onHoverEnd={() => setHovered(false)}
      whileHover={{ y: -6, scale: 1.05 }}
      transition={{ type: 'spring', stiffness: 300, damping: 20 }}
      className="card-aureate relative p-4 flex flex-col items-center justify-center min-h-[105px] cursor-pointer group hover:border-[var(--brass)] hover:shadow-lg hover:shadow-[var(--brass-soft)] transition-all duration-300"
    >
      {/* Company Logo Container */}
      <div className="w-14 h-14 rounded-xl bg-white p-1.5 border border-[var(--border)] flex items-center justify-center group-hover:border-[var(--brass)] transition-colors duration-300 overflow-hidden shadow-md">
        {!imgError && logoUrl ? (
          <img
            src={logoUrl}
            alt={`${name} logo`}
            onError={() => setImgError(true)}
            className="w-full h-full object-contain"
          />
        ) : (
          <div className="w-full h-full rounded-lg bg-[var(--surface-alt)] flex items-center justify-center font-display font-bold text-base text-[var(--brass)]">
            {name.charAt(0)}
          </div>
        )}
      </div>

      {/* Floating Tooltip Reveal on Hover */}
      <AnimatePresence>
        {hovered && (
          <motion.div
            initial={{ opacity: 0, y: 10, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 5, scale: 0.9 }}
            transition={{ duration: 0.15 }}
            className="absolute -top-12 z-20 px-3 py-1.5 rounded-lg bg-[var(--surface-high)] border border-[var(--brass)] text-center shadow-xl pointer-events-none whitespace-nowrap"
          >
            <span className="font-display font-medium text-xs text-[var(--ink)] block">{name}</span>
            <span className="text-[10px] font-mono text-[var(--brass)] block">{category}</span>
          </motion.div>
        )}
      </AnimatePresence>

      <span className="text-[11px] font-medium text-[var(--ink-muted)] group-hover:text-[var(--ink)] mt-2 transition-colors">
        {name}
      </span>
    </motion.div>
  );
};
