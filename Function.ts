
const trueValue = [
  { gpn: 2333, flag: true },
  { gpn: 2334, flag: true },
  { gpn: 2337, flag: true },
  { gpn: 2338, flag: true }
];

const changedItems = [
  { gpn: 2333, flag: true },
  { gpn: 2363, flag: true },
  { gpn: 2345, flag: true }
];

// Convert changedItems to a Set for faster lookup
const changedGpnSet = new Set(changedItems.map(item => item.gpn));

// Mark old items not in changedItems as false
const removedItems = trueValue
  .filter(item => !changedGpnSet.has(item.gpn))
  .map(item => ({ ...item, flag: false }));

// Combine both arrays
const result = [
  ...changedItems,
  ...removedItems
];

console.log(result);
