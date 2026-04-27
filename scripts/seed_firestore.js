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
// Uses service-account.json if present in the root directory, 
// otherwise falls back to Application Default Credentials.
let appOptions = {};
try {
  const serviceAccount = require("../service-account.json");
  appOptions = { credential: cert(serviceAccount) };
  console.log("Using service-account.json for authentication...");
} catch (e) {
  console.log("No service-account.json found. Falling back to Application Default Credentials.");
}

initializeApp(appOptions);
const db = getFirestore();

// ─── Constants from PRD ───────────────────────────────────────────────────
const HUB_LAT = 18.6298;
const HUB_LNG = 73.8553;
const LAT_PER_KM = 1 / 110;
const LNG_PER_KM = 1 / (110 * Math.cos(HUB_LAT * Math.PI / 180));

// ─── Locality names & rough coordinates for 25 sectors ─────────────────────
const LOCALITIES = {
  A1: { name: "Pimpri Colony", lat: 18.627, lng: 73.800 },
  B1: { name: "Chinchwad East", lat: 18.635, lng: 73.790 },
  C1: { name: "Kasarwadi", lat: 18.605, lng: 73.820 },
  D1: { name: "Pimpri Sandas", lat: 18.610, lng: 73.810 },
  E1: { name: "Dapodi", lat: 18.580, lng: 73.835 },
  A2: { name: "Nigdi Pradhikaran", lat: 18.650, lng: 73.765 },
  B2: { name: "Akurdi", lat: 18.645, lng: 73.780 },
  C2: { name: "Thermax Chowk", lat: 18.660, lng: 73.790 },
  D2: { name: "Bhosari MIDC", lat: 18.625, lng: 73.835 },
  E2: { name: "Dighi", lat: 18.610, lng: 73.865 },
  A3: { name: "Ravet", lat: 18.640, lng: 73.740 },
  B3: { name: "Punawale", lat: 18.620, lng: 73.745 },
  C3: { name: "Wakad West", lat: 18.595, lng: 73.760 },
  D3: { name: "Pimple Saudagar", lat: 18.595, lng: 73.790 },
  E3: { name: "Pimple Nilakh", lat: 18.580, lng: 73.780 },
  A4: { name: "Tathawade", lat: 18.610, lng: 73.750 },
  B4: { name: "Hinjewadi Phase 1", lat: 18.580, lng: 73.740 },
  C4: { name: "Hinjewadi Phase 2", lat: 18.585, lng: 73.710 },
  D4: { name: "Wakad East", lat: 18.600, lng: 73.775 },
  E4: { name: "Aundh", lat: 18.560, lng: 73.805 },
  A5: { name: "Baner", lat: 18.560, lng: 73.780 },
  B5: { name: "Balewadi", lat: 18.575, lng: 73.770 },
  C5: { name: "Sus", lat: 18.545, lng: 73.750 },
  D5: { name: "Pashan", lat: 18.540, lng: 73.790 },
  E5: { name: "Kothrud", lat: 18.505, lng: 73.810 },
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
// Generates an organic polygon around a center point (low vertex count for latency)
function generateOrganicPolygon(centerLat, centerLng, baseRadiusKm = 1.2) {
  const points = [];
  const numPoints = 6; // Low number of vertices to keep map render very fast
  
  for (let i = 0; i < numPoints; i++) {
    const angleRad = (i / numPoints) * 2 * Math.PI;
    // Add jitter to radius (+/- 30%) to make it look organic/irregular
    const jitter = 0.7 + Math.random() * 0.6; 
    const rKm = baseRadiusKm * jitter;
    
    points.push({
      lat: centerLat + (rKm * LAT_PER_KM) * Math.sin(angleRad),
      lng: centerLng + (rKm * LNG_PER_KM) * Math.cos(angleRad)
    });
  }
  return points;
}

async function seedSectors() {
  console.log("Seeding 25 organic sectors...");
  const batch = db.batch();

  for (const [sectorId, data] of Object.entries(LOCALITIES)) {
    const ref = db.collection("sectors").doc(sectorId);

    const existing = await ref.get();
    if (existing.exists) {
      console.log(`  ✓ ${sectorId} already exists, skipping.`);
      continue;
    }

    const zoneStatus = ZONE_STATUS_MAP[sectorId];
    // Organic polygon generation
    const polygonPoints = generateOrganicPolygon(data.lat, data.lng, 1.4); // ~1.4km radius

    batch.set(ref, {
      sector_id: sectorId,
      label: data.name,
      center_lat: data.lat,
      center_lng: data.lng,
      polygon_points: polygonPoints,
      zone_status: zoneStatus,
      risk_scores: riskScoresForZone(zoneStatus),
      population_estimate: 5000 + Math.floor(Math.random() * 15000),
      registered_beneficiaries: 200 + Math.floor(Math.random() * 800),
      registered_donors: 50 + Math.floor(Math.random() * 150),
      last_scout_run: Timestamp.now(),
      active_drive_id: null,
    });

    console.log(`  + ${sectorId} (${data.name}) → ${zoneStatus}`);
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
