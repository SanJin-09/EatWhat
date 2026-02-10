export type StoreFloorOverride = {
  campusCode: string;
  storeName?: string;
  area?: string;
  canteenName: string;
  floorOrder: number;
  floorLabel: string;
};

// 可按需要添加人工覆盖项。命中优先级：campusCode + storeName + area -> campusCode + storeName -> campusCode + area。
export const storeFloorOverrides: StoreFloorOverride[] = [];

function normalize(value: string): string {
  return value.trim().replace(/\s+/g, '');
}

export function findStoreFloorOverride(input: {
  campusCode: string;
  storeName: string;
  area: string;
}): StoreFloorOverride | undefined {
  const campusCode = input.campusCode.trim();
  const storeName = normalize(input.storeName);
  const area = normalize(input.area);

  const exact = storeFloorOverrides.find((item) => {
    if (item.campusCode.trim() !== campusCode) {
      return false;
    }

    const itemStoreName = item.storeName ? normalize(item.storeName) : null;
    const itemArea = item.area ? normalize(item.area) : null;

    return itemStoreName === storeName && itemArea === area;
  });

  if (exact) {
    return exact;
  }

  const byStoreName = storeFloorOverrides.find((item) => {
    if (item.campusCode.trim() !== campusCode || !item.storeName || item.area) {
      return false;
    }
    return normalize(item.storeName) === storeName;
  });

  if (byStoreName) {
    return byStoreName;
  }

  return storeFloorOverrides.find((item) => {
    if (item.campusCode.trim() !== campusCode || !item.area || item.storeName) {
      return false;
    }
    return normalize(item.area) === area;
  });
}
