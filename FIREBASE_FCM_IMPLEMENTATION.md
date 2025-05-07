# Firebase Cloud Messaging (FCM) Implementation for My Byaj Book

This document outlines the Firebase Cloud Messaging implementation in My Byaj Book app.

## Features Added

1. **Firebase Cloud Messaging Integration**
   - Added `firebase_messaging` package
   - Configured background message handling
   - Set up foreground message handling
   - Implemented local notification display for FCM messages

2. **Android Configuration**
   - Added necessary permissions in AndroidManifest.xml
   - Configured FCM service and receiver
   - Added FLUTTER_NOTIFICATION_CLICK intent filter

3. **Notification Service Enhancement**
   - Added FCM message handling functionality to NotificationService
   - Implemented local notification display from FCM messages
   - Added support for different notification types (loan, card, reminder)

## How to Use FCM in This App

### Testing FCM

You can test FCM notifications using the Firebase Console:

1. Go to Firebase Console > Project > Messaging
2. Create a new notification
3. Target your app
4. For data messages, use the following format:

```json
{
  "type": "loan", // or "card" or "reminder"
  "loanId": "your_loan_id", // if type is loan
  "cardId": "your_card_id", // if type is card
  "reminderId": "your_reminder_id", // if type is reminder
  "action": "view_details" // or "mark_as_paid" for loan notifications
}
```

### FCM Token

The FCM token for the device is printed in the console logs during app initialization. You can find it by searching for "FCM Token:" in the logs.

Current FCM Token: `fmAMjRpiSEelhmjzVYDJIm:APA91bH5IA7bO3-DySsiMwnJJHDIZBsDQ3AKPk942W7gDRc3F3iOCRp8t-XSJadfPeXfyIBYeLLq_drsj8c8cMot9aRsZ6WEMeAbjUjKsNj0rRCHP3a-kLw`

### Server Integration

To send notifications from your server:

1. Use Firebase Admin SDK or Firebase Cloud Messaging HTTP v1 API
2. Send to specific devices using their FCM token
3. Format your data payload as shown above

## Next Steps

1. **Setup Firebase Cloud Functions** - Create serverless functions to trigger notifications based on events
2. **Store FCM Tokens** - Save user FCM tokens in your database to target specific users
3. **Topic Subscriptions** - Implement topic-based messaging for broader notifications

## Troubleshooting

If notifications are not working:

1. Check that Firebase is properly initialized
2. Verify the device has granted notification permissions
3. Make sure your FCM token is valid and not expired
4. Test with a direct message from Firebase Console 