import React, { useState } from "react";

interface Option {
  label: string;
  value: string;
}

interface SearchSelectProps {
  options: Option[];
  placeholder?: string;
  onSelect: (option: Option) => void;
  className?: string;
  defaultValue?: Option | null;
}

function classNames(...classes: (string | false | null | undefined)[]) {
  return classes.filter(Boolean).join(" ");
}

export default function SearchSelect({
  options,
  placeholder = "Search…",
  onSelect,
  className,
  defaultValue = null,
}: SearchSelectProps) {
  const [query, setQuery] = useState<string>(defaultValue?.label ?? "");
  const [selected, setSelected] = useState<Option | null>(defaultValue);

  const filteredOptions = options.filter((option) =>
    option.label.toLowerCase().includes(query.toLowerCase())
  );

  const handleSelect = (option: Option) => {
    setSelected(option);
    setQuery(option.label);
    onSelect(option);
  };

  return (
    <div className={classNames("w-full", className)}>
      <input
        type="text"
        value={query}
        placeholder={placeholder}
        onChange={(e) => setQuery(e.target.value)}
        className="w-full rounded-2xl border border-gray-300 px-4 py-2 text-base shadow-sm focus:border-indigo-500 focus:outline-none"
      />

      <ul className="mt-2 max-h-60 w-full overflow-auto rounded-2xl bg-white py-1 shadow-lg border border-gray-200">
        {filteredOptions.length === 0 ? (
          <li className="px-4 py-2 text-sm text-gray-500">No results found</li>
        ) : (
          filteredOptions.map((option) => (
            <li
              key={option.value}
              onClick={() => handleSelect(option)}
              className={classNames(
                "cursor-pointer px-4 py-2 text-base hover:bg-indigo-50",
                selected?.value === option.value && "bg-indigo-100"
              )}
            >
              {option.label}
            </li>
          ))
        )}
      </ul>
    </div>
  );
}
