import { BrowserRouter, Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { Trophy, Users, BarChart3, Star } from 'lucide-react';
import { useAppStore } from './stores/useAppStore';
import { TournamentsPage, AttendancePage, PodsPage, StatsPage, AchievementsPage } from './pages';
import { cn } from './utils';
import { useEffect, useRef } from 'react';

function TabBar() {
  const location = useLocation();
  const navigate = useNavigate();

  // Hide tab bar on attendance page
  if (location.pathname === '/attendance') {
    return null;
  }

  const tabs = [
    { id: 'tournaments', label: 'Tournaments', icon: Trophy, path: '/' },
    { id: 'pods', label: 'Pods', icon: Users, path: '/pods' },
    { id: 'stats', label: 'Stats', icon: BarChart3, path: '/stats' },
    { id: 'achievements', label: 'Achievements', icon: Star, path: '/achievements' },
  ];

  const currentPath = location.pathname;

  return (
    <nav className="flex items-center justify-around bg-white border-t border-gray-200 px-2 py-1 safe-area-pb">
      {tabs.map((tab) => {
        const isActive = currentPath === tab.path || (tab.path === '/' && currentPath === '');
        const Icon = tab.icon;

        return (
          <button
            key={tab.id}
            onClick={() => navigate(tab.path)}
            className={cn(
              'flex flex-col items-center justify-center min-w-[64px] py-2 px-3 rounded-lg transition-colors',
              isActive ? 'text-blue-600' : 'text-gray-500 hover:text-gray-700'
            )}
          >
            <Icon className="w-6 h-6" />
            <span className="text-xs mt-1 font-medium">{tab.label}</span>
          </button>
        );
      })}
    </nav>
  );
}

function ScreenRouter() {
  const navigate = useNavigate();
  const { currentScreen } = useAppStore();
  const prevScreen = useRef(currentScreen);

  // Only navigate when currentScreen changes (from store actions)
  useEffect(() => {
    if (prevScreen.current !== currentScreen) {
      prevScreen.current = currentScreen;
      
      switch (currentScreen) {
        case 'attendance':
          navigate('/attendance');
          break;
        case 'pods':
          navigate('/pods');
          break;
        case 'tournamentStandings':
        case 'tournaments':
          navigate('/');
          break;
      }
    }
  }, [currentScreen, navigate]);

  return null;
}

function AppContent() {
  return (
    <div className="flex flex-col h-screen bg-gray-50">
      <ScreenRouter />
      <main className="flex-1 overflow-hidden flex flex-col">
        <Routes>
          <Route path="/" element={<TournamentsPage />} />
          <Route path="/attendance" element={<AttendancePage />} />
          <Route path="/pods" element={<PodsPage />} />
          <Route path="/stats" element={<StatsPage />} />
          <Route path="/achievements" element={<AchievementsPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
      <TabBar />
    </div>
  );
}

const basename = import.meta.env.BASE_URL.replace(/\/$/, '')

export default function App() {
  return (
    <BrowserRouter basename={basename}>
      <AppContent />
    </BrowserRouter>
  );
}
