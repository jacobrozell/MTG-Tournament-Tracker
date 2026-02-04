import { useState } from 'react';
import { ChevronRight, Trash2, Plus } from 'lucide-react';
import { useAppStore } from '../stores/useAppStore';
import { PageHeader, EmptyStateView, Modal, ModalActionBar } from '../components/layout';
import { PrimaryActionButton } from '../components/buttons';
import { sortPlayersByTotalPoints } from '../engines/statsEngine';

export function PlayersPage() {
  const {
    players,
    getPlayerAchievementHistory,
    addPlayer,
    removePlayer,
    selectPlayer,
  } = useAppStore();

  const [showAddModal, setShowAddModal] = useState(false);
  const [newPlayerName, setNewPlayerName] = useState('');

  const sortedPlayers = sortPlayersByTotalPoints(players);

  const handleOpenAdd = () => {
    setNewPlayerName('');
    setShowAddModal(true);
  };

  const handleAddPlayer = () => {
    if (!newPlayerName.trim()) return;
    addPlayer(newPlayerName);
    setNewPlayerName('');
    setShowAddModal(false);
  };

  const handleDeletePlayer = (id: string, name: string) => {
    if (!window.confirm(`Delete ${name}? This cannot be undone.`)) return;
    removePlayer(id);
  };

  const handlePlayerClick = (id: string) => {
    selectPlayer(id);
  };

  const getPlayerSummary = (player: (typeof players)[0]) => {
    const totalPoints = player.placementPoints + player.achievementPoints;
    const parts: string[] = [];
    if (totalPoints > 0) parts.push(`${totalPoints} pts`);
    if (player.wins > 0) parts.push(`${player.wins} wins`);
    if (player.gamesPlayed > 0) parts.push(`${player.gamesPlayed} games`);
    const achievementCount = getPlayerAchievementHistory(player.id).length;
    if (achievementCount > 0) parts.push(`${achievementCount} achievement${achievementCount !== 1 ? 's' : ''}`);
    return parts.length > 0 ? parts.join(' · ') : 'No games played';
  };

  return (
    <div className="flex-1 flex flex-col min-h-0 bg-gray-50">
      <PageHeader title="Players" onAdd={handleOpenAdd} />

      {players.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center p-4">
          <EmptyStateView
            message="No players yet"
            hint="Add players to get started"
          />
          <div className="mt-4 w-full max-w-xs">
            <PrimaryActionButton title="Add Player" onClick={handleOpenAdd} />
          </div>
        </div>
      ) : (
        <div className="flex-1 min-h-0 overflow-y-auto">
          {/* Inline add row at top */}
          <div className="bg-white border-b border-gray-100 px-4 py-3 flex gap-2 items-center">
            <input
              type="text"
              value={newPlayerName}
              onChange={(e) => setNewPlayerName(e.target.value)}
              placeholder="Add new player"
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              onKeyDown={(e) => e.key === 'Enter' && handleAddPlayer()}
            />
            <button
              onClick={handleAddPlayer}
              disabled={!newPlayerName.trim()}
              className="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors disabled:opacity-50"
            >
              <Plus className="w-5 h-5" />
            </button>
          </div>
          {sortedPlayers.map((player) => (
            <div
              key={player.id}
              className="flex items-center bg-white border-b border-gray-100"
            >
              <button
                onClick={() => handlePlayerClick(player.id)}
                className="flex-1 flex items-center justify-between min-h-[60px] py-3 px-4 hover:bg-gray-50 transition-colors text-left"
              >
                <div>
                  <span className="text-gray-900 font-medium">{player.name}</span>
                  <p className="text-sm text-gray-500 mt-0.5">
                    {getPlayerSummary(player)}
                  </p>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </button>
              <button
                onClick={() => handleDeletePlayer(player.id, player.name)}
                aria-label={`Delete ${player.name}`}
                className="w-12 h-12 flex items-center justify-center text-red-500 hover:bg-red-50 transition-colors"
              >
                <Trash2 className="w-5 h-5" />
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Add Player Modal */}
      <Modal
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
        title="Add Player"
      >
        <div className="p-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Player Name
            </label>
            <div className="flex gap-2">
              <input
                type="text"
                value={newPlayerName}
                onChange={(e) => setNewPlayerName(e.target.value)}
                placeholder="Enter player name"
                className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                onKeyDown={(e) => e.key === 'Enter' && handleAddPlayer()}
                autoFocus
              />
              <button
                onClick={handleAddPlayer}
                disabled={!newPlayerName.trim()}
                className="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors disabled:opacity-50"
              >
                <Plus className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
        <ModalActionBar
          primaryTitle="Add Player"
          primaryAction={handleAddPlayer}
          primaryDisabled={!newPlayerName.trim()}
          secondaryTitle="Cancel"
          secondaryAction={() => setShowAddModal(false)}
        />
      </Modal>
    </div>
  );
}
