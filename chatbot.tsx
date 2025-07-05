// src/pages/EventImpactAccessor.tsx
import React, { useState } from "react";

type ImpactResponse = {
  summary: string;
  policies: string[];
};

const EventImpactAccessor: React.FC = () => {
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<ImpactResponse | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!description.trim()) return;

    setLoading(true);
    setError(null);
    setData(null);

    try {
      // 🔁  Replace `/api/event-impact` with your real endpoint
      const res = await fetch("/api/event-impact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ description }),
      });

      if (!res.ok) {
        throw new Error(`Server responded ${res.status}`);
      }

      const json: ImpactResponse = await res.json();
      setData(json);
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
  };

  return (
    <div className="mx-auto max-w-3xl px-4 py-8">
      <h1 className="text-2xl font-semibold mb-6">
        Event Impact Accessor
      </h1>

      <form
        onSubmit={handleSubmit}
        className="space-y-4 bg-white/70 rounded-xl shadow p-6"
      >
        <label className="block">
          <span className="text-sm font-medium text-gray-700">
            Event Description
          </span>
          <textarea
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

      {/* RESULTS */}
      {error && (
        <p className="mt-6 rounded bg-red-50 px-4 py-3 text-red-700">
          {error}
        </p>
      )}

      {data && (
        <section className="mt-8 space-y-6">
          <div>
            <h2 className="text-xl font-medium text-gray-800 mb-2">
              Event Summary
            </h2>
            <p className="whitespace-pre-line rounded bg-gray-50 p-4">
              {data.summary}
            </p>
          </div>

          <div>
            <h2 className="text-xl font-medium text-gray-800 mb-2">
              Impacted Policies
            </h2>
            {data.policies.length ? (
              <ul className="list-inside list-disc space-y-1 rounded bg-gray-50 p-4">
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
        </section>
      )}
    </div>
  );
};

export default EventImpactAccessor;
