const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { VertexAI } = require("@google-cloud/vertexai");

initializeApp();
const db = getFirestore();

// GCP Project configuration
// Using separate GCP project for Vertex AI
const PROJECT_ID = "project-a2d6ed25-99d9-4307-be2";
const REGION = "us-central1";
const MODEL = "gemini-2.5-flash";

const vertexAi = new VertexAI({ project: PROJECT_ID, location: REGION });
const generativeModel = vertexAi.getGenerativeModel({
  model: MODEL,
  generationConfig: {
    temperature: 0.2,
    responseMimeType: "application/json",
  },
});

// Core logic for the Scout Agent
async function executeScoutAgent() {
  console.log("Starting Scout Agent execution...");
  console.log(`Using project: ${PROJECT_ID}, region: ${REGION}, model: ${MODEL}`);

  // 1. Gather Inventory Data
  console.log("Step 1: Reading inventory...");
  const inventorySnapshot = await db.collection("inventory").get();
  const inventoryData = [];
  inventorySnapshot.forEach((doc) => {
    const data = doc.data();
    inventoryData.push({
      sku_id: data.sku_id,
      category_id: data.category_id,
      category_name: data.category_name,
      days_of_runway: data.days_of_runway,
      avg_daily_consumption: data.avg_daily_consumption,
    });
  });
  console.log(`  Found ${inventoryData.length} inventory items.`);

  // 2. Gather Sectors Data
  console.log("Step 2: Reading sectors...");
  const sectorsSnapshot = await db.collection("sectors").get();
  const sectorsData = [];
  sectorsSnapshot.forEach((doc) => {
    const data = doc.data();
    sectorsData.push({
      sector_id: data.sector_id,
      label: data.label,
      population_estimate: data.population_estimate,
      registered_beneficiaries: data.registered_beneficiaries,
      registered_donors: data.registered_donors,
    });
  });
  console.log(`  Found ${sectorsData.length} sectors.`);

  // 3. Construct the Prompt for Gemini
  console.log("Step 3: Constructing prompt...");
  const prompt = `
    You are the ReliefHub AI Scout, an expert resource management intelligence engine.
    Analyze the following inventory and sector data for an NGO.
    
    Inventory Data:
    ${JSON.stringify(inventoryData, null, 2)}
    
    Sectors Data:
    ${JSON.stringify(sectorsData, null, 2)}
    
    Your task is to predict resource scarcity and assign risk levels (HIGH, MEDIUM, LOW) for each category in each sector.
    Consider the following constraints:
    - If a category has SKUs with < 14 days of runway, it indicates higher risk.
    - Sectors with high beneficiary-to-donor ratios should have elevated risk.
    
    Respond STRICTLY with valid JSON adhering to the following schema:
    {
      "sector_risk": [
        {
          "sector_id": "string",
          "category": "string",
          "risk_level": "HIGH" | "MEDIUM" | "LOW",
          "primary_evidence": "string",
          "reasoning": "string",
          "predicted_runway_delta_days": number
        }
      ]
    }
  `;

  // 4. Call Vertex AI
  console.log("Step 4: Calling Gemini API...");
  const startTime = Date.now();
  const request = { contents: [{ role: "user", parts: [{ text: prompt }] }] };
  
  let result;
  try {
    result = await generativeModel.generateContent(request);
  } catch (aiError) {
    console.error("Vertex AI call FAILED:", aiError.message || aiError);
    console.error("Full error:", JSON.stringify(aiError, null, 2));
    throw new Error(`Vertex AI API call failed: ${aiError.message}`);
  }
  
  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`  Gemini responded in ${elapsed}s.`);
  const responseText = result.response.candidates[0].content.parts[0].text;
  
  // 5. Parse and Validate Output
  let parsedResponse;
  try {
    parsedResponse = JSON.parse(responseText);
    if (!parsedResponse.sector_risk || !Array.isArray(parsedResponse.sector_risk)) {
      throw new Error("Invalid schema structure: missing sector_risk array");
    }
  } catch (error) {
    console.error("Failed to parse or validate Gemini output:", error, "Raw Response:", responseText);
    throw new Error("AI Agent output validation failed.");
  }

  // 6. Update Firestore Sectors
  const batch = db.batch();
  
  // Group risks by sector
  const risksBySector = {};
  for (const item of parsedResponse.sector_risk) {
    if (!risksBySector[item.sector_id]) {
      risksBySector[item.sector_id] = {};
    }
    // We only care about risk_scores map: { CAT_01: "HIGH", ... }
    risksBySector[item.sector_id][item.category] = item.risk_level;
  }

  for (const sectorId of Object.keys(risksBySector)) {
    const sectorRef = db.collection("sectors").doc(sectorId);
    batch.update(sectorRef, {
      risk_scores: risksBySector[sectorId],
      last_scout_run: Timestamp.now(),
    });
  }

  await batch.commit();
  console.log(`Scout Agent completed successfully. Updated ${Object.keys(risksBySector).length} sectors.`);
  return parsedResponse;
}

// ----------------------------------------------------------------------
// 1. Scout agent — primary intelligence (Scheduled)
// ----------------------------------------------------------------------
exports.runScoutAgent = onSchedule({
  schedule: "every 6 hours",
  timeoutSeconds: 300,
  memory: "1GiB",
}, async (event) => {
  try {
    await executeScoutAgent();
  } catch (error) {
    console.error("Scheduled Scout Agent failed:", error);
  }
});

// ----------------------------------------------------------------------
// 2. Manual scout trigger — admin only, for demo (Callable)
// ----------------------------------------------------------------------
exports.manualScoutTrigger = onCall({ 
  cors: true,
  timeoutSeconds: 300,
  memory: "1GiB",
}, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to trigger the Scout Agent."
    );
  }

  // Check role in Firestore (since custom claims might not be set)
  const userDoc = await db.collection("users").doc(request.auth.uid).get();
  if (!userDoc.exists || userDoc.data().role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Only administrators can manually trigger the Scout Agent."
    );
  }

  try {
    const result = await executeScoutAgent();
    return { success: true, message: "Scout Agent executed successfully.", data: result };
  } catch (error) {
    console.error("Manual Scout Trigger failed:", error);
    throw new HttpsError("internal", error.message);
  }
});

// ----------------------------------------------------------------------
// 3. Zone status updater — fires when sector risk_scores change
// ----------------------------------------------------------------------
exports.updateZoneStatus = onDocumentWritten("sectors/{sectorId}", async (event) => {
  // Only trigger on updates
  if (!event.data.before.exists || !event.data.after.exists) return null;

  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  const beforeScores = JSON.stringify(beforeData.risk_scores || {});
  const afterScores = JSON.stringify(afterData.risk_scores || {});

  // If risk_scores didn't change, do nothing
  if (beforeScores === afterScores) return null;

  const scores = Object.values(afterData.risk_scores || {});
  let highCount = 0;
  let lowCount = 0;

  for (const score of scores) {
    if (score === "HIGH") highCount++;
    if (score === "LOW") lowCount++;
  }

  let newZoneStatus = "NEUTRAL";
  if (highCount >= 2) {
    newZoneStatus = "SCARCITY";
  } else if (highCount === 0 && lowCount >= 3) {
    newZoneStatus = "ABUNDANCE";
  }

  if (afterData.zone_status !== newZoneStatus) {
    console.log(`Updating sector ${event.params.sectorId} zone_status to ${newZoneStatus}`);
    return event.data.after.ref.update({ zone_status: newZoneStatus });
  }

  return null;
});
