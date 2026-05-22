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

    // Use project ID directly
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
    console.error('   - Run: node seed-user-history.js <userID>\n');
    console.error('2️⃣  Environment Variable:');
    console.error('   - Windows (PowerShell):\n     $env:GOOGLE_APPLICATION_CREDENTIALS="C:\\path\\to\\service-account-key.json"\n     node seed-user-history.js <userID>\n');
    process.exit(1);
  }
}

// Generate mood logs for past 30 days
function generateHistoricalLogs(userID, baseDate = new Date()) {
  const logs = [];
  const emotions = [
    { type: 'Happy', intensity: 5 },
    { type: 'Calm', intensity: 4 },
    { type: 'Anxious', intensity: 2 },
    { type: 'Tired', intensity: 3 },
    { type: 'Happy', intensity: 5 },
    { type: 'Sad', intensity: 2 },
    { type: 'Content', intensity: 4 },
    { type: 'Stressed', intensity: 2 },
  ];

  // Generate 30 days of data
  for (let daysAgo = 30; daysAgo >= 1; daysAgo--) {
    const logDate = new Date(baseDate);
    logDate.setDate(logDate.getDate() - daysAgo);
    // Random time between 8am and 8pm
    logDate.setHours(Math.floor(Math.random() * 12) + 8, Math.floor(Math.random() * 60));

    const emotion = emotions[Math.floor(Math.random() * emotions.length)];

    logs.push({
      logID: uuidv4(),
      userID,
      emotionType: emotion.type,
      intensityScore: emotion.intensity,
      notes: null,
      timestamp: admin.firestore.Timestamp.fromDate(logDate),
    });
  }

  return logs;
}

// Main function
async function seedUserHistory(userID) {
  if (!userID) {
    console.error('❌ No userID provided');
    console.error('\nUsage: node seed-user-history.js <userID>');
    console.error('\nExample: node seed-user-history.js nMwPMwHofmPyboIbfBC2t0sEt8p1');
    process.exit(1);
  }

  try {
    initializeFirebase();

    const db = admin.firestore();

    console.log('\n🌱 Seeding historical mood data...\n');
    console.log(`📊 Target User ID: ${userID}`);

    // Verify user exists
    const userDoc = await db.collection('users').doc(userID).get();
    if (!userDoc.exists) {
      console.error(`\n❌ User not found: ${userID}`);
      console.error('Please verify the user ID is correct.\n');
      process.exit(1);
    }

    const userData = userDoc.data();
    console.log(`✓ Found user: ${userData.userName} (${userData.userEmail})\n`);

    // Generate historical logs
    const historicalLogs = generateHistoricalLogs(userID);
    console.log(`📝 Generating ${historicalLogs.length} mood logs from the past 30 days...\n`);

    // Add logs in batches (Firestore has a 500-write limit per batch)
    const batchSize = 100;
    let totalAdded = 0;

    for (let i = 0; i < historicalLogs.length; i += batchSize) {
      const batch = db.batch();
      const batchLogs = historicalLogs.slice(i, Math.min(i + batchSize, historicalLogs.length));

      batchLogs.forEach((log) => {
        const ref = db
          .collection('users')
          .doc(userID)
          .collection('emotion_logs')
          .doc(log.logID);
        batch.set(ref, log);
      });

      await batch.commit();
      totalAdded += batchLogs.length;
      console.log(`  ✓ Added ${totalAdded}/${historicalLogs.length} logs`);
    }

    console.log(`\n✅ Successfully added ${totalAdded} historical mood logs!\n`);
    console.log('📈 Data includes:');
    console.log('   - Last 30 days of mood entries');
    console.log('   - Random emotions: Happy, Calm, Anxious, Tired, Sad, Content, Stressed');
    console.log('   - Random timestamps throughout each day');
    console.log('   - Intensity scores from 2-5\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding historical data:', error.message);
    process.exit(1);
  }
}

// Get userID from command line arguments
const userID = process.argv[2];
seedUserHistory(userID);
