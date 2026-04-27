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

const scoutFunctions = require("./scout");
const ledgerFunctions = require("./ledger");
const replenisherFunctions = require("./replenisher");

// Scout exports
exports.runScoutAgent = scoutFunctions.runScoutAgent;
exports.manualScoutTrigger = scoutFunctions.manualScoutTrigger;
exports.updateZoneStatus = scoutFunctions.updateZoneStatus;

// Ledger exports
exports.recalcRunway = ledgerFunctions.recalcRunway;
exports.rollingAvgConsumption = ledgerFunctions.rollingAvgConsumption;

// Replenisher exports
exports.expireDonationDrive = replenisherFunctions.expireDonationDrive;
exports.checkRunwayAndCreateDrive = replenisherFunctions.checkRunwayAndCreateDrive;
