// src/pages/EventImpactAccessor.tsx
import React, { useState, useEffect, useRef } from "react";
import HistoryList, { HistoryItem } from "@/components/HistoryList";
import KeywordBank from "@/components/KeywordBank";

/* ╭─────────────────────────────────────────╮
   │  Types & constants                      │
   ╰─────────────────────────────────────────╯ */
type ImpactRow = {
  divisionGroup: string;
  divisionFunction: string;
  overallImpact: string;
  region: string;
  nfrTaxonomy: string;
  inherentRiskRating: string;
  changeRequired: string;
  extraaterritoralImpact: string;
  extraerriotriAlImpact: string;
};

type ImpactResponse = {
  summary: string;
  impacts: ImpactRow[];
};

const LOCAL_RESULT  = "eventImpact";
const LOCAL_HISTORY = "eventImpact_history";
const HISTORY_LIMIT = 20;

/* Some starter keywords for drag‑and‑drop */
const MOCK_KEYWORDS = [
  "Downtime",
  "Compliance",
  "Security",
  "Performance",
  "SLA breach",
];

/* ╭─────────────────────────────────────────╮
   │  Mock API (½‑second latency)            │
   ╰─────────────────────────────────────────╯ */
const mockApi = (description: string): Promise<ImpactResponse> =>
  new Promise((resolve) =>
    setTimeout(() => {
      const hash = description.length % 3;
      const impacts: ImpactRow[] =
        hash === 0
          ? [
              {
                divisionGroup: "Ops & Tech",
                divisionFunction: "Data Centre Ops",
                overallImpact: "High",
                region: "Global",
                nfrTaxonomy: "Availability",
                inherentRiskRating: "Severe",
                changeRequired: "BCP review",
                extraaterritoralImpact: "Yes",
                extraerriotriAlImpact: "N/A",
              },
              {
                divisionGroup: "Ops & Tech",
                divisionFunction: "Infrastructure",
                overallImpact: "Medium",
                region: "APAC",
                nfrTaxonomy: "Resilience",
                inherentRiskRating: "High",
                changeRequired: "DR scope update",
                extraaterritoralImpact: "No",
                extraerriotriAlImpact: "N/A",
              },
            ]
          : hash === 1
          ? [
              {
                divisionGroup: "Business Services",
                divisionFunction: "Payments",
                overallImpact: "Low",
                region: "EMEA",
                nfrTaxonomy: "Process Risk",
                inherentRiskRating: "Moderate",
                changeRequired: "Procedure tweak",
                extraaterritoralImpact: "No",
                extraerriotriAlImpact: "N/A",
              },
              {
                divisionGroup: "Business Services",
                divisionFunction: "Settlements",
                overallImpact: "Medium",
                region: "Global",
                nfrTaxonomy: "Timeliness",
                inherentRiskRating: "High",
                changeRequired: "SLA amendment",
                extraaterritoralImpact: "Yes",
                extraerriotriAlImpact: "Possible",
              },
            ]
          : [
              {
                divisionGroup: "Risk & Compliance",
                divisionFunction: "Operational Risk",
                overallImpact: "High",
                region: "Americas",
                nfrTaxonomy: "Regulatory",
                inherentRiskRating: "Severe",
                changeRequired: "Policy update",
                extraaterritoralImpact: "No",
                extraerriotriAlImpact: "N/A",
              },
              {
                divisionGroup: "Risk & Compliance",
                divisionFunction: "Audit",
                overallImpact: "Low",
                region: "Global",
                nfrTaxonomy: "Reporting",
                inherentRiskRating: "Low",
                changeRequired: "No change",
                extraaterritoralImpact: "No",
                extraerriotriAlImpact: "N/A",
              },
            ];

      resolve({
        summary:
          hash === 0
            ? "System outage caused by data‑centre power failure."
            : hash === 1
            ? "Planned maintenance window extended beyond schedule."
            : "Unexpected spike in traffic led to degraded performance.",
        impacts,
      });
    }, 500)
  );

/* ╭─────────────────────────────────────────╮
   │  Component                              │
   ╰─────────────────────────────────────────╯ */
const EventImpactAccessor: React.FC = () => {
  const [description, setDescription] = useState("");
  const [loading, setLoading]         = useState(false);
  const [error, setError]             = useState<string | null>(null);
  const [data, setData]               = useState<ImpactResponse | null>(null);
  const [history, setHistory]         = useState<HistoryItem[]>([]);
  const textAreaRef                   = useRef<HTMLTextAreaElement>(null);

  /* ── hydrate cached result & history ── */
  useEffect(() => {
    const cached = localStorage.getItem(LOCAL_RESULT);
    if (cached) setData(JSON.parse(cached));
    const h = localStorage.getItem(LOCAL_HISTORY);
    if (h) setHistory(JSON.parse(h));
  }, []);

  /* ── history helpers ── */
  const persistHistory = (h: HistoryItem[]) => {
    setHistory(h);
    localStorage.setItem(LOCAL_HISTORY, JSON.stringify(h));
  };

  const updateHistory = (desc: string) => {
    const updated = [{ id: Date.now(), description: desc }, ...history].slice(
      0,
      HISTORY_LIMIT
    );
    persistHistory(updated);
  };

  /* ── submit (→ mock API) ── */
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!description.trim()) return;

    setLoading(true);
    setError(null);
    setData(null);

    try {
      const json = await mockApi(description);
      localStorage.setItem(LOCAL_RESULT, JSON.stringify(json));
      setData(json);
      updateHistory(description);
    } catch {
      setError("Unexpected error — please retry.");
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

  /* ── drag‑and‑drop keyword → textarea ── */
  const handleDrop = (e: React.DragEvent<HTMLTextAreaElement>) => {
    e.preventDefault();
    const kw = e.dataTransfer.getData("text/plain");
    if (!kw) return;

    const ta = textAreaRef.current;
    if (!ta) return;

    const { selectionStart, selectionEnd } = ta;
    setDescription(
      description.slice(0, selectionStart) +
        kw +
        description.slice(selectionEnd)
    );
  };

  /* ── combine mock keywords with any division/functions for variety ── */
  const keywords = data
    ? [
        ...MOCK_KEYWORDS,
        ...data.impacts.map((i) => i.divisionFunction),
        ...data.impacts.map((i) => i.divisionGroup),
      ]
    : MOCK_KEYWORDS;

  /* ── render ── */
  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <h1 className="text-2xl font-semibold mb-6">Event Impact Accessor</h1>

      <div className="flex flex-col md:flex-row gap-6">
        {/* ╭──────── Left column ────────╮ */}
        <div className="flex-1 space-y-6">
          {/* form */}
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

          {/* error / results */}
          {error && (
            <p className="rounded bg-red-50 px-4 py-3 text-red-700">{error}</p>
          )}

          {data && (
            <section className="space-y-6">
              {/* summary */}
              <div>
                <h2 className="text-xl font-medium mb-2">Event Summary</h2>
                <p className="whitespace-pre-line rounded bg-gray-50 p-4">
                  {data.summary}
                </p>
              </div>

              {/* NEW TABLE */}
              <div>
                <h2 className="text-xl font-medium mb-2">
                  Impacted Policies&nbsp;/ Controls
                </h2>
                <div className="overflow-x-auto rounded border border-gray-200">
                  <table className="min-w-full divide-y divide-gray-200 text-sm">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-4 py-2 text-left font-semibold">
                          Division / Functions Group
                        </th>
                        <th className="px-4 py-2 text-left font-semibold">
                          Division Function
                        </th>
                        <th className="px-4 py-2 text-left font-semibold">
                          Overall Impact
                        </th>
                        <th className="px-4 py-2 text-left font-semibold">
                          Region
                        </th>
                        <th className="px-4 py-2 text-left font-semibold">
                          NFR Taxonomy
                        </th>
                        <th className="px-4 py-2 text-left font-semibold">
                          Inherent Risk Rating
                        </th>
                        <th className="px-4 py-2 text-left font-semibold">
                          Change Required
                        </th>
                        <th className="px-4 py-2 text-left font-semibold">
                          Extraaterritoral Impact
                        </th>
                        <th className="px-4 py-2 text-left font-semibold">
                          Extraerriotri&nbsp;al Impact
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                      {data.impacts.map((row, idx) => (
                        <tr key={idx}>
                          <td className="px-4 py-2 whitespace-nowrap">
                            {row.divisionGroup}
                          </td>
                          <td className="px-4 py-2 whitespace-nowrap">
                            {row.divisionFunction}
                          </td>
                          <td className="px-4 py-2">{row.overallImpact}</td>
                          <td className="px-4 py-2">{row.region}</td>
                          <td className="px-4 py-2">{row.nfrTaxonomy}</td>
                          <td className="px-4 py-2">
                            {row.inherentRiskRating}
                          </td>
                          <td className="px-4 py-2">{row.changeRequired}</td>
                          <td className="px-4 py-2">
                            {row.extraaterritoralImpact}
                          </td>
                          <td className="px-4 py-2">
                            {row.extraerriotriAlImpact}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </section>
          )}
        </div>

        {/* ╭──────── Right column ───────╮ */}
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
