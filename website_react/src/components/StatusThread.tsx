import React from 'react';

interface StatusThreadProps {
  stages: string[];
  currentIndex: number;
}

export const StatusThread: React.FC<StatusThreadProps> = ({ stages, currentIndex }) => {
  const progressPercent = Math.min(100, Math.max(0, (currentIndex / (stages.length - 1)) * 100));

  return (
    <div className="w-full overflow-x-auto no-scrollbar">
      <div className="relative min-w-[320px] w-full pt-4 pb-2 px-1">
        {/* Background Thread Track */}
        <div className="absolute top-[22px] left-[35px] right-[35px] h-[2px] bg-[var(--border)]" />
        
        {/* Active Fill Line */}
        <div 
          className="absolute top-[22px] left-[35px] h-[2px] bg-[var(--brass)] transition-all duration-500 ease-out"
          style={{ width: `calc(${progressPercent}% * 0.88)` }}
        />

        <div className="relative flex justify-between items-start">
          {stages.map((stage, idx) => {
            const isDone = idx < currentIndex;
            const isCurrent = idx === currentIndex;

            return (
              <div key={stage} className="flex flex-col items-center gap-2 w-16">
                <div 
                  className={`w-[10px] h-[10px] rounded-full transition-all duration-300 ${
                    isDone
                      ? 'bg-[var(--brass)] border-2 border-[var(--brass)]'
                      : isCurrent
                        ? 'bg-[var(--surface)] border-2 border-[var(--brass)] ring-4 ring-[var(--brass-soft)] scale-125'
                        : 'bg-[var(--surface)] border-2 border-[var(--border)]'
                  }`}
                />
                <span className={`text-[11px] font-semibold text-center leading-tight ${
                  isCurrent || isDone ? 'text-[var(--ink)]' : 'text-[var(--ink-muted)]'
                }`}>
                  {stage}
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
