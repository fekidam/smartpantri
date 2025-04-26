import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// Firebase inicializálása
initializeApp();

export const sendGroupInviteNotification = onDocumentUpdated(
  "groups/{groupId}",
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    const oldSharedWith = beforeData.sharedWith || [];
    const newSharedWith = afterData.sharedWith || [];

    const addedUsers = newSharedWith.filter(
      (userId) => !oldSharedWith.includes(userId)
    );

    if (addedUsers.length === 0) {
      return null;
    }

    const groupName = afterData.name || "a group";
    const inviterId = afterData.userId;
    const inviterDoc = await getFirestore()
      .collection("users")
      .doc(inviterId)
      .get();
    const inviterEmail = inviterDoc.exists ? inviterDoc.data().email : "someone";

    for (const userId of addedUsers) {
      const tokensSnapshot = await getFirestore()
        .collection("users")
        .doc(userId)
        .collection("tokens")
        .get();

      const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);

      if (tokens.length === 0) {
        console.log(`No FCM tokens found for user ${userId}`);
        continue;
      }

      const payload = {
        notification: {
          title: "Group Invitation",
          body: `${inviterEmail} invited you to the group "${groupName}"!`,
        },
        data: {
          screen: "group_home",
          groupId: event.params.groupId,
        },
      };

      try {
        await getMessaging().sendEachForMulticast({
          tokens: tokens,
          ...payload,
        });
        console.log(`Notification sent to user ${userId}`);
      } catch (error) {
        console.error(`Error sending notification to user ${userId}:`, error);
      }
    }

    return null;
  }
);