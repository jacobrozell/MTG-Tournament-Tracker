import { BrowserRouter, Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { Trophy, Users, BarChart3, Star } from 'lucide-react';
import { useAppStore } from './stores/useAppStore';
import { 
  TournamentsPage, 
  TournamentDetailPage,
  PlayersPage, 
  PlayerDetailPage,
  StatsPage, 
  AchievementsPage 
} from './pages';
import { cn } from './utils';
import { useEffect, useRef } from 'react';

function SyncStoreFromUrl() {
  const location = useLocation();
  const { setScreen, setActiveTournament, clearSelectedPlayer, selectPlayer } = useAppStore();
  const pathname = location.pathname;

  useEffect(() => {
    if (pathname === '/' || pathname === '') {
      setScreen('tournaments');
      setActiveTournament(null);
      clearSelectedPlayer();
    } else if (pathname.startsWith('/tournament/')) {
      const id = pathname.slice('/tournament/'.length);
      if (id) {
        setScreen('tournamentDetail');
        setActiveTournament(id);
      }
    } else if (pathname === '/players') {
      setScreen('players');
      clearSelectedPlayer();
    } else if (pathname.startsWith('/player/')) {
      const id = pathname.slice('/player/'.length);
      if (id) {
        setScreen('playerDetail');
        selectPlayer(id);
      }
    } else if (pathname === '/stats') {
      setScreen('stats');
    } else if (pathname === '/achievements') {
      setScreen('achievements');
    }
  }, [pathname, setScreen, setActiveTournament, clearSelectedPlayer, selectPlayer]);

  return null;
}

function TabBar() {
  const location = useLocation();
  const navigate = useNavigate();

  // Hide tab bar on detail pages
  if (location.pathname.startsWith('/tournament/') || location.pathname.startsWith('/player/')) {
    return null;
  }

  const tabs = [
    { id: 'tournaments', label: 'Tournaments', icon: Trophy, path: '/' },
    { id: 'players', label: 'Players', icon: Users, path: '/players' },
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
              'flex flex-col items-center justify-center min-w-[64px] min-h-[44px] py-2 px-3 rounded-lg transition-colors',
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
  const { currentScreen, activeTournamentId, selectedPlayerId } = useAppStore();
  const prevScreen = useRef(currentScreen);

  // Only navigate when currentScreen changes (from store actions)
  useEffect(() => {
    if (prevScreen.current !== currentScreen) {
      prevScreen.current = currentScreen;
      
      switch (currentScreen) {
        case 'tournamentDetail':
          if (activeTournamentId) {
            navigate(`/tournament/${activeTournamentId}`);
          }
          break;
        case 'playerDetail':
          if (selectedPlayerId) {
            navigate(`/player/${selectedPlayerId}`);
          }
          break;
        case 'players':
          navigate('/players');
          break;
        case 'stats':
          navigate('/stats');
          break;
        case 'achievements':
          navigate('/achievements');
          break;
        case 'tournaments':
        default:
          navigate('/');
          break;
      }
    }
  }, [currentScreen, navigate, activeTournamentId, selectedPlayerId]);

  return null;
}

function AppContent() {
  return (
    <div className="flex flex-col h-full bg-gray-50">
      <SyncStoreFromUrl />
      <ScreenRouter />
      <main className="flex-1 overflow-hidden flex flex-col">
        <Routes>
          <Route path="/" element={<TournamentsPage />} />
          <Route path="/tournament/:id" element={<TournamentDetailPage />} />
          <Route path="/players" element={<PlayersPage />} />
          <Route path="/player/:id" element={<PlayerDetailPage />} />
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
