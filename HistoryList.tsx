import React from "react";

export interface HistoryItem {
  id: number;
  description: string;
}

interface Props {
  items: HistoryItem[];
  onSelect: (description: string) => void;
  onClear: () => void;
}

const HistoryList: React.FC<Props> = ({ items, onSelect, onClear }) => {
  return (
    <aside className="w-full md:w-80 flex flex-col">
      <div className="flex items-center justify-between mb-2">
        <h2 className="text-lg font-medium">Search History</h2>
        {items.length ? (
          <button
            onClick={onClear}
            className="text-xs text-indigo-600 hover:underline"
          >
            Clear
          </button>
        ) : null}
      </div>

      {items.length ? (
        <ul className="flex-1 overflow-auto rounded border border-gray-200 bg-white">
          {items.map((h) => (
            <li
              key={h.id}
              className="border-b border-gray-100 p-3 hover:bg-gray-50 cursor-pointer text-sm"
              onClick={() => onSelect(h.description)}
            >
              {h.description.slice(0, 80)}
              {h.description.length > 80 ? "…" : ""}
            </li>
          ))}
        </ul>
      ) : (
        <p className="text-sm italic text-gray-500">
          No searches yet – submit one!
        </p>
      )}
    </aside>
  );
};

export default HistoryList;
