"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";

type Category = "Focus" | "Meetings" | "Admin" | "Drift";
type Entry = {
  id: number;
  title: string;
  detail: string;
  category: Category;
  minutes: number;
  start: string;
};

const CATEGORY_COLORS: Record<Category, string> = {
  Focus: "#16856b",
  Meetings: "#5b6bc7",
  Admin: "#d88a31",
  Drift: "#d95d52",
};

const INITIAL_ENTRIES: Entry[] = [];

const NAV_ITEMS = ["Today", "Review", "Patterns"] as const;
type View = (typeof NAV_ITEMS)[number];

function formatDuration(minutes: number) {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return hours ? `${hours}h ${mins}m` : `${mins}m`;
}

function getTodayLabel() {
  return new Intl.DateTimeFormat("en-GB", {
    weekday: "long",
    day: "numeric",
    month: "long",
  }).format(new Date());
}

export default function Home() {
  const [view, setView] = useState<View>("Today");
  const [entries, setEntries] = useState<Entry[]>(INITIAL_ENTRIES);
  const [activity, setActivity] = useState("");
  const [category, setCategory] = useState<Category>("Focus");
  const [minutes, setMinutes] = useState("30");
  const [tracking, setTracking] = useState(false);
  const [running, setRunning] = useState(false);
  const [elapsed, setElapsed] = useState(0);
  const [notice, setNotice] = useState("");

  useEffect(() => {
    try {
      const stored = localStorage.getItem("reality-entries");
      if (stored) setEntries(JSON.parse(stored));
    } catch {
      // A private local store may be unavailable in strict browser modes.
    }
  }, []);

  useEffect(() => {
    if (!running) return;
    const timer = window.setInterval(() => setElapsed((value) => value + 1), 1000);
    return () => window.clearInterval(timer);
  }, [running]);

  const totals = useMemo(() => {
    const result: Record<Category, number> = { Focus: 0, Meetings: 0, Admin: 0, Drift: 0 };
    entries.forEach((entry) => (result[entry.category] += entry.minutes));
    return result;
  }, [entries]);

  const totalMinutes = Object.values(totals).reduce((sum, value) => sum + value, 0);
  const intentionalMinutes = totals.Focus + totals.Meetings;
  const score = totalMinutes ? Math.round((intentionalMinutes / totalMinutes) * 100) : 0;

  function persist(next: Entry[]) {
    setEntries(next);
    try {
      localStorage.setItem("reality-entries", JSON.stringify(next));
    } catch {
      setNotice("Saved for this session only — browser storage is unavailable.");
    }
  }

  function addEntry(event: FormEvent) {
    event.preventDefault();
    const duration = running ? Math.max(1, Math.ceil(elapsed / 60)) : Number(minutes);
    if (!activity.trim() || !duration) {
      setNotice("Name the activity and add its duration.");
      return;
    }
    const now = new Date();
    const start = now.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
    const next = [
      ...entries,
      { id: Date.now(), title: activity.trim(), detail: "Added manually", category, minutes: duration, start },
    ];
    persist(next);
    setActivity("");
    setElapsed(0);
    setRunning(false);
    setNotice("Activity added. Your picture of today is more honest now.");
  }

  function deleteEntry(id: number) {
    persist(entries.filter((entry) => entry.id !== id));
  }

  function toggleTracking() {
    if (!tracking) {
      setTracking(true);
      setNotice("Automatic tracking is queued. This prototype keeps all current data on this device; a desktop helper will be required for app and website capture.");
    } else {
      setTracking(false);
      setNotice("Automatic tracking request cancelled.");
    }
  }

  if (view !== "Today") {
    return (
      <main className="app-shell">
        <Sidebar view={view} setView={setView} tracking={tracking} />
        <section className="content review-content">
          <header className="topbar">
            <button className="mobile-mark" onClick={() => setView("Today")} aria-label="Return to today">R</button>
            <span className="privacy-pill"><span /> PRIVATE · ON THIS DEVICE</span>
          </header>
          <div className="review-hero">
            <p className="eyebrow">{view === "Review" ? "WEEKLY REVIEW" : "BEHAVIOUR PATTERNS"}</p>
            <h1>{view === "Review" ? "Face the week." : "Notice what repeats."}</h1>
            <p>{view === "Review" ? "A clear summary of where your hours went — and one decision for next week." : "Patterns become choices once you can see them."}</p>
          </div>
          <div className="review-grid">
            <article className="review-score"><span>Intentional time</span><strong>{score}%</strong><small>{formatDuration(intentionalMinutes)} of {formatDuration(totalMinutes)} tracked</small></article>
            <article className="review-card"><span className="card-kicker">REPEATING LEAK</span><h2>{totalMinutes ? "Your largest drift block" : "Not enough data yet"}</h2><p>{totalMinutes ? "Reality will identify repeated distraction patterns after several recorded days." : "Record a few real days before drawing conclusions."}</p></article>
            <article className="review-card"><span className="card-kicker">BEST WINDOW</span><h2>{totalMinutes ? "Your strongest focus block" : "Waiting for evidence"}</h2><p>{totalMinutes ? "Your most reliable focus window will appear here as the pattern becomes stable." : "Reality does not invent patterns from missing data."}</p></article>
          </div>
          <button className="back-button" onClick={() => setView("Today")}>← Back to today</button>
        </section>
      </main>
    );
  }

  return (
    <main className="app-shell">
      <Sidebar view={view} setView={setView} tracking={tracking} />
      <section className="content">
        <header className="topbar">
          <button className="mobile-mark" onClick={() => setView("Today")} aria-label="Open today">R</button>
          <nav className="mobile-nav" aria-label="Mobile navigation">
            {NAV_ITEMS.map((item) => <button key={item} onClick={() => setView(item)} className={view === item ? "active" : ""}>{item}</button>)}
          </nav>
          <span className="privacy-pill"><span /> PRIVATE · ON THIS DEVICE</span>
        </header>

        <div className="page-heading">
          <div>
            <p className="eyebrow">{getTodayLabel().toUpperCase()}</p>
            <h1>Here’s where your day went.</h1>
          </div>
          <div className="day-controls" aria-label="Day controls">
            <button aria-label="Previous day">←</button><span>Today</span><button aria-label="Next day" disabled>→</button>
          </div>
        </div>

        <section className="score-grid">
          <article className="score-card">
            <div className="score-ring" style={{ "--score": `${score * 3.6}deg` } as React.CSSProperties}>
              <div><strong>{score}</strong><span>/100</span></div>
            </div>
            <div className="score-copy">
              <span className="card-kicker">INTENTIONAL TIME</span>
              <h2>{!totalMinutes ? "Start with an honest record." : score >= 70 ? "You protected the important work." : "You were pulled off course."}</h2>
              <p>{totalMinutes ? `${formatDuration(intentionalMinutes)} of ${formatDuration(totalMinutes)} tracked served work you chose.` : "Add an activity or start the timer. No conclusions until there is evidence."}</p>
            </div>
          </article>
          <article className="truth-card">
            <div className="truth-icon">!</div>
            <div><span className="card-kicker">REALITY CHECK</span><h2>{totals.Drift ? `You lost ${formatDuration(totals.Drift)} to reactive browsing.` : "No drift recorded yet."}</h2><p>{totals.Drift ? "That is your largest recoverable block today." : "Reality will only report what you actually record."}</p></div>
          </article>
        </section>

        <section className="capture-card">
          <div className="capture-heading">
            <div><span className="card-kicker">CAPTURE THE TRUTH</span><h2>What did you just do?</h2></div>
            <button className={`timer-button ${running ? "running" : ""}`} onClick={() => setRunning(!running)}>{running ? `Stop · ${Math.floor(elapsed / 60)}:${String(elapsed % 60).padStart(2, "0")}` : "Start timer"}</button>
          </div>
          <form onSubmit={addEntry}>
            <label className="activity-field"><span>Activity</span><input value={activity} onChange={(event) => setActivity(event.target.value)} placeholder="e.g. Client proposal" /></label>
            <label><span>Type</span><select value={category} onChange={(event) => setCategory(event.target.value as Category)}>{Object.keys(CATEGORY_COLORS).map((item) => <option key={item}>{item}</option>)}</select></label>
            <label><span>Minutes</span><input type="number" min="1" max="720" value={minutes} disabled={running} onChange={(event) => setMinutes(event.target.value)} /></label>
            <button className="add-button" type="submit">Add to today <span>→</span></button>
          </form>
          {notice && <button className="notice" onClick={() => setNotice("")} aria-label="Dismiss message">{notice}<span>×</span></button>}
        </section>

        <section className="day-section">
          <div className="section-heading"><div><span className="card-kicker">TODAY’S RECORD</span><h2>{entries.length} activities · {formatDuration(totalMinutes)}</h2></div><span className="sync-note">Saved locally</span></div>
          <div className="allocation" aria-label="Time allocation">
            {totalMinutes > 0 && (Object.keys(CATEGORY_COLORS) as Category[]).map((item) => totals[item] > 0 && <div key={item} style={{ width: `${(totals[item] / totalMinutes) * 100}%`, background: CATEGORY_COLORS[item] }} title={`${item}: ${formatDuration(totals[item])}`} />)}
          </div>
          <div className="legend">{(Object.keys(CATEGORY_COLORS) as Category[]).map((item) => <span key={item}><i style={{ background: CATEGORY_COLORS[item] }} />{item} <b>{formatDuration(totals[item])}</b></span>)}</div>
          <div className="timeline">
            {!entries.length && <p className="empty-state">Nothing recorded yet. Start the timer or add your first real activity.</p>}
            {entries.map((entry) => (
              <article className="timeline-row" key={entry.id}>
                <time>{entry.start}</time><span className="timeline-dot" style={{ borderColor: CATEGORY_COLORS[entry.category] }} />
                <div><h3>{entry.title}</h3><p>{entry.detail}</p></div>
                <span className="category-tag" style={{ color: CATEGORY_COLORS[entry.category] }}>{entry.category}</span>
                <strong>{formatDuration(entry.minutes)}</strong>
                <button className="delete-button" onClick={() => deleteEntry(entry.id)} aria-label={`Delete ${entry.title}`}>×</button>
              </article>
            ))}
          </div>
        </section>

        <section className="tomorrow-card">
          <div><span className="card-kicker">ONE CORRECTION FOR TOMORROW</span><h2>Protect the first two hours.</h2><p>Keep messages and news closed until your first chosen outcome is finished.</p></div>
          <label><input type="checkbox" /> Make this tomorrow’s intention</label>
        </section>

        <section className="tracker-card">
          <div className="tracker-mark">⌁</div><div><span className="card-kicker">AUTOMATIC TRACKING</span><h2>{tracking ? "Desktop helper requested" : "Make the record effortless"}</h2><p>{tracking ? "We’ll keep this opt-in. Current data remains private and local." : "A small desktop helper can capture active apps and websites. Nothing leaves your device."}</p></div>
          <button onClick={toggleTracking}>{tracking ? "Cancel request" : "Join the next step"}</button>
        </section>
        <footer><strong>REALITY</strong><span>Your time is your life in concrete form.</span><small>Local-first · No account</small></footer>
      </section>
    </main>
  );
}

function Sidebar({ view, setView, tracking }: { view: View; setView: (view: View) => void; tracking: boolean }) {
  return <aside className="sidebar"><div className="brand"><span>R</span><strong>REALITY</strong></div><p className="brand-line">See your time.<br />Change your life.</p><nav aria-label="Primary navigation">{NAV_ITEMS.map((item, index) => <button key={item} onClick={() => setView(item)} className={view === item ? "active" : ""}><span>{index === 0 ? "◷" : index === 1 ? "▤" : "↗"}</span>{item}</button>)}</nav><div className="sidebar-spacer" /><button className="tracking-status" onClick={() => setView("Today")}><span className={tracking ? "connected" : ""} /><div><small>AUTO-TRACKING</small><strong>{tracking ? "Requested" : "Not connected"}</strong></div><b>›</b></button><p className="local-note">Your data stays on this device.</p></aside>;
}
