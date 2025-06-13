import React, { useEffect, useRef, useState } from "react";

/**
 * A searchable, single‑select dropdown component built with React, TypeScript and Tailwind CSS.
 *
 * Example:
 * ```tsx
 * const colours = [
 *   { label: "Red", value: "red" },
 *   { label: "Green", value: "green" },
 *   { label: "Blue", value: "blue" }
 * ];
 *
 * function App() {
 *   return (
 *     <div className="max-w-sm p-4">
 *       <SearchSelect
 *         options={colours}
 *         placeholder="Choose a colour…"
 *         onSelect={(option) => console.log(option)}
 *       />
 *     </div>
 *   );
 * }
 * ```
 */

interface Option {
  label: string;
  value: string;
}

interface SearchSelectProps {
  /** The list of options to search & select from. */
  options: Option[];
  /** Optional placeholder text for the input. */
  placeholder?: string;
  /** Callback fired when the user selects an option. */
  onSelect: (option: Option) => void;
  /** Extra Tailwind classes for the root element. */
  className?: string;
  /** Pre‑selected value. */
  defaultValue?: Option | null;
}

function classNames(
  ...classes: Array<string | false | null | undefined>
): string {
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
  const [open, setOpen] = useState(false);
  const [selected, setSelected] = useState<Option | null>(defaultValue);
  const containerRef = useRef<HTMLDivElement>(null);

  const filtered = query
    ? options.filter((o) =>
        o.label.toLowerCase().includes(query.toLowerCase())
      )
    : options;

  // Close dropdown on outside click
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
      ) {
        setOpen(false);
      }
    }

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  function handleSelect(option: Option) {
    setSelected(option);
    setQuery(option.label);
    setOpen(false);
    onSelect(option);
  }

  return (
    <div
      ref={containerRef}
      className={classNames("relative w-full", className)}
    >
      <input
        type="text"
        value={query}
        placeholder={placeholder}
        onChange={(e) => {
          setQuery(e.target.value);
          setOpen(true);
        }}
        onFocus={() => setOpen(true)}
        className="w-full rounded-2xl border border-gray-300 px-4 py-2 text-base shadow-sm focus:border-indigo-500 focus:outline-none"
      />

      {open && (
        <ul className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-2xl bg-white py-1 shadow-lg">
          {filtered.length === 0 && (
            <li className="px-4 py-2 text-sm text-gray-500">No results found</li>
          )}

          {filtered.map((option) => (
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
          ))}
        </ul>
      )}
    </div>
  );
}
