import React, { useState, useEffect, useRef } from "react";
import HistoryList, { HistoryItem } from "@/components/HistoryList";
import KeywordBank from "@/components/KeywordBank";

/* ───────── Types & constants ───────── */
type ImpactResponse = { summary: string; policies: string[] };

const LOCAL_RESULT  = "eventImpact";
const LOCAL_HISTORY = "eventImpact_history";
const HISTORY_LIMIT = 20;

const MOCK_KEYWORDS = ["Downtime", "Compliance", "Security", "Performance", "SLA breach"];

/* ───────── Fake API helper ───────── */
const mockApi = (description: string): Promise<ImpactResponse> =>
  new Promise((resolve) =>
    setTimeout(() => {
      const hash = description.length % 3;
      resolve(
        hash === 0
          ? { summary: "System outage caused by data‑centre power failure.", policies: ["BCP‑001", "DR‑004"] }
          : hash === 1
          ? { summary: "Planned maintenance window extended beyond schedule.", policies: ["MAINT‑02", "SLA‑99"] }
          : { summary: "Unexpected traffic spike led to degraded performance.", policies: ["PERF‑A1", "CAP‑B2"] }
      );
    }, 500)
  );

/* ───────── Component ───────── */
const EventImpactAccessor: React.FC = () => {
  const [description, setDescription] = useState("");
  const [loading, setLoading]     = useState(false);
  const [error, setError]         = useState<string | null>(null);
  const [data, setData]           = useState<ImpactResponse | null>(null);
  const [history, setHistory]     = useState<HistoryItem[]>([]);
  const textAreaRef               = useRef<HTMLTextAreaElement>(null);

  /* ─── hydrate cache ─── */
  useEffect(() => {
    const cached = localStorage.getItem(LOCAL_RESULT);
    if (cached) setData(JSON.parse(cached));
    const h = localStorage.getItem(LOCAL_HISTORY);
    if (h) setHistory(JSON.parse(h));
  }, []);

  /* ─── history helpers ─── */
  const persistHistory = (h: HistoryItem[]) => {
    setHistory(h);
    localStorage.setItem(LOCAL_HISTORY, JSON.stringify(h));
  };

  const updateHistory = (desc: string) => {
    const updated = [{ id: Date.now(), description: desc }, ...history].slice(0, HISTORY_LIMIT);
    persistHistory(updated);
  };

  /* ─── submit → fake API ─── */
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!description.trim()) return;
    setLoading(true); setError(null); setData(null);

    try {
      const json = await mockApi(description);
      localStorage.setItem(LOCAL_RESULT, JSON.stringify(json));
      setData(json);
      updateHistory(description);
    } catch {
      setError("Unexpected error — please retry.");
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setDescription(""); setData(null); setError(null);
    localStorage.removeItem(LOCAL_RESULT);
  };

  /* ─── drag‑drop helpers ─── */
  const handleDrop = (e: React.DragEvent<HTMLTextAreaElement>) => {
    e.preventDefault();
    const kw = e.dataTransfer.getData("text/plain");
    if (!kw) return;
    const ta = textAreaRef.current;
    if (!ta) return;
    const { selectionStart, selectionEnd } = ta;
    setDescription(
      description.slice(0, selectionStart) + kw + description.slice(selectionEnd)
    );
  };

  const keywords = data ? [...MOCK_KEYWORDS, ...data.policies] : MOCK_KEYWORDS;

  /* ─── render ─── */
  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <h1 className="text-2xl font-semibold mb-6">Event Impact Accessor</h1>

      <div className="flex flex-col md:flex-row gap-6">
        {/* LEFT COLUMN */}
        <div className="flex-1 space-y-6">
          {/* --- form --- */}
          <form
            onSubmit={handleSubmit}
            className="space-y-4 bg-white/70 rounded-xl shadow p-6"
          >
            <label className="block">
              <span className="text-sm font-medium">Event Description</span>
              <textarea
                ref={textAreaRef}
                onDrop={handleDrop}
                onDragOver={(e) => e.preventDefault()}
                className="mt-1 block w-full resize-y rounded-md border-gray-300
                           bg-gray-50 focus:border-indigo-500 focus:ring-indigo-500"
                rows={4}
                placeholder="Describe the event in detail…"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                required
              />
            </label>

            <div className="flex gap-3">
              <button
                type="submit"
                disabled={loading}
                className="rounded-md bg-indigo-600 px-4 py-2 text-white
                           hover:bg-indigo-700 disabled:opacity-60"
              >
                {loading ? "Analyzing…" : "Submit"}
              </button>
              <button
                type="button"
                onClick={handleReset}
                className="rounded-md border border-gray-300 px-4 py-2
                           text-gray-700 hover:bg-gray-100"
              >
                Reset
              </button>
            </div>
          </form>

          {/* --- error & results --- */}
          {error && (
            <p className="rounded bg-red-50 px-4 py-3 text-red-700">{error}</p>
          )}

          {data && (
            <section className="space-y-6">
              <div>
                <h2 className="text-xl font-medium mb-2">Event Summary</h2>
                <p className="whitespace-pre-line rounded bg-gray-50 p-4">
                  {data.summary}
                </p>
              </div>

              <div>
                <h2 className="text-xl font-medium mb-2">Impacted Policies</h2>
                {data.policies.length ? (
                  <ul className="list-disc list-inside rounded bg-gray-50 p-4 space-y-1">
                    {data.policies.map((p) => (
                      <li key={p}>{p}</li>
                    ))}
                  </ul>
                ) : (
                  <p className="rounded bg-gray-50 p-4 italic">No policies impacted.</p>
                )}
              </div>
            </section>
          )}
        </div>

        {/* RIGHT COLUMN – history + keywords */}
        <div className="w-full md:w-80 flex flex-col gap-4">
          <HistoryList
            items={history}
            onSelect={(desc) => setDescription(desc)}
            onClear={() => persistHistory([])}
          />
          <KeywordBank keywords={keywords} />
        </div>
      </div>
    </div>
  );
};

export default EventImpactAccessor;
