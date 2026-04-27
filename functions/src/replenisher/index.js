const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { sendAdminFCM } = require("../notifications");
const { VertexAI } = require("@google-cloud/vertexai");

const PROJECT_ID = "project-a2d6ed25-99d9-4307-be2";
const REGION = "us-central1";
const MODEL = "gemini-2.5-flash";

const vertexAi = new VertexAI({ project: PROJECT_ID, location: REGION });
const generativeModel = vertexAi.getGenerativeModel({
  model: MODEL,
  generationConfig: { temperature: 0.7 }, // Slightly more creative for descriptions
});

/**
 * Creates a proactive donation drive when runway hits MONITOR or WARNING status.
 */
async function createDonationDrive(skuData) {
  const db = getFirestore();
  const driveId = `DRIVE-${Date.now()}`;
  
  // Calculate quantity needed to get back to safe threshold (e.g. 45 days)
  const safeDays = 45;
  const targetQty = Math.max(1, Math.ceil((safeDays - skuData.days_of_runway) * skuData.avg_daily_consumption));

  // Generate Gemini description
  let geminiDescription = "A new proactive donation drive has been initiated to secure essential supplies for our community.";
  try {
    const prompt = `
      You are the ReliefHub NGO Coordinator. Write a short, empathetic, and urgent (but not panicked) 
      2-sentence description for a proactive donation drive to collect "${skuData.sku_name}". 
      Currently, the runway is at ${skuData.days_of_runway.toFixed(1)} days.
      Do not include hashtags. Do not use quotes around the entire text.
    `;
    const request = { contents: [{ role: "user", parts: [{ text: prompt }] }] };
    const result = await generativeModel.generateContent(request);
    geminiDescription = result.response.candidates[0].content.parts[0].text.trim();
  } catch (error) {
    console.error("Failed to generate Gemini description for drive:", error);
  }

  const driveData = {
    drive_id: driveId,
    created_at: Timestamp.now(),
    urgency_mode: "PROACTIVE",
    trigger_sku_id: skuData.sku_id,
    trigger_category_id: skuData.category_id,
    runway_at_creation_days: skuData.days_of_runway,
    target_items: [
      {
        sku_id: skuData.sku_id,
        qty_needed: targetQty,
        qty_pledged: 0,
        qty_received: 0,
      }
    ],
    drop_off_point: {
      name: "Main ReliefHub Storehouse",
      lat: 18.6298,
      lng: 73.8553,
    },
    drive_window_days: 14,
    expires_at: Timestamp.fromDate(new Date(Date.now() + 14 * 24 * 60 * 60 * 1000)),
    status: "ACTIVE",
    gemini_description: geminiDescription,
    fulfilled_at: null,
  };

  await db.collection("donation_drives").doc(driveId).set(driveData);
  console.log(`Donation Drive ${driveId} created successfully.`);

  // Send Admin FCM
  await sendAdminFCM(
    "Proactive Drive Created",
    `A new drive for ${skuData.sku_name} has been launched automatically.`
  );
}

// ----------------------------------------------------------------------
// Drive expiry — daily check
// ----------------------------------------------------------------------
exports.expireDonationDrive = onSchedule("every 24 hours", async (event) => {
  const db = getFirestore();
  const now = Timestamp.now();
  
  try {
    const activeDrivesSnapshot = await db.collection("donation_drives")
      .where("status", "==", "ACTIVE")
      .where("expires_at", "<", now)
      .get();

    if (activeDrivesSnapshot.empty) {
      console.log("No drives to expire today.");
      return;
    }

    const batch = db.batch();
    activeDrivesSnapshot.forEach(doc => {
      batch.update(doc.ref, { status: "EXPIRED" });
    });

    await batch.commit();
    console.log(`Successfully expired ${activeDrivesSnapshot.size} donation drives.`);
  } catch (error) {
    console.error("Error expiring donation drives:", error);
  }
});

// ----------------------------------------------------------------------
// Callable: Check runway after stock update and create drive if needed
// ----------------------------------------------------------------------
const { onCall, HttpsError } = require("firebase-functions/v2/https");

exports.checkRunwayAndCreateDrive = onCall({
  cors: true,
  timeoutSeconds: 300,
  memory: "1GiB",
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in.");
  }

  const { skuId } = request.data;
  if (!skuId) {
    throw new HttpsError("invalid-argument", "skuId is required.");
  }

  const db = getFirestore();
  const skuDoc = await db.collection("inventory").doc(skuId).get();
  if (!skuDoc.exists) {
    throw new HttpsError("not-found", "SKU not found.");
  }

  const skuData = skuDoc.data();
  const currentStock = skuData.current_stock || 0;
  const reservedStock = skuData.reserved_stock || 0;
  const avgDailyConsumption = skuData.avg_daily_consumption || 0;

  let runway = 999.0;
  if (avgDailyConsumption > 0) {
    runway = (currentStock - reservedStock) / avgDailyConsumption;
  }

  console.log(`checkRunwayAndCreateDrive: SKU ${skuId}, runway = ${runway.toFixed(1)} days`);

  if (runway < 7) {
    // CRITICAL — send FCM alert, no drive
    await sendAdminFCM(
      "CRITICAL SCARCITY ALERT",
      `${skuData.sku_name} has dropped below 7 days of runway (${runway.toFixed(1)} days)! Immediate dispatch required.`
    );
    return { action: "CRITICAL_ALERT", runway: runway };
  } else if (runway < 30) {
    // WARNING or MONITOR — create proactive drive if none exists
    const activeDrives = await db.collection("donation_drives")
      .where("status", "==", "ACTIVE")
      .get();
    
    let alreadyExists = false;
    activeDrives.forEach(doc => {
      if (doc.data().trigger_sku_id === skuId) alreadyExists = true;
    });

    if (!alreadyExists) {
      const updatedSkuData = { ...skuData, days_of_runway: runway };
      await createDonationDrive(updatedSkuData);
      return { action: "DRIVE_CREATED", runway: runway };
    }
    return { action: "DRIVE_EXISTS", runway: runway };
  }

  return { action: "SAFE", runway: runway };
});

module.exports.createDonationDrive = createDonationDrive;
module.exports.expireDonationDrive = exports.expireDonationDrive;
module.exports.checkRunwayAndCreateDrive = exports.checkRunwayAndCreateDrive;

