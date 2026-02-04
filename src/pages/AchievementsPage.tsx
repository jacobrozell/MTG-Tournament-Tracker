import { useState, useMemo } from 'react';
import { useAppStore } from '../stores/useAppStore';
import { PageHeader, EmptyStateView, Modal, ModalActionBar } from '../components/layout';
import { AchievementListRow } from '../components/lists';
import { PrimaryActionButton } from '../components/buttons';
import { LabeledStepper, LabeledToggle } from '../components/forms';
import { getAllAchievementStats } from '../engines/statsEngine';

export function AchievementsPage() {
  const {
    achievements,
    gameResults,
    players,
    addAchievement,
    removeAchievement,
    setAchievementAlwaysOn,
  } = useAppStore();

  const achievementStatsById = useMemo(
    () => getAllAchievementStats(achievements, gameResults, players),
    [achievements, gameResults, players]
  );

  const [showNewModal, setShowNewModal] = useState(false);
  const [name, setName] = useState('');
  const [points, setPoints] = useState(1);
  const [alwaysOn, setAlwaysOn] = useState(false);

  const handleOpenNew = () => {
    setName('');
    setPoints(1);
    setAlwaysOn(false);
    setShowNewModal(true);
  };

  const handleCreate = () => {
    if (!name.trim()) return;
    addAchievement(name, points, alwaysOn);
    setShowNewModal(false);
  };

  return (
    <div className="flex-1 flex flex-col min-h-0 bg-gray-50">
      <PageHeader title="Achievements" onAdd={handleOpenNew} />

      {achievements.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center p-4">
          <EmptyStateView
            message="No achievements yet"
            hint="Add achievements to reward special plays"
          />
          <div className="mt-4 w-full max-w-xs">
            <PrimaryActionButton title="Add Achievement" onClick={handleOpenNew} />
          </div>
        </div>
      ) : (
        <div className="flex-1 min-h-0 overflow-y-auto">
          <div className="bg-white">
            {achievements.map((ach) => {
              const stats = achievementStatsById[ach.id];
              return (
                <AchievementListRow
                  key={ach.id}
                  name={ach.name}
                  points={ach.points}
                  alwaysOn={ach.alwaysOn}
                  onToggleAlwaysOn={(on) => setAchievementAlwaysOn(ach.id, on)}
                  onRemove={() => removeAchievement(ach.id)}
                  timesEarned={stats?.totalTimesEarned}
                  topPlayers={stats?.topPlayers.map((p) => ({ playerName: p.playerName, count: p.count }))}
                />
              );
            })}
          </div>
        </div>
      )}

      {/* New Achievement Modal */}
      <Modal
        isOpen={showNewModal}
        onClose={() => setShowNewModal(false)}
        title="New Achievement"
      >
        <div className="p-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Achievement Name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Enter achievement name"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          <LabeledStepper
            title="Points"
            value={points}
            onChange={setPoints}
            min={0}
            max={99}
          />

          <LabeledToggle
            title="Always on"
            checked={alwaysOn}
            onChange={setAlwaysOn}
          />
        </div>
        <ModalActionBar
          primaryTitle="Add Achievement"
          primaryAction={handleCreate}
          primaryDisabled={!name.trim()}
          secondaryTitle="Cancel"
          secondaryAction={() => setShowNewModal(false)}
        />
      </Modal>
    </div>
  );
}
