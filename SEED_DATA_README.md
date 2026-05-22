# Demo Data Seed Script

This script populates your Firebase Firestore with demo data for testing the admin dashboard and mood tracking features.

## Data Created

1. **High-Risk User** (user0002@gmail.com)
   - 3 consecutive days of negative emotions (triggers high-risk alert)
   - Pattern: Anxious → Anxious → Sad → Calm → Happy → Tired → Calm

2. **Demo User 2** (user0003@gmail.com)
   - A week of mostly positive and calm moods
   - Great for showing a healthy mood progression

3. **Demo User 3** (user0004@gmail.com)
   - A week of balanced mixed emotions
   - Shows typical user mood variation

4. **User0001 Historical Data**
   - 30 days of historical mood logs
   - If user0001@gmail.com exists in your database

## Prerequisites

- Firebase Admin SDK (already included in `functions/`)
- Firebase project credentials
- Node.js 22+

## Setup

### Option 1: Using Google Cloud Service Account (Recommended)

1. Download your Google Cloud service account key from Firebase Console:
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file as `functions/service-account-key.json`

2. Run the seed script:
```bash
cd functions
GOOGLE_APPLICATION_CREDENTIALS=./service-account-key.json node seed-demo-data.js
```

### Option 2: Using Firebase CLI Authentication

1. Make sure Firebase CLI is installed and authenticated:
```bash
npm install -g firebase-tools
firebase login
firebase projects:list  # Verify your project is accessible
```

2. Run the seed script:
```bash
cd functions
node seed-demo-data.js
```

### Option 3: Using FIREBASE_CONFIG Environment Variable

1. Set up your Firebase config:
```bash
cd functions
export FIREBASE_PROJECT_ID=your-project-id
export FIREBASE_DATABASE_URL=https://your-project.firebaseio.com
node seed-demo-data.js
```

## Running the Script

```bash
cd functions
npm install  # If not already done
GOOGLE_APPLICATION_CREDENTIALS=./service-account-key.json node seed-demo-data.js
```

## Expected Output

```
🌱 Starting demo data seed...

1️⃣  Creating high-risk user...
✓ Created user: user0002@gmail.com (ID: xxxx)
✓ Added 7 emotion logs for high-risk user

2️⃣  Creating second demo user...
✓ Created user: user0003@gmail.com (ID: xxxx)
✓ Added 7 emotion logs for user 2

3️⃣  Creating third demo user...
✓ Created user: user0004@gmail.com (ID: xxxx)
✓ Added 7 emotion logs for user 3

4️⃣  Adding historical mood data for User0001...
Found User0001: xxxx
✓ Added 30 historical emotion logs for User0001

✅ Demo data seed completed successfully!
```

## Troubleshooting

### "GOOGLE_APPLICATION_CREDENTIALS not set"
- Make sure you have the service account key JSON file in the correct path
- Use absolute path: `GOOGLE_APPLICATION_CREDENTIALS=/full/path/to/service-account-key.json`

### "Permission denied" or "Insufficient permissions"
- Check your service account has Firestore permissions
- In Firebase Console: IAM → Grant "Editor" role to the service account

### "Email already exists"
- The script will reuse existing accounts and skip creation
- The emotional logs will still be added

## Testing the High-Risk Alert

After running the script:

1. Log in to the admin dashboard
2. Check the high-risk user (user0002@gmail.com) 
3. Should see a high-risk alert notification due to 3 consecutive negative emotions

## Demo Credentials

After running the script, you can log in with:

| Email | Password | Description |
|-------|----------|---|
| user0002@gmail.com | Demo@12345 | High-risk user (for alerts demo) |
| user0003@gmail.com | Demo@12345 | Positive mood user |
| user0004@gmail.com | Demo@12345 | Mixed mood user |

## Cleaning Up (Optional)

To delete the demo data, use the Firebase Console:

1. Go to Firestore Database
2. Delete users: user0002, user0003, user0004
3. Delete their emotion_logs subcollections

Or use Firebase CLI:
```bash
firebase firestore:delete users/USER_ID --recursive
```
