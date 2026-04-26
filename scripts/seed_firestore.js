/**
 * ReliefHub AI — Synthetic Data Seeder
 * 
 * Idempotent: checks for document existence before writing.
 * Anchor: Pimpri-Chinchwad, Maharashtra (18.6298, 73.8553)
 * Coverage: 5km radius → 5x5 grid of sectors
 * 
 * Usage:
 *   node scripts/seed_firestore.js
 * 
 * Prerequisites:
 *   - GOOGLE_APPLICATION_CREDENTIALS env var set, OR
 *   - Run from a machine with Firebase Admin SDK access
 *   - npm install firebase-admin
 */

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

// ─── Initialize Firebase Admin ────────────────────────────────────────────
// Uses Application Default Credentials. Set GOOGLE_APPLICATION_CREDENTIALS
// to your service account key JSON, or run on a GCP-authed machine.
initializeApp();
const db = getFirestore();

// ─── Constants from PRD ───────────────────────────────────────────────────
const HUB_LAT = 18.6298;
const HUB_LNG = 73.8553;
const RADIUS_KM = 5;
const CELL_KM = RADIUS_KM / 2.5; // 2km per cell
const LAT_PER_KM = 1 / 110;
const LNG_PER_KM = 1 / (110 * Math.cos(HUB_LAT * Math.PI / 180));

// ─── Locality names for sectors ───────────────────────────────────────────
const LOCALITY_NAMES = {
  A1: "Pimpri Colony",      B1: "Chinchwad East",    C1: "Kasarwadi",
  D1: "Pimpri Sandas",      E1: "Dapodi",            A2: "Nigdi Pradhikaran",
  B2: "Akurdi",             C2: "Thermax Chowk",     D2: "Bhosari MIDC",
  E2: "Dighi",              A3: "Ravet",             B3: "Punawale",
  C3: "Wakad West",         D3: "Pimple Saudagar",   E3: "Pimple Nilakh",
  A4: "Tathawade",          B4: "Hinjewadi Phase 1", C4: "Hinjewadi Phase 2",
  D4: "Wakad East",         E4: "Aundh",             A5: "Baner",
  B5: "Balewadi",           C5: "Sus",               D5: "Pashan",
  E5: "Kothrud",
};

// ─── Zone status distribution: 7 SCARCITY, 8 NEUTRAL, 10 ABUNDANCE ──────
const ZONE_STATUS_MAP = {
  A1: "SCARCITY",  B1: "NEUTRAL",    C1: "ABUNDANCE",
  D1: "SCARCITY",  E1: "NEUTRAL",    A2: "ABUNDANCE",
  B2: "ABUNDANCE", C2: "NEUTRAL",    D2: "SCARCITY",
  E2: "ABUNDANCE", A3: "NEUTRAL",    B3: "ABUNDANCE",
  C3: "ABUNDANCE", D3: "NEUTRAL",    E3: "SCARCITY",
  A4: "ABUNDANCE", B4: "ABUNDANCE",  C4: "NEUTRAL",
  D4: "SCARCITY",  E4: "ABUNDANCE",  A5: "NEUTRAL",
  B5: "ABUNDANCE", C5: "SCARCITY",   D5: "NEUTRAL",
  E5: "SCARCITY",
};

// Risk scores vary by zone status
function riskScoresForZone(zoneStatus) {
  if (zoneStatus === "SCARCITY") {
    return { CAT_01: "HIGH", CAT_02: "MEDIUM", CAT_03: "HIGH", CAT_04: "LOW", CAT_05: "MEDIUM" };
  } else if (zoneStatus === "NEUTRAL") {
    return { CAT_01: "MEDIUM", CAT_02: "LOW", CAT_03: "LOW", CAT_04: "LOW", CAT_05: "MEDIUM" };
  }
  return { CAT_01: "LOW", CAT_02: "LOW", CAT_03: "LOW", CAT_04: "LOW", CAT_05: "LOW" };
}

// ─── Seed Sectors ─────────────────────────────────────────────────────────
async function seedSectors() {
  console.log("Seeding 25 sectors...");
  const batch = db.batch();

  for (let row = 0; row < 5; row++) {
    for (let col = 0; col < 5; col++) {
      const sectorId = String.fromCharCode(65 + col) + (row + 1);
      const ref = db.collection("sectors").doc(sectorId);

      const existing = await ref.get();
      if (existing.exists) {
        console.log(`  ✓ ${sectorId} already exists, skipping.`);
        continue;
      }

      const swLat = HUB_LAT - (RADIUS_KM * LAT_PER_KM) + (row * CELL_KM * LAT_PER_KM);
      const swLng = HUB_LNG - (RADIUS_KM * LNG_PER_KM) + (col * CELL_KM * LNG_PER_KM);
      const neLat = swLat + CELL_KM * LAT_PER_KM;
      const neLng = swLng + CELL_KM * LNG_PER_KM;
      const centerLat = (swLat + neLat) / 2;
      const centerLng = (swLng + neLng) / 2;

      const zoneStatus = ZONE_STATUS_MAP[sectorId];

      batch.set(ref, {
        sector_id: sectorId,
        label: LOCALITY_NAMES[sectorId],
        center_lat: centerLat,
        center_lng: centerLng,
        bounding_box: {
          ne: { lat: neLat, lng: neLng },
          sw: { lat: swLat, lng: swLng },
        },
        zone_status: zoneStatus,
        risk_scores: riskScoresForZone(zoneStatus),
        population_estimate: 5000 + Math.floor(Math.random() * 15000),
        registered_beneficiaries: 200 + Math.floor(Math.random() * 800),
        registered_donors: 50 + Math.floor(Math.random() * 150),
        last_scout_run: Timestamp.now(),
        active_drive_id: null,
      });

      console.log(`  + ${sectorId} (${LOCALITY_NAMES[sectorId]}) → ${zoneStatus}`);
    }
  }

  await batch.commit();
  console.log("✅ Sectors seeded.\n");
}

// ─── Seed Inventory ───────────────────────────────────────────────────────
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

async function seedInventory() {
  console.log("Seeding 10 inventory SKUs...");

  for (const item of INVENTORY_ITEMS) {
    const ref = db.collection("inventory").doc(item.sku_id);
    const existing = await ref.get();
    if (existing.exists) {
      console.log(`  ✓ ${item.sku_id} already exists, skipping.`);
      continue;
    }

    const daysOfRunway = item.avg_daily_consumption > 0
      ? (item.current_stock - item.reserved_stock) / item.avg_daily_consumption
      : 999.0;

    await ref.set({
      ...item,
      days_of_runway: parseFloat(daysOfRunway.toFixed(1)),
      last_updated: Timestamp.now(),
      last_updated_by: "SEED_SCRIPT",
    });

    let status = "SAFE";
    if (daysOfRunway < 7) status = "CRITICAL";
    else if (daysOfRunway < 15) status = "WARNING";
    else if (daysOfRunway <= 30) status = "MONITOR";

    console.log(`  + ${item.sku_id} ${item.sku_name} → ${status} (${daysOfRunway.toFixed(1)}d)`);
  }

  console.log("✅ Inventory seeded.\n");
}

// ─── Seed Donation Drives ─────────────────────────────────────────────────
async function seedDrives() {
  console.log("Seeding 3 active donation drives...");

  const drives = [
    {
      drive_id: "DRIVE-001",
      urgency_mode: "PROACTIVE",
      trigger_sku_id: "SKU-005",
      trigger_category_id: "CAT-03",
      runway_at_creation_days: 23.3,
      target_items: [
        { sku_id: "SKU-005", qty_needed: 200, qty_pledged: 80, qty_received: 30 },
        { sku_id: "SKU-007", qty_needed: 150, qty_pledged: 50, qty_received: 20 },
      ],
      drop_off_point: { name: "NGO Hub Warehouse", lat: HUB_LAT, lng: HUB_LNG },
      drive_window_days: 14,
      status: "ACTIVE",
      gemini_description: "Clothing supplies are trending toward MONITOR levels. Blankets and T-shirts are needed for the upcoming winter season in sectors A1 and D1.",
    },
    {
      drive_id: "DRIVE-002",
      urgency_mode: "PROACTIVE",
      trigger_sku_id: "SKU-006",
      trigger_category_id: "CAT-04",
      runway_at_creation_days: 23.5,
      target_items: [
        { sku_id: "SKU-006", qty_needed: 300, qty_pledged: 200, qty_received: 100 },
        { sku_id: "SKU-009", qty_needed: 100, qty_pledged: 90, qty_received: 60 },
      ],
      drop_off_point: { name: "Akurdi Community Center", lat: 18.6485, lng: 73.8345 },
      drive_window_days: 14,
      status: "ACTIVE",
      gemini_description: "Hygiene product consumption is accelerating in sectors B2 and C2. Soap and toothbrush donations will help maintain adequate supply levels.",
    },
    {
      drive_id: "DRIVE-003",
      urgency_mode: "PROACTIVE",
      trigger_sku_id: "SKU-008",
      trigger_category_id: "CAT-05",
      runway_at_creation_days: 18.0,
      target_items: [
        { sku_id: "SKU-008", qty_needed: 500, qty_pledged: 120, qty_received: 40 },
        { sku_id: "SKU-010", qty_needed: 200, qty_pledged: 30, qty_received: 10 },
      ],
      drop_off_point: { name: "Nigdi School Hall", lat: 18.6520, lng: 73.7720 },
      drive_window_days: 14,
      status: "ACTIVE",
      gemini_description: "Education supply demand is rising with the new school term. Notebooks and pencil boxes are projected to reach WARNING in 10 days without replenishment.",
    },
  ];

  for (const drive of drives) {
    const ref = db.collection("donation_drives").doc(drive.drive_id);
    const existing = await ref.get();
    if (existing.exists) {
      console.log(`  ✓ ${drive.drive_id} already exists, skipping.`);
      continue;
    }

    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + drive.drive_window_days * 24 * 60 * 60 * 1000);

    await ref.set({
      ...drive,
      created_at: Timestamp.fromDate(createdAt),
      expires_at: Timestamp.fromDate(expiresAt),
      fulfilled_at: null,
    });

    console.log(`  + ${drive.drive_id} → ${drive.status} (trigger: ${drive.trigger_sku_id})`);
  }

  console.log("✅ Donation drives seeded.\n");
}

// ─── Seed Users ───────────────────────────────────────────────────────────
async function seedUsers() {
  console.log("Seeding 3 user documents...");

  const users = [
    {
      uid: "admin-001",
      display_name: "Priya Sharma",
      email: "admin@reliefhub.ai",
      role: "admin",
      preferred_categories: [],
      donation_history: [],
      fcm_token: null,
      created_at: Timestamp.now(),
    },
    {
      uid: "staff-001",
      display_name: "Rajesh Kumar",
      email: "staff@reliefhub.ai",
      role: "staff",
      preferred_categories: [],
      donation_history: [],
      fcm_token: null,
      created_at: Timestamp.now(),
    },
    {
      uid: "donor-001",
      display_name: "Anita Desai",
      email: "donor@reliefhub.ai",
      role: "donor",
      preferred_categories: ["CAT-01", "CAT-03"],
      donation_history: ["DRIVE-001"],
      fcm_token: null,
      created_at: Timestamp.now(),
    },
  ];

  for (const user of users) {
    const ref = db.collection("users").doc(user.uid);
    const existing = await ref.get();
    if (existing.exists) {
      console.log(`  ✓ ${user.uid} already exists, skipping.`);
      continue;
    }
    await ref.set(user);
    console.log(`  + ${user.uid} (${user.role}) → ${user.display_name}`);
  }

  console.log("✅ Users seeded.\n");
}

// ─── Link active drives to sectors ────────────────────────────────────────
async function linkDrivesToSectors() {
  console.log("Linking drives to sectors...");
  const links = { A1: "DRIVE-001", B2: "DRIVE-002", A2: "DRIVE-003" };
  for (const [sectorId, driveId] of Object.entries(links)) {
    await db.collection("sectors").doc(sectorId).update({ active_drive_id: driveId });
    console.log(`  + ${sectorId} → ${driveId}`);
  }
  console.log("✅ Drive-sector links set.\n");
}

// ─── Main ─────────────────────────────────────────────────────────────────
async function main() {
  console.log("═══════════════════════════════════════════════");
  console.log("  ReliefHub AI — Firestore Seeder");
  console.log("═══════════════════════════════════════════════\n");

  await seedSectors();
  await seedInventory();
  await seedDrives();
  await seedUsers();
  await linkDrivesToSectors();

  console.log("═══════════════════════════════════════════════");
  console.log("  All seed data written successfully!");
  console.log("═══════════════════════════════════════════════");
  process.exit(0);
}

main().catch((err) => {
  console.error("❌ Seeder failed:", err);
  process.exit(1);
});
