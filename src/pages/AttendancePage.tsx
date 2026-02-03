import { useState, useEffect, useMemo } from 'react';
import { useAppStore } from '../stores/useAppStore';
import { PageHeader, SectionHeader } from '../components/layout';
import { PrimaryActionButton } from '../components/buttons';
import { LabeledToggle } from '../components/forms';
import { Plus } from 'lucide-react';

export function AttendancePage() {
  const {
    players,
    getActiveTournament,
    confirmAttendance,
    addWeeklyPlayer,
    setScreen,
  } = useAppStore();

  const tournament = getActiveTournament();
  const [presentIds, setPresentIds] = useState<Set<string>>(new Set());
  const [achievementsOn, setAchievementsOn] = useState(true);
  const [newPlayerName, setNewPlayerName] = useState('');

  // Filter to only players selected for this tournament
  const tournamentPlayers = useMemo(() => {
    if (!tournament) return [];
    const selectedIds = new Set(tournament.selectedPlayerIds || []);
    return players.filter((p) => selectedIds.has(p.id));
  }, [players, tournament]);

  useEffect(() => {
    // Default: all tournament players present
    setPresentIds(new Set(tournamentPlayers.map((p) => p.id)));
  }, [tournamentPlayers]);

  if (!tournament) {
    return (
      <div className="flex-1 flex items-center justify-center p-4">
        <p className="text-gray-500">No active tournament</p>
      </div>
    );
  }

  const handleConfirm = () => {
    if (presentIds.size === 0) return;
    confirmAttendance(Array.from(presentIds), achievementsOn);
  };

  const handleAddPlayer = () => {
    if (!newPlayerName.trim()) return;
    const player = addWeeklyPlayer(newPlayerName);
    if (player) {
      setPresentIds((prev) => new Set([...prev, player.id]));
      setNewPlayerName('');
    }
  };

  const togglePlayer = (id: string, checked: boolean) => {
    setPresentIds((prev) => {
      const next = new Set(prev);
      if (checked) {
        next.add(id);
      } else {
        next.delete(id);
      }
      return next;
    });
  };

  const handleBack = () => {
    setScreen('tournaments');
  };

  return (
    <div className="flex-1 flex flex-col bg-gray-50">
      <PageHeader 
        title={`Attendance - Week ${tournament.currentWeek}`} 
        onBack={handleBack}
      />

      <div className="flex-1 overflow-y-auto">
        <SectionHeader title="This Week" />
        <div className="bg-white px-4">
          <LabeledToggle
            title="Count achievements this week"
            checked={achievementsOn}
            onChange={setAchievementsOn}
          />
        </div>

        <SectionHeader title={`Players (${presentIds.size} present)`} />
        <div className="bg-white">
          {tournamentPlayers.map((p) => (
            <label
              key={p.id}
              className="flex items-center gap-3 px-4 py-3 border-b border-gray-100 cursor-pointer hover:bg-gray-50"
            >
              <input
                type="checkbox"
                checked={presentIds.has(p.id)}
                onChange={(e) => togglePlayer(p.id, e.target.checked)}
                className="w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span className="text-gray-900 font-medium">{p.name}</span>
            </label>
          ))}

          <div className="flex gap-2 p-4 border-t border-gray-200">
            <input
              type="text"
              value={newPlayerName}
              onChange={(e) => setNewPlayerName(e.target.value)}
              placeholder="Add player this week"
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              onKeyDown={(e) => e.key === 'Enter' && handleAddPlayer()}
            />
            <button
              onClick={handleAddPlayer}
              className="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
            >
              <Plus className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      <div className="p-4 bg-white border-t border-gray-200">
        <PrimaryActionButton
          title="Confirm Attendance"
          onClick={handleConfirm}
          disabled={presentIds.size === 0}
        />
      </div>
    </div>
  );
}
