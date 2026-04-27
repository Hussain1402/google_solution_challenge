const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore } = require("firebase-admin/firestore");
const { sendAdminFCM } = require("../notifications");
const { createDonationDrive } = require("../replenisher");

// Helper to check if an active drive exists for a given SKU
async function hasActiveDriveForSku(db, skuId) {
  const snapshot = await db.collection("donation_drives")
    .where("status", "==", "ACTIVE")
    .get();
  
  let found = false;
  snapshot.forEach(doc => {
    if (doc.data().trigger_sku_id === skuId) found = true;
  });
  return found;
}

// ----------------------------------------------------------------------
// 4. Runway recalculator — fires on every inventory write
// ----------------------------------------------------------------------
exports.recalcRunway = onDocumentWritten("inventory/{skuId}", async (event) => {
  if (!event.data.after.exists) return null; // Document deleted
  
  const db = getFirestore();
  const skuData = event.data.after.data();
  const beforeData = event.data.before.exists ? event.data.before.data() : null;

  const currentStock = skuData.current_stock || 0;
  const reservedStock = skuData.reserved_stock || 0;
  const avgDailyConsumption = skuData.avg_daily_consumption || 0;

  // Calculate new runway
  let newRunway = 999.0;
  if (avgDailyConsumption > 0) {
    newRunway = (currentStock - reservedStock) / avgDailyConsumption;
  }

  // Prevent infinite loop by checking if runway actually changed
  if (beforeData && Math.abs((beforeData.days_of_runway || 999.0) - newRunway) < 0.01) {
    return null;
  }

  // Write new runway back to the document
  await event.data.after.ref.update({ days_of_runway: newRunway });
  console.log(`Updated runway for ${skuData.sku_id} to ${newRunway.toFixed(2)} days.`);

  // Evaluate Two-Mode Response Logic
  const wasCritical = beforeData ? (beforeData.days_of_runway < 7) : false;
  const isCritical = newRunway < 7;
  
  if (isCritical && !wasCritical) {
    // Escalate to CRITICAL -> send Admin FCM Alert
    await sendAdminFCM(
      "CRITICAL SCARCITY ALERT",
      `${skuData.sku_name} has dropped below 7 days of runway! Immediate dispatch required.`
    );
  } else if (newRunway >= 7 && newRunway < 30) {
    // WARNING (7-14) or MONITOR (15-30)
    // Check if we need to create a proactive drive
    const wasMonitorOrWarning = beforeData ? (beforeData.days_of_runway >= 7 && beforeData.days_of_runway < 30) : false;
    
    // Create a drive if it just entered this state, AND no active drive exists
    if (!wasMonitorOrWarning) {
      const activeDriveExists = await hasActiveDriveForSku(db, skuData.sku_id);
      if (!activeDriveExists) {
        console.log(`Runway for ${skuData.sku_id} hit ${newRunway.toFixed(1)} days. Creating proactive drive.`);
        
        // Pass the updated skuData down to createDonationDrive
        const updatedSkuData = { ...skuData, days_of_runway: newRunway };
        await createDonationDrive(updatedSkuData);
      }
    }
  }

  return null;
});

// ----------------------------------------------------------------------
// 5. Rolling average — nightly scheduled function
// ----------------------------------------------------------------------
exports.rollingAvgConsumption = onSchedule("every 24 hours", async (event) => {
  const db = getFirestore();
  const now = new Date();
  const fourteenDaysAgo = new Date(now.getTime() - (14 * 24 * 60 * 60 * 1000));

  try {
    const logsSnapshot = await db.collection("inventory_log")
      .where("event_type", "==", "STOCK_OUT")
      .where("timestamp", ">=", fourteenDaysAgo)
      .get();

    // Group out-quantities by SKU
    const skuTotals = {};
    logsSnapshot.forEach(doc => {
      const data = doc.data();
      const skuId = data.sku_id;
      // absolute value of quantity_delta just in case it's stored as negative
      const qty = Math.abs(data.quantity_delta || 0);
      
      if (!skuTotals[skuId]) skuTotals[skuId] = 0;
      skuTotals[skuId] += qty;
    });

    // Update avg_daily_consumption for each SKU
    const batch = db.batch();
    for (const [skuId, totalQty] of Object.entries(skuTotals)) {
      const avgDaily = totalQty / 14.0;
      const skuRef = db.collection("inventory").doc(skuId);
      batch.update(skuRef, { 
        avg_daily_consumption: avgDaily,
        last_updated: new Date()
      });
      console.log(`SKU ${skuId}: New avg daily consumption = ${avgDaily.toFixed(2)}`);
    }

    await batch.commit();
    console.log("Successfully updated 14-day rolling averages.");
  } catch (error) {
    console.error("Error computing rolling average:", error);
  }
});
