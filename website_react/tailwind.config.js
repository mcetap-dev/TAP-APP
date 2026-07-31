export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: {
          brass: '#C5A059',
          brassSoft: 'rgba(197, 160, 89, 0.15)',
          paperGrey: '#F5F5F7',
          paperGreyDark: '#12141C',
          trueBlack: '#000000',
          navySlate: '#0B0E14',
          cardBorder: '#27272A',
          statusShortlisted: '#22C55E',
          statusRejected: '#EF4444',
          statusPending: '#F59E0B',
        }
      },
      fontFamily: {
        fraunces: ['Fraunces', 'serif'],
        inter: ['Inter', 'sans-serif'],
        mono: ['IBM Plex Mono', 'monospace'],
      }
    },
  },
  plugins: [],
}
