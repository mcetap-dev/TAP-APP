import React, { useState, useEffect } from 'react';
import { Sun, Moon } from 'lucide-react';

export const ThemeToggle: React.FC = () => {
  const [theme, setTheme] = useState<'dark' | 'light'>(() => {
    const savedTheme = localStorage.getItem('app-theme');
    return (savedTheme as 'dark' | 'light') || 'dark';
  });

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('app-theme', theme);
  }, [theme]);

  const toggleTheme = (newTheme: 'dark' | 'light') => {
    setTheme(newTheme);
  };

  return (
    <div className="flex gap-1 bg-[#1B1C20] p-1 rounded-xl border border-[#232428]">
      <button
        onClick={() => toggleTheme('dark')}
        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
          theme === 'dark'
            ? 'bg-[#111214] text-[#F2F1EC] shadow-md border border-[#232428]'
            : 'text-[#9AA3AF] hover:text-[#F2F1EC]'
        }`}
      >
        <Moon className="w-3.5 h-3.5 text-[#C89446]" />
        <span>Dark</span>
      </button>

      <button
        onClick={() => toggleTheme('light')}
        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
          theme === 'light'
            ? 'bg-[#FFFFFF] text-[#14171C] shadow-md'
            : 'text-[#9AA3AF] hover:text-[#F2F1EC]'
        }`}
      >
        <Sun className="w-3.5 h-3.5 text-[#A9752F]" />
        <span>Light</span>
      </button>
    </div>
  );
};
