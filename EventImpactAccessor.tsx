import React, { useState, useEffect, useRef } from "react";
import HistoryList, { HistoryItem } from "@/components/HistoryList";
import KeywordBank from "@/components/KeywordBank";

type ImpactResponse = {
  summary: string;
  policies: string[];
};

const LOCAL_RESULT = "eventImpact";
const LOCAL_HISTORY = "eventImpact_history";
const HISTORY_LIMIT = 20; // keep the last 20 searches

const EventImpactAccessor: React.FC = () => {
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<ImpactResponse | null>(null);
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const textAreaRef = useRef<HTMLTextAreaElement>(null);

  /* ─────── Hydrate result & history on mount ─────── */
  useEffect(() => {
    const cached = localStorage.getItem(LOCAL_RESULT);
    if (cached) {
      try {
        setData(JSON.parse(cached) as ImpactResponse);
      } catch {
        localStorage.removeItem(LOCAL_RESULT);
      }
    }
    const h = localStorage.getItem(LOCAL_HISTORY);
    if (h) {
      try {
        setHistory(JSON.parse(h) as HistoryItem[]);
      } catch {
        localStorage.removeItem(LOCAL_HISTORY);
      }
    }
  }, []);

  /* ─────── Helpers ─────── */
  const persistHistory = (newHistory: HistoryItem[]) => {
    setHistory(newHistory);
    localStorage.setItem(LOCAL_HISTORY, JSON.stringify(newHistory));
  };

  const updateHistory = (desc: string) => {
    const newEntry: HistoryItem = { id: Date.now(), description: desc };
    const updated = [newEntry, ...history]
      .slice(0, HISTORY_LIMIT); // cap size
    persistHistory(updated);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!description.trim()) return;

    setLoading(true);
    setError(null);
    setData(null);

    try {
      const res = await fetch("/api/event-impact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ description }),
      });
      if (!res.ok) throw new Error(`Server responded ${res.status}`);

      const json: ImpactResponse = await res.json();
      localStorage.setItem(LOCAL_RESULT, JSON.stringify(json));
      setData(json);
      updateHistory(description);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Unexpected error — please retry."
      );
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setDescription("");
    setData(null);
    setError(null);
    localStorage.removeItem(LOCAL_RESULT);
  };

  /* ─────── Drag‑and‑drop support for textarea ─────── */
  const handleDrop = (e: React.DragEvent<HTMLTextAreaElement>) => {
    e.preventDefault();
    const kw = e.dataTransfer.getData("text/plain");
    if (!kw) return;
    const ta = textAreaRef.current;
    if (!ta) return;

    const start = ta.selectionStart;
    const end = ta.selectionEnd;
    const newText =
      description.slice(0, start) + kw + description.slice(end);

    setDescription(newText);
  };

  const handleDragOver = (e: React.DragEvent<HTMLTextAreaElement>) =>
    e.preventDefault();

  /* ─────── Render ─────── */
  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <h1 className="text-2xl font-semibold mb-6">Event Impact Accessor</h1>

      <div className="flex flex-col md:flex-row gap-6">
        {/* LEFT COLUMN – form & results */}
        <div className="flex-1 space-y-6">
          <form
            onSubmit={handleSubmit}
            className="space-y-4 bg-white/70 rounded-xl shadow p-6"
          >
            <label className="block">
              <span className="text-sm font-medium text-gray-700">
                Event Description
              </span>
              <textarea
                ref={textAreaRef}
                onDrop={handleDrop}
                onDragOver={handleDragOver}
                className="mt-1 block w-full resize-y rounded-md border-gray-300 bg-gray-50 focus:border-indigo-500 focus:ring-indigo-500"
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
                className="inline-flex items-center justify-center rounded-md bg-indigo-600 px-4 py-2 text-white hover:bg-indigo-700 disabled:opacity-60"
              >
                {loading ? "Analyzing…" : "Submit"}
              </button>

              <button
                type="button"
                onClick={handleReset}
                className="rounded-md border border-gray-300 px-4 py-2 text-gray-700 hover:bg-gray-100"
              >
                Reset
              </button>
            </div>
          </form>

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
                <h2 className="text-xl font-medium mb-2">
                  Impacted Policies
                </h2>
                {data.policies.length ? (
                  <ul className="list-disc list-inside rounded bg-gray-50 p-4 space-y-1">
                    {data.policies.map((p) => (
                      <li key={p}>{p}</li>
                    ))}
                  </ul>
                ) : (
                  <p className="rounded bg-gray-50 p-4 italic">
                    No policies impacted.
                  </p>
                )}
              </div>

              {/* IMPORTANT KEYWORDS */}
              <KeywordBank
                keywords={data.policies.length ? data.policies : []}
              />
            </section>
          )}
        </div>

        {/* RIGHT COLUMN – history */}
        <HistoryList
          items={history}
          onSelect={(desc) => setDescription(desc)}
          onClear={() => persistHistory([])}
        />
      </div>
    </div>
  );
};

export default EventImpactAccessor;
