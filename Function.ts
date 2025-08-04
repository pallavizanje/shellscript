function getChangedItems(original: Item[], updated: Item[]): Item[] {
  const updatedMap = new Map(updated.map(item => [item.gpn, item.flag]));
  return original
    .map(item =>
      updatedMap.has(item.gpn)
        ? { gpn: item.gpn, flag: updatedMap.get(item.gpn)! }
        : item
    )
    .filter(item => {
      const originalItem = original.find(o => o.gpn === item.gpn);
      return originalItem?.flag !== item.flag;
    });
}
