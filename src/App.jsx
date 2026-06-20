import { useState, useEffect, useCallback } from 'react';
import { LOCATIONS } from './locations';
import './App.css';

const PHASES = {
  SETUP: 'setup',
  REVEAL: 'reveal',
  GAME: 'game',
  END: 'end',
};

function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function assignRoles(players) {
  const location = LOCATIONS[Math.floor(Math.random() * LOCATIONS.length)];
  const roles = shuffle([...location.roles]);
  const spyIndex = Math.floor(Math.random() * players.length);
  return players.map((name, i) => ({
    name,
    isSpy: i === spyIndex,
    role: i === spyIndex ? null : roles[i % roles.length],
    location: i === spyIndex ? null : location.name,
  }));
}

// ─── Setup Screen ─────────────────────────────────────────────────────────────

function SetupScreen({ onStart }) {
  const [players, setPlayers] = useState(['', '', '']);
  const [duration, setDuration] = useState(8);

  const removePlayer = (i) => {
    if (players.length <= 2) return;
    setPlayers(players.filter((_, idx) => idx !== i));
  };

  const updatePlayer = (i, val) => {
    const updated = [...players];
    updated[i] = val;
    setPlayers(updated);
  };

  const validPlayers = players.map((p) => p.trim()).filter(Boolean);
  const canStart = validPlayers.length >= 3;

  return (
    <div className="screen">
      <div className="setup-header">
        <div className="logo-icon">🕵️</div>
        <h1>Spyfall</h1>
        <p className="subtitle">Descubra o espião entre vocês</p>
      </div>

      <div className="card section">
        <div className="section-title">
          <h2>Jogadores</h2>
          <span className="badge">{validPlayers.length}</span>
        </div>
        <p className="hint">Mínimo 3 jogadores</p>

        <div className="player-list">
          {players.map((p, i) => (
            <div key={i} className="player-item">
              <span className="player-num">{i + 1}</span>
              <input
                className="player-input"
                value={p}
                placeholder={`Jogador ${i + 1}`}
                onChange={(e) => updatePlayer(i, e.target.value)}
                maxLength={20}
              />
              {players.length > 2 && (
                <button className="btn-icon-danger" onClick={() => removePlayer(i)}>✕</button>
              )}
            </div>
          ))}
        </div>

        <button
          className="btn btn-secondary"
          style={{ marginTop: 12 }}
          onClick={() => setPlayers([...players, ''])}
        >
          + Adicionar jogador
        </button>
      </div>

      <div className="card section">
        <h2>Duração da rodada</h2>
        <div className="duration-row">
          {[6, 8, 10, 12].map((m) => (
            <button
              key={m}
              className={`duration-btn ${duration === m ? 'active' : ''}`}
              onClick={() => setDuration(m)}
            >
              {m} min
            </button>
          ))}
        </div>
      </div>

      <button
        className="btn btn-primary"
        disabled={!canStart}
        onClick={() => onStart(validPlayers, duration)}
      >
        🎮 Iniciar Jogo
      </button>

      {!canStart && (
        <p className="hint center" style={{ marginTop: 12 }}>
          Adicione pelo menos 3 jogadores para começar
        </p>
      )}
    </div>
  );
}

// ─── Reveal Screen ────────────────────────────────────────────────────────────

function RevealScreen({ assignments, currentIndex, onNext, onStartGame }) {
  const [showing, setShowing] = useState(false);
  const current = assignments[currentIndex];
  const isLast = currentIndex === assignments.length - 1;

  const handleNext = () => {
    setShowing(false);
    if (isLast) onStartGame();
    else onNext();
  };

  return (
    <div className="screen">
      <div className="reveal-header">
        <p className="hint center">Passe para o jogador</p>
        <h2 className="reveal-name">{current.name}</h2>
      </div>

      <div className="progress-bar">
        {assignments.map((_, i) => (
          <div
            key={i}
            className={`progress-seg ${i < currentIndex ? 'done' : i === currentIndex ? 'current' : ''}`}
          />
        ))}
      </div>

      {!showing ? (
        <div className="card hidden-card">
          <div className="card-back-icon">🃏</div>
          <p className="card-back-title">Carta de <strong>{current.name}</strong></p>
          <p className="hint">Os outros devem virar o rosto 👀</p>
          <button className="btn btn-primary" style={{ marginTop: 20 }} onClick={() => setShowing(true)}>
            Ver minha carta
          </button>
        </div>
      ) : (
        <div className={`card role-card ${current.isSpy ? 'spy-card' : 'player-card'}`}>
          {current.isSpy ? (
            <div className="role-card-inner">
              <div className="big-icon">🕵️</div>
              <span className="tag tag-spy">ESPIÃO</span>
              <p className="role-description">
                Você não sabe o local. Faça perguntas, blefe e descubra sem ser pego!
              </p>
            </div>
          ) : (
            <div className="role-card-inner">
              <div className="location-section">
                <span className="field-label">📍 Local</span>
                <div className="field-value location-value">{current.location}</div>
              </div>
              <div className="divider" />
              <div className="role-section">
                <span className="field-label">🎭 Seu papel</span>
                <div className="field-value role-value">{current.role}</div>
              </div>
              <span className="tag tag-player">JOGADOR</span>
            </div>
          )}
          <button className="btn btn-primary" style={{ marginTop: 20 }} onClick={handleNext}>
            {isLast ? '🚀 Começar o jogo!' : 'Próximo jogador →'}
          </button>
        </div>
      )}
    </div>
  );
}

// ─── Game Screen ──────────────────────────────────────────────────────────────

function GameScreen({ assignments, duration, onEnd }) {
  const total = duration * 60;
  const [seconds, setSeconds] = useState(total);
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    if (paused || seconds <= 0) return;
    const id = setInterval(() => setSeconds((s) => s - 1), 1000);
    return () => clearInterval(id);
  }, [paused, seconds]);

  useEffect(() => {
    if (seconds <= 0) onEnd('timeout');
  }, [seconds, onEnd]);

  const pct = seconds / total;
  const mins = String(Math.floor(seconds / 60)).padStart(2, '0');
  const secs = String(seconds % 60).padStart(2, '0');
  const urgent = seconds <= 60;
  const circumference = 2 * Math.PI * 45;

  return (
    <div className="screen">
      <div className={`timer-wrap ${urgent ? 'urgent' : ''}`}>
        <svg className="timer-svg" viewBox="0 0 100 100">
          <circle cx="50" cy="50" r="45" className="ring-bg" />
          <circle
            cx="50" cy="50" r="45"
            className="ring-fg"
            strokeDasharray={circumference}
            strokeDashoffset={circumference * (1 - pct)}
            transform="rotate(-90 50 50)"
          />
        </svg>
        <div className="timer-inner">
          <span className="timer-digits">{mins}:{secs}</span>
          {urgent && <span className="timer-urgent-label">⚡ URGENTE</span>}
        </div>
      </div>

      <div className="card section">
        <h2>Jogadores</h2>
        <div className="players-grid">
          {assignments.map((a) => (
            <div key={a.name} className="player-badge">{a.name}</div>
          ))}
        </div>
      </div>

      <div className="card section mystery-card">
        <span className="mystery-icon">🔐</span>
        <p className="mystery-text">Local secreto desta rodada</p>
        <p className="mystery-sub">Somente os jogadores sabem — o espião não!</p>
      </div>

      <div className="game-actions">
        <button className="btn btn-secondary" onClick={() => setPaused((p) => !p)}>
          {paused ? '▶ Continuar' : '⏸ Pausar'}
        </button>
        <button className="btn btn-accent" onClick={() => onEnd('vote')}>
          🗳 Revelar espião
        </button>
      </div>
    </div>
  );
}

// ─── End Screen ───────────────────────────────────────────────────────────────

function EndScreen({ assignments, reason, onRestart }) {
  const spy = assignments.find((a) => a.isSpy);
  const location = assignments.find((a) => !a.isSpy)?.location;
  const [revealed, setRevealed] = useState(false);

  return (
    <div className="screen">
      <div className="end-header">
        <div className="end-icon">{reason === 'timeout' ? '⏰' : '🗳️'}</div>
        <h1>{reason === 'timeout' ? 'Tempo esgotado!' : 'Hora de revelar!'}</h1>
        <p className="subtitle">
          {reason === 'timeout' ? 'Votem: quem é o espião?' : 'Confiram o resultado da rodada'}
        </p>
      </div>

      <div className="card section">
        <span className="field-label">📍 Local desta rodada</span>
        <div className="field-value location-value" style={{ marginTop: 8 }}>{location}</div>
      </div>

      <div className="card section">
        <h2>🕵️ O espião era...</h2>
        {!revealed ? (
          <button className="btn btn-primary" style={{ marginTop: 12 }} onClick={() => setRevealed(true)}>
            Revelar espião
          </button>
        ) : (
          <div className="spy-reveal">
            <div className="spy-name">{spy.name}</div>
            <span className="tag tag-spy">ESPIÃO</span>
          </div>
        )}
      </div>

      {revealed && (
        <div className="card section">
          <h2>Papéis desta rodada</h2>
          <div className="roles-list">
            {assignments.map((a) => (
              <div key={a.name} className={`role-row ${a.isSpy ? 'row-spy' : ''}`}>
                <span className="role-row-name">{a.name}</span>
                <span className="role-row-role">
                  {a.isSpy ? '🕵️ Espião' : a.role}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      <button className="btn btn-primary" onClick={onRestart}>
        🔄 Jogar novamente
      </button>
    </div>
  );
}

// ─── Main App ─────────────────────────────────────────────────────────────────

export default function App() {
  const [phase, setPhase] = useState(PHASES.SETUP);
  const [assignments, setAssignments] = useState([]);
  const [revealIndex, setRevealIndex] = useState(0);
  const [duration, setDuration] = useState(8);
  const [endReason, setEndReason] = useState(null);

  const handleStart = (players, mins) => {
    setAssignments(assignRoles(players));
    setDuration(mins);
    setRevealIndex(0);
    setPhase(PHASES.REVEAL);
  };

  const handleEnd = useCallback((reason) => {
    setEndReason(reason);
    setPhase(PHASES.END);
  }, []);

  return (
    <div className="app">
      {phase === PHASES.SETUP && <SetupScreen onStart={handleStart} />}
      {phase === PHASES.REVEAL && (
        <RevealScreen
          assignments={assignments}
          currentIndex={revealIndex}
          onNext={() => setRevealIndex((i) => i + 1)}
          onStartGame={() => setPhase(PHASES.GAME)}
        />
      )}
      {phase === PHASES.GAME && (
        <GameScreen assignments={assignments} duration={duration} onEnd={handleEnd} />
      )}
      {phase === PHASES.END && (
        <EndScreen
          assignments={assignments}
          reason={endReason}
          onRestart={() => { setAssignments([]); setPhase(PHASES.SETUP); }}
        />
      )}
    </div>
  );
}
