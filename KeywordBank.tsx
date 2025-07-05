import React from "react";

interface Props {
  keywords: string[];
}

/**
 * Renders keywords as draggable chips.
 * When dragged, the keyword’s text can be dropped into any textarea/element
 * that handles `dataTransfer.getData("text/plain")`.
 */
const KeywordBank: React.FC<Props> = ({ keywords }) => {
  if (!keywords.length) return null;

  return (
    <div>
      <h3 className="text-lg font-medium mb-1">Important Keywords</h3>
      <div className="flex flex-wrap gap-2">
        {keywords.map((kw) => (
          <span
            key={kw}
            draggable
            onDragStart={(e) => e.dataTransfer.setData("text/plain", kw)}
            className="select-none rounded-full bg-indigo-100 px-3 py-1 text-xs text-indigo-700 cursor-move hover:bg-indigo-200"
          >
            {kw}
          </span>
        ))}
      </div>
    </div>
  );
};

export default KeywordBank;
