const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin with proper credential handling
function initializeFirebase() {
  try {
    // Check for service account key in current directory
    const serviceAccountPath = path.join(__dirname, 'service-account-key.json');
    if (fs.existsSync(serviceAccountPath)) {
      console.log('📄 Using service-account-key.json...');
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      return;
    }

    // Check for GOOGLE_APPLICATION_CREDENTIALS env var
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      console.log('📄 Using GOOGLE_APPLICATION_CREDENTIALS...');
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      return;
    }

    // Try using FIREBASE_CONFIG
    if (process.env.FIREBASE_DATABASE_URL) {
      console.log('📄 Using FIREBASE_CONFIG environment variables...');
      admin.initializeApp({
        projectId: process.env.FIREBASE_PROJECT_ID,
        databaseURL: process.env.FIREBASE_DATABASE_URL,
      });
      return;
    }

    // Use project ID directly if we have environment variable
    console.log('📄 Attempting to use default credentials...');
    admin.initializeApp({
      projectId: 'mindmate-917e3',
      credential: admin.credential.applicationDefault(),
    });
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK');
    console.error('\n📋 Please provide Firebase credentials using one of these methods:\n');
    console.error('1️⃣  Service Account Key (Recommended):');
    console.error('   - Download from: Firebase Console → Project Settings → Service Accounts');
    console.error('   - Save as: functions/service-account-key.json');
    console.error('   - Run: node seed-demo-data.js\n');
    console.error('2️⃣  Environment Variable:');
    console.error('   - Windows (PowerShell):\n     $env:GOOGLE_APPLICATION_CREDENTIALS="C:\\path\\to\\service-account-key.json"\n     node seed-demo-data.js');
    console.error('   - Windows (CMD):\n     set GOOGLE_APPLICATION_CREDENTIALS=C:\\path\\to\\service-account-key.json\n     node seed-demo-data.js\n');
    console.error('3️⃣  Firebase CLI:');
    console.error('   - Install: npm install -g firebase-tools');
    console.error('   - Login: firebase login');
    console.error('   - Run: node seed-demo-data.js\n');
    process.exit(1);
  }
}

// Initialize Firebase Admin
initializeFirebase();

const db = admin.firestore();
const auth = admin.auth();

// Helper to generate mood logs for a week
function generateWeekMoodLogs(userID, baseDate, emotionPattern) {
  const logs = [];
  const startDate = new Date(baseDate);
  startDate.setDate(startDate.getDate() - 6); // Start from 6 days ago

  for (let i = 0; i < 7; i++) {
    const logDate = new Date(startDate);
    logDate.setDate(logDate.getDate() + i);
    logDate.setHours(Math.floor(Math.random() * 8) + 8, Math.floor(Math.random() * 60)); // Random time 8am-4pm

    const emotion = emotionPattern[i % emotionPattern.length];
    logs.push({
      logID: uuidv4(),
      userID,
      emotionType: emotion.type,
      intensityScore: emotion.intensity,
      notes: emotion.notes || null,
      timestamp: admin.firestore.Timestamp.fromDate(logDate),
    });
  }
  return logs;
}

// Helper to create user in Firebase Auth and Firestore
async function createUser(email, password, userName, isSeed = true) {
  try {
    // Create auth user
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: userName,
    });

    // Create Firestore user doc
    const userDoc = {
      userID: userRecord.uid,
      userName,
      userEmail: email,
      role: 'user',
      isDisabled: false,
      lastLogin: admin.firestore.Timestamp.now(),
      age: 25,
      gender: 'Not specified',
      settings: {
        darkMode: false,
        language: 'en',
        notificationPrefs: {},
        equippedAvatar: 'default',
        unlockedAvatars: ['default'],
      },
    };

    await db.collection('users').doc(userRecord.uid).set(userDoc);
    console.log(`✓ Created user: ${email} (ID: ${userRecord.uid})`);

    return userRecord.uid;
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log(`⚠ User ${email} already exists, fetching...`);
      const userRecord = await auth.getUserByEmail(email);
      return userRecord.uid;
    }
    throw error;
  }
}

// Main seed function
async function seedDemoData() {
  try {
    console.log('🌱 Starting demo data seed...\n');

    const baseDate = new Date();

    // 1. Create high-risk user (3 consecutive days of negative emotions)
    console.log('1️⃣  Creating high-risk user...');
    const highRiskUserID = await createUser('user0002@gmail.com', 'Demo@12345', 'User0002');

    // Add 3 consecutive days of negative emotions (triggers high-risk alert)
    const highRiskLogs = generateWeekMoodLogs(highRiskUserID, baseDate, [
      { type: 'Anxious', intensity: 4, notes: 'Feeling stressed about work' },
      { type: 'Anxious', intensity: 5, notes: 'Sleep was poor' },
      { type: 'Sad', intensity: 4, notes: 'Feeling down today' },
      { type: 'Calm', intensity: 3, notes: 'Had a good coffee' },
      { type: 'Happy', intensity: 4, notes: 'Watched a good movie' },
      { type: 'Tired', intensity: 3, notes: 'Long day at work' },
      { type: 'Calm', intensity: 3, notes: '' },
    ]);

    const batch1 = db.batch();
    highRiskLogs.forEach((log) => {
      const ref = db.collection('users').doc(highRiskUserID).collection('emotion_logs').doc(log.logID);
      batch1.set(ref, log);
    });
    await batch1.commit();
    console.log(`✓ Added ${highRiskLogs.length} emotion logs for high-risk user\n`);

    // 2. Create second user with varied mood logs
    console.log('2️⃣  Creating second demo user...');
    const user2ID = await createUser('user0003@gmail.com', 'Demo@12345', 'User0003');

    const user2Logs = generateWeekMoodLogs(user2ID, baseDate, [
      { type: 'Happy', intensity: 5, notes: 'Great day!' },
      { type: 'Calm', intensity: 4, notes: 'Meditation helped' },
      { type: 'Happy', intensity: 4, notes: 'Good conversation with friend' },
      { type: 'Tired', intensity: 3, notes: 'Work was busy' },
      { type: 'Calm', intensity: 4, notes: 'Evening walk was nice' },
      { type: 'Happy', intensity: 5, notes: 'Amazing workout' },
      { type: 'Calm', intensity: 3, notes: '' },
    ]);

    const batch2 = db.batch();
    user2Logs.forEach((log) => {
      const ref = db.collection('users').doc(user2ID).collection('emotion_logs').doc(log.logID);
      batch2.set(ref, log);
    });
    await batch2.commit();
    console.log(`✓ Added ${user2Logs.length} emotion logs for user 2\n`);

    // 3. Create third user with mixed mood logs
    console.log('3️⃣  Creating third demo user...');
    const user3ID = await createUser('user0004@gmail.com', 'Demo@12345', 'User0004');

    const user3Logs = generateWeekMoodLogs(user3ID, baseDate, [
      { type: 'Happy', intensity: 4, notes: 'Feeling optimistic' },
      { type: 'Anxious', intensity: 3, notes: 'Meeting went well though' },
      { type: 'Calm', intensity: 4, notes: 'Good sleep' },
      { type: 'Happy', intensity: 5, notes: 'Spending time with family' },
      { type: 'Tired', intensity: 4, notes: 'Lot of tasks' },
      { type: 'Calm', intensity: 3, notes: 'Took a break' },
      { type: 'Happy', intensity: 4, notes: 'Weekend started' },
    ]);

    const batch3 = db.batch();
    user3Logs.forEach((log) => {
      const ref = db.collection('users').doc(user3ID).collection('emotion_logs').doc(log.logID);
      batch3.set(ref, log);
    });
    await batch3.commit();
    console.log(`✓ Added ${user3Logs.length} emotion logs for user 3\n`);

    // 4. Add historical data for User0001 (if exists)
    console.log('4️⃣  Adding historical mood data for User0001...');
    try {
      const user0001Ref = db.collection('users').where('userEmail', '==', 'user0001@gmail.com');
      const snapshot = await user0001Ref.get();

      if (!snapshot.empty) {
        const user0001ID = snapshot.docs[0].id;
        console.log(`Found User0001: ${user0001ID}`);

        // Add mood logs from 30 days ago
        const historicalLogs = [];
        for (let daysAgo = 30; daysAgo > 0; daysAgo--) {
          const logDate = new Date(baseDate);
          logDate.setDate(logDate.getDate() - daysAgo);
          logDate.setHours(Math.floor(Math.random() * 8) + 8, Math.floor(Math.random() * 60));

          const emotions = [
            { type: 'Happy', intensity: 4 },
            { type: 'Calm', intensity: 3 },
            { type: 'Anxious', intensity: 2 },
            { type: 'Tired', intensity: 3 },
            { type: 'Happy', intensity: 5 },
            { type: 'Sad', intensity: 2 },
          ];

          const emotion = emotions[Math.floor(Math.random() * emotions.length)];

          historicalLogs.push({
            logID: uuidv4(),
            userID: user0001ID,
            emotionType: emotion.type,
            intensityScore: emotion.intensity,
            notes: null,
            timestamp: admin.firestore.Timestamp.fromDate(logDate),
          });
        }

        const batch4 = db.batch();
        historicalLogs.forEach((log) => {
          const ref = db.collection('users').doc(user0001ID).collection('emotion_logs').doc(log.logID);
          batch4.set(ref, log);
        });
        await batch4.commit();
        console.log(`✓ Added ${historicalLogs.length} historical emotion logs for User0001\n`);
      } else {
        console.log('⚠ User0001 not found. Skipping historical data.\n');
      }
    } catch (error) {
      console.error('Error adding data for User0001:', error.message);
    }

    console.log('✅ Demo data seed completed successfully!');
    console.log('\nSummary:');
    console.log('- High-risk user (user0002@gmail.com) with 3 consecutive negative days');
    console.log('- Demo user 2 (user0003@gmail.com) with mixed positive mood logs');
    console.log('- Demo user 3 (user0004@gmail.com) with balanced mood logs');
    console.log('- Historical data added for User0001 (if exists)');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding demo data:', error);
    process.exit(1);
  }
}

// Run the seed
seedDemoData();
