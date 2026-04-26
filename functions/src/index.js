// ReliefHub AI — Cloud Functions placeholder
// Actual implementations are in src/ subdirectories.
// This file will be populated in Phase 3.

// Function names (PRD-mandated):
// 1. runScoutAgent         — scheduled every 6 hours
// 2. manualScoutTrigger    — onCall, admin only
// 3. updateZoneStatus      — onDocumentWritten (sectors)
// 4. recalcRunway          — onDocumentWritten (inventory)
// 5. rollingAvgConsumption  — scheduled every 24 hours
// 6. expireDonationDrive    — scheduled every 24 hours

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");

// Exports will be added as each function is implemented in Phase 3-4.
