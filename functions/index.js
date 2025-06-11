// Cloud Function: sendVerificationCode
// Runtime: Node.js 20

const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");
const cors = require("cors")({ origin: true });
const functions = require('firebase-functions/v1');

admin.initializeApp();
// Force redeploy - Updated timestamp: May 4, 2025

const db = admin.firestore();

exports.sendVerificationCode = onRequest(
  {
    secrets: ["SENDGRID_API_KEY"], // ✅ إضافة هذا السطر فقط
  },
  async (req, res) => {
    return cors(req, res, async () => {
      if (req.method !== "POST") {
        return res.status(405).send("Method Not Allowed");
      }

      const email = req.body.email;
      if (!email) {
        return res.status(400).send("Email is required");
      }

      const code = Math.floor(100000 + Math.random() * 900000).toString();

      try {
        await admin.firestore().collection("otp_codes").doc(email).set({
          code,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 10 * 60 * 1000)
          ),
        });

        // ✅ استخدم السكريت بعد تعريفه
        const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
        sgMail.setApiKey(SENDGRID_API_KEY);

        const msg = {
          to: email,
          from: "chatgpyrj@gmail.com", // ✅ تأكد من تفعيله في SendGrid
          subject: "Your Verification Code",
          html: `<p>Your code is <strong>${code}</strong>. It will expire in 10 minutes.</p>`,
        };

        await sgMail.send(msg);
        res.status(200).send({ success: true });
      } catch (err) {
        console.error("❌ Error:", err);
        res.status(500).send("Internal Server Error");
      }
    });
  }
);

exports.sendNotification = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  const { userId, title, body } = req.body;

  if (!userId || !title || !body) {
    return res.status(400).send("userId, title, and body are required");
  }

  try {
    // Get the user's FCM token from Firestore
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.data();

    if (!userData || !userData.fcmToken) {
      return res.status(404).send("User not found or missing FCM token");
    }

    const message = {
      token: userData.fcmToken,
      notification: {
        title,
        body,
      },
    };

    await admin.messaging().send(message);
    res.status(200).send({ success: true, message: "Notification sent" });
  } catch (error) {
    console.error("❌ Error sending notification:", error);
    res.status(500).send("Failed to send notification");
  }
});

// 🔔 إشعار عند إضافة لايك على منتج
exports.onProductLikeAdded = functions.firestore
  .document('likes/{likeId}')
  .onCreate(async (snap, context) => {
    try {
      const likeData = snap.data();
      const { productId, userId: likerUserId } = likeData;
      
      console.log('Like added for product:', productId, 'by user:', likerUserId);
      
      // جلب بيانات المنتج
      const productDoc = await db.collection('products').doc(productId).get();
      if (!productDoc.exists) {
        console.log('Product not found:', productId);
        return;
      }
      
      const product = productDoc.data();
      const productOwnerId = product.createdBy;
      
      // ماتبعتش إشعار للشخص نفسه
      if (likerUserId === productOwnerId) {
        console.log('User liked their own product, skipping notification');
        return;
      }
      
      // جلب بيانات الشخص اللي عمل لايك
      const likerDoc = await db.collection('users').doc(likerUserId).get();
      const likerName = likerDoc.exists ? likerDoc.data().name || 'Anonymous' : 'Anonymous';
      
      // إنشاء الإشعار في قاعدة البيانات - بالإنجليزية
      const notification = {
        uid: productOwnerId,
        senderUid: likerUserId,
        senderName: likerName,
        senderImageUrl: likerDoc.exists ? likerDoc.data().profileImageUrl || '' : '',
        type: 'product_like',
        productId: productId,
        productName: product.name || 'Product',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        message: `${likerName} liked your product "${product.name || 'Product'}"`,
        read: false
      };
      
      // حفظ الإشعار
      await db.collection('notifications').add(notification);
      console.log('Notification saved to database');
      
      // جلب FCM token للمستخدم وإرسال Push Notification
      const ownerDoc = await db.collection('users').doc(productOwnerId).get();
      if (ownerDoc.exists && ownerDoc.data().fcmToken) {
        const fcmToken = ownerDoc.data().fcmToken;
        
        const message = {
          token: fcmToken,
          notification: {
            title: 'New Like ❤️',
            body: `${likerName} liked your product "${product.name || 'Product'}"`,
          },
          data: {
            type: 'product_like',
            productId: productId,
            senderUid: likerUserId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK'
          }
        };
        
        try {
          await admin.messaging().send(message);
          console.log('✅ Product like push notification sent successfully');
        } catch (error) {
          console.error('❌ Error sending push notification:', error);
        }
      } else {
        console.log('No FCM token found for user:', productOwnerId);
      }
      
    } catch (error) {
      console.error('❌ Error in onProductLikeAdded:', error);
    }
  });

// 🔔 إشعار عند إضافة كومنت على منتج - تم تعطيلها لمنع التكرار
exports.onProductCommentAdded = functions.firestore
  .document('products/{productId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    // تم تعطيل هذه الدالة لمنع تكرار الإشعارات
    // الإشعارات تتم من خلال التطبيق مباشرة
    console.log('🚫 Product comment notification blocked to prevent duplicates');
    return;
  });

// 🔔 إشعار عند إضافة كومنت على منشور - تم تعطيلها لمنع التكرار  
exports.onPostCommentAdded = functions.firestore
  .document('posts/{postId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    // تم تعطيل هذه الدالة لمنع تكرار الإشعارات
    // الإشعارات تتم من خلال التطبيق مباشرة
    console.log('🚫 Post comment notification blocked to prevent duplicates');
    return;
  });