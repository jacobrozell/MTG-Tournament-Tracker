import { v4 as uuidv4 } from 'uuid';

export function generateId(): string {
  return uuidv4();
}

export function shuffleArray<T>(array: T[]): T[] {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

export function formatDateRange(startDate: string, endDate: string | null): string {
  const start = new Date(startDate);
  const options: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric' };
  const startStr = start.toLocaleDateString('en-US', options);
  
  if (!endDate) {
    return `${startStr} - Present`;
  }
  
  const end = new Date(endDate);
  const endOptions: Intl.DateTimeFormatOptions = { 
    month: 'short', 
    day: 'numeric',
    year: start.getFullYear() !== end.getFullYear() ? 'numeric' : undefined 
  };
  const endStr = end.toLocaleDateString('en-US', endOptions);
  
  if (start.getFullYear() !== end.getFullYear()) {
    return `${start.toLocaleDateString('en-US', { ...options, year: 'numeric' })} - ${endStr}`;
  }
  
  return `${startStr} - ${endStr}, ${end.getFullYear()}`;
}

export function cn(...classes: (string | boolean | undefined | null)[]): string {
  return classes.filter(Boolean).join(' ');
}
