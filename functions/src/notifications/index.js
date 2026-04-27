const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");

/**
 * Helper to send FCM notifications to all users with the "admin" role.
 * @param {string} title Notification title
 * @param {string} body Notification body
 */
async function sendAdminFCM(title, body) {
  const db = getFirestore();
  const messaging = getMessaging();

  try {
    const adminsSnapshot = await db.collection("users").where("role", "==", "admin").get();
    
    if (adminsSnapshot.empty) {
      console.log("No admins found to send FCM to.");
      return;
    }

    const tokens = [];
    adminsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.fcm_token) {
        tokens.push(data.fcm_token);
      }
    });

    if (tokens.length === 0) {
      console.log("No valid FCM tokens found for admins.");
      return;
    }

    const message = {
      notification: { title, body },
      tokens: tokens,
    };

    const response = await messaging.sendEachForMulticast(message);
    console.log(`Successfully sent FCM to ${response.successCount} admins. Failed: ${response.failureCount}`);
  } catch (error) {
    console.error("Error sending Admin FCM:", error);
  }
}

module.exports = { sendAdminFCM };
