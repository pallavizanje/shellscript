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
    <div className="h-screen w-screen bg-gray-100 overflow-hidden">
      <div className="grid grid-cols-2 gap-4 h-full w-full p-4">

        {/* Left Panel */}
        <div className="relative border border-gray-300 rounded-lg pt-10 pb-4 px-6 bg-white h-full overflow-y-auto">
          <div className="absolute -top-4 left-1/2 transform -translate-x-1/2 bg-white px-4 text-gray-700 font-semibold border border-gray-300 rounded-md shadow-sm">
            Left Side
          </div>

          {/* Place form elements here */}
          <AutoSuggest suggestions={suggestions} />
          <div className="mt-4 space-y-4">
            <input type="text" className="w-full border rounded px-3 py-2" placeholder="Additional Input 1" />
            <input type="text" className="w-full border rounded px-3 py-2" placeholder="Additional Input 2" />
            {/* More inputs or table can go here */}
          </div>
        </div>

        {/* Right Panel */}
        <div className="relative border border-gray-300 rounded-lg pt-10 pb-4 px-6 bg-white h-full overflow-y-auto">
          <div className="absolute -top-4 left-1/2 transform -translate-x-1/2 bg-white px-4 text-gray-700 font-semibold border border-gray-300 rounded-md shadow-sm">
            Right Side
          </div>

          {/* Content for right panel */}
          <p className="text-gray-500 mb-4">Right content goes here...</p>
          <table className="w-full border border-collapse">
            <thead>
              <tr className="bg-gray-200">
                <th className="border px-3 py-2">Name</th>
                <th className="border px-3 py-2">Value</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="border px-3 py-2">Example 1</td>
                <td className="border px-3 py-2">123</td>
              </tr>
              <tr>
                <td className="border px-3 py-2">Example 2</td>
                <td className="border px-3 py-2">456</td>
              </tr>
              {/* Add more rows as needed */}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default App;
