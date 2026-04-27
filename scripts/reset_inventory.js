/**
 * ReliefHub AI — Inventory Reset Script
 * 
 * Force-resets all inventory items to their original seed values.
 * Also cleans up any auto-generated donation drives.
 * 
 * Usage:
 *   node scripts/reset_inventory.js
 */

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

let appOptions = {};
try {
  const serviceAccount = require("../service-account.json");
  appOptions = { credential: cert(serviceAccount) };
  console.log("Using service-account.json for authentication...");
} catch (e) {
  console.log("No service-account.json found. Using ADC.");
}

initializeApp(appOptions);
const db = getFirestore();

const INVENTORY_ITEMS = [
  // CRITICAL (runway < 7 days) — 2 items
  {
    sku_id: "SKU-001", category_id: "CAT-01", category_name: "Basic Necessities",
    sku_name: "Rice (25kg bags)", unit: "bags",
    current_stock: 30, reserved_stock: 5, reorder_threshold: 50,
    avg_daily_consumption: 5.2, location_in_storehouse: "Aisle A, Shelf 1",
  },
  {
    sku_id: "SKU-002", category_id: "CAT-01", category_name: "Basic Necessities",
    sku_name: "Drinking Water (20L)", unit: "cans",
    current_stock: 40, reserved_stock: 10, reorder_threshold: 60,
    avg_daily_consumption: 6.0, location_in_storehouse: "Aisle A, Shelf 3",
  },
  // WARNING (runway 7–14 days) — 2 items
  {
    sku_id: "SKU-003", category_id: "CAT-02", category_name: "Medical Supplies",
    sku_name: "First Aid Kits", unit: "kits",
    current_stock: 120, reserved_stock: 10, reorder_threshold: 40,
    avg_daily_consumption: 8.5, location_in_storehouse: "Aisle B, Shelf 2",
  },
  {
    sku_id: "SKU-004", category_id: "CAT-02", category_name: "Medical Supplies",
    sku_name: "Paracetamol Strips", unit: "strips",
    current_stock: 200, reserved_stock: 20, reorder_threshold: 80,
    avg_daily_consumption: 15.0, location_in_storehouse: "Aisle B, Shelf 4",
  },
  // MONITOR (runway 15–30 days) — 2 items
  {
    sku_id: "SKU-005", category_id: "CAT-03", category_name: "Clothing",
    sku_name: "Blankets", unit: "pieces",
    current_stock: 300, reserved_stock: 20, reorder_threshold: 100,
    avg_daily_consumption: 12.0, location_in_storehouse: "Aisle C, Shelf 1",
  },
  {
    sku_id: "SKU-006", category_id: "CAT-04", category_name: "Hygiene Products",
    sku_name: "Soap Bars", unit: "bars",
    current_stock: 500, reserved_stock: 30, reorder_threshold: 150,
    avg_daily_consumption: 20.0, location_in_storehouse: "Aisle D, Shelf 2",
  },
  // SAFE (runway > 30 days) — 4 items
  {
    sku_id: "SKU-007", category_id: "CAT-03", category_name: "Clothing",
    sku_name: "T-Shirts (Assorted)", unit: "pieces",
    current_stock: 800, reserved_stock: 50, reorder_threshold: 100,
    avg_daily_consumption: 10.0, location_in_storehouse: "Aisle C, Shelf 3",
  },
  {
    sku_id: "SKU-008", category_id: "CAT-05", category_name: "Education Supplies",
    sku_name: "Notebooks", unit: "pieces",
    current_stock: 1200, reserved_stock: 100, reorder_threshold: 200,
    avg_daily_consumption: 15.0, location_in_storehouse: "Aisle E, Shelf 1",
  },
  {
    sku_id: "SKU-009", category_id: "CAT-04", category_name: "Hygiene Products",
    sku_name: "Toothbrush Packs", unit: "packs",
    current_stock: 600, reserved_stock: 40, reorder_threshold: 100,
    avg_daily_consumption: 8.0, location_in_storehouse: "Aisle D, Shelf 4",
  },
  {
    sku_id: "SKU-010", category_id: "CAT-05", category_name: "Education Supplies",
    sku_name: "Pencil Boxes", unit: "boxes",
    current_stock: 900, reserved_stock: 50, reorder_threshold: 150,
    avg_daily_consumption: 5.0, location_in_storehouse: "Aisle E, Shelf 3",
  },
];

async function resetInventory() {
  console.log("Resetting all 10 inventory items to seed values...\n");

  for (const item of INVENTORY_ITEMS) {
    const daysOfRunway = item.avg_daily_consumption > 0
      ? (item.current_stock - item.reserved_stock) / item.avg_daily_consumption
      : 999.0;

    let status = "SAFE";
    if (daysOfRunway < 7) status = "CRITICAL";
    else if (daysOfRunway < 15) status = "WARNING";
    else if (daysOfRunway <= 30) status = "MONITOR";

    await db.collection("inventory").doc(item.sku_id).set({
      ...item,
      days_of_runway: parseFloat(daysOfRunway.toFixed(1)),
      last_updated: Timestamp.now(),
      last_updated_by: "RESET_SCRIPT",
    });

    console.log(`  ✓ ${item.sku_id} ${item.sku_name} → ${status} (${daysOfRunway.toFixed(1)}d)`);
  }

  console.log("\n✅ All inventory items reset.\n");
}

async function cleanupAutoDrives() {
  console.log("Cleaning up auto-generated drives (DRIVE-1xxx...)...");
  
  const snapshot = await db.collection("donation_drives").get();
  let deleted = 0;
  
  for (const doc of snapshot.docs) {
    // Only delete auto-generated drives (not seeded ones like DRIVE-001/002/003)
    if (doc.id.startsWith("DRIVE-1")) {
      await doc.ref.delete();
      console.log(`  🗑️  Deleted ${doc.id}`);
      deleted++;
    }
  }
  
  if (deleted === 0) {
    console.log("  No auto-generated drives found.");
  }
  console.log("✅ Drive cleanup done.\n");
}

async function main() {
  console.log("═══════════════════════════════════════════════");
  console.log("  ReliefHub AI — Inventory Reset");
  console.log("═══════════════════════════════════════════════\n");

  await resetInventory();
  await cleanupAutoDrives();

  console.log("═══════════════════════════════════════════════");
  console.log("  Reset complete! All items back to original values.");
  console.log("═══════════════════════════════════════════════");
  process.exit(0);
}

main().catch((err) => {
  console.error("❌ Reset failed:", err);
  process.exit(1);
});
