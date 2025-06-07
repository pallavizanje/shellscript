import React from "react";
import AutoSuggest from "./components/AutoSuggest";

const suggestions = [
  "Apple",
  "Banana",
  "Cherry",
  "Date",
  "Elderberry",
  "Fig",
  "Grapes",
  "Honeydew",
];

const App: React.FC = () => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 p-4">
      <div className="grid grid-cols-2 gap-4 w-full max-w-5xl">

        {/* Left Panel */}
        <div className="relative border border-gray-300 rounded-lg p-6 pt-10 bg-white">
          <div className="absolute -top-4 left-1/2 transform -translate-x-1/2 bg-white px-4 text-gray-700 font-semibold border border-gray-300 rounded-md shadow-sm">
            Left Side
          </div>
          <AutoSuggest suggestions={suggestions} />
        </div>

        {/* Right Panel */}
        <div className="relative border border-gray-300 rounded-lg p-6 pt-10 bg-white">
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
