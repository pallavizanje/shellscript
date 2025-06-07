import React, { useState, useEffect } from "react";

type EntityInfo = {
  dataOwningEntity: string;
  description: string;
  entityDivision: string;
};

type AutoSuggestProps = {
  suggestions: EntityInfo[];
  onSelect: (value: EntityInfo) => void;
};

const AutoSuggest: React.FC<AutoSuggestProps> = ({ suggestions, onSelect }) => {
  const [input, setInput] = useState("");
  const [filteredSuggestions, setFilteredSuggestions] = useState<EntityInfo[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);

  useEffect(() => {
    if (input.trim() === "") {
      setFilteredSuggestions([]);
    } else {
      const filtered = suggestions.filter((s) =>
        s.dataOwningEntity.toLowerCase().includes(input.toLowerCase())
      );
      setFilteredSuggestions(filtered);
    }
  }, [input, suggestions]);

  const handleSelect = (item: EntityInfo) => {
    setInput(item.dataOwningEntity);
    setShowSuggestions(false);
    onSelect(item);
  };

  return (
    <div className="relative w-full">
      <input
        type="text"
        className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
        placeholder="Search by Data Owning Entity..."
        value={input}
        onChange={(e) => setInput(e.target.value)}
        onFocus={() => setShowSuggestions(true)}
        onBlur={() => setTimeout(() => setShowSuggestions(false), 150)}
      />
      {showSuggestions && filteredSuggestions.length > 0 && (
        <ul className="absolute z-10 w-full bg-white border border-gray-200 rounded-md mt-1 shadow-md max-h-60 overflow-auto">
          {filteredSuggestions.map((item, index) => (
            <li
              key={index}
              onClick={() => handleSelect(item)}
              className="px-4 py-2 hover:bg-blue-100 cursor-pointer"
            >
              {item.dataOwningEntity}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

export default AutoSuggest;



import React, { useState } from "react";
import AutoSuggest from "./components/AutoSuggest";

type EntityInfo = {
  dataOwningEntity: string;
  description: string;
  entityDivision: string;
};

const suggestions: EntityInfo[] = [
  { dataOwningEntity: "Finance", description: "Handles financial ops", entityDivision: "North Division" },
  { dataOwningEntity: "HR", description: "Manages HR policies", entityDivision: "East Division" },
  { dataOwningEntity: "IT", description: "Tech infrastructure", entityDivision: "West Division" },
  { dataOwningEntity: "Marketing", description: "Campaign management", entityDivision: "South Division" },
];

const App: React.FC = () => {
  const [selectedItems, setSelectedItems] = useState<EntityInfo[]>([]);

  const handleItemSelect = (item: EntityInfo) => {
    const alreadyExists = selectedItems.some(
      (s) => s.dataOwningEntity === item.dataOwningEntity
    );
    if (!alreadyExists) {
      setSelectedItems((prev) => [...prev, item]);
    }
  };

  return (
    <div className="h-screen w-screen bg-gray-100 overflow-hidden">
      <div className="grid grid-cols-2 gap-4 h-full w-full p-4">

        {/* Left Panel */}
        <div className="relative border border-gray-300 rounded-lg pt-10 pb-4 px-6 bg-white h-full overflow-y-auto">
          <div className="absolute -top-4 left-1/2 transform -translate-x-1/2 bg-white px-4 text-gray-700 font-semibold border border-gray-300 rounded-md shadow-sm">
            Left Side
          </div>

          <AutoSuggest suggestions={suggestions} onSelect={handleItemSelect} />

          {/* Table */}
          {selectedItems.length > 0 && (
            <table className="w-full mt-6 border border-collapse">
              <thead>
                <tr className="bg-gray-100">
                  <th className="border px-3 py-2 text-left">Data Owning Entity</th>
                  <th className="border px-3 py-2 text-left">Description</th>
                  <th className="border px-3 py-2 text-left">Entity Division</th>
                </tr>
              </thead>
              <tbody>
                {selectedItems.map((item, index) => (
                  <tr key={index}>
                    <td className="border px-3 py-2">{item.dataOwningEntity}</td>
                    <td className="border px-3 py-2">{item.description}</td>
                    <td className="border px-3 py-2">{item.entityDivision}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* Right Panel */}
        <div className="relative border border-gray-300 rounded-lg pt-10 pb-4 px-6 bg-white h-full overflow-y-auto">
          <div className="absolute -top-4 left-1/2 transform -translate-x-1/2 bg-white px-4 text-gray-700 font-semibold border border-gray-300 rounded-md shadow-sm">
            Right Side
          </div>

          <p className="text-gray-500">Right content goes here...</p>
        </div>
      </div>
    </div>
  );
};

export default App;
