import React from "react";

interface Props {
  keywords: string[];
}

/**
 * Draggable keyword chips rendered in a fixed‑height, scrollable panel.
 *
 * – Each chip sets its text in `dataTransfer` so it can be dropped into
 *   any textarea that calls `e.dataTransfer.getData("text/plain")`.
 * – The outer container has `h-60` (≈ 15 rem) and `overflow-y-auto`
 *   so a scrollbar appears when there are many keywords.
 */
const KeywordBank: React.FC<Props> = ({ keywords }) => {
  if (!keywords.length) return null;

  return (
    <div className="rounded border border-gray-200 bg-white flex flex-col">
      <h3 className="text-lg font-medium p-3 border-b border-gray-100">
        Keywords
      </h3>

      <div className="p-3 h-60 overflow-y-auto flex flex-wrap gap-2">
        {keywords.map((kw) => (
          <span
            key={kw}
            draggable
            onDragStart={(e) => e.dataTransfer.setData("text/plain", kw)}
            className="select-none rounded-full bg-indigo-100 px-3 py-1 text-xs
                       text-indigo-700 cursor-move hover:bg-indigo-200"
          >
            {kw}
          </span>
        ))}
      </div>
    </div>
  );
};

export default KeywordBank;
