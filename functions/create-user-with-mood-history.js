const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Initialize Firebase Admin
function initializeFirebase() {
  try {
    const serviceAccountPath = path.join(__dirname, 'service-account-key.json');
    if (fs.existsSync(serviceAccountPath)) {
      console.log('📄 Using service-account-key.json...');
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      return;
    }

    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      console.log('📄 Using GOOGLE_APPLICATION_CREDENTIALS...');
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      return;
    }

    console.log('📄 Using default credentials...');
    admin.initializeApp({
      projectId: 'mindmate-917e3',
      credential: admin.credential.applicationDefault(),
    });
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK');
    console.error('\n📋 Please set up credentials first:');
    console.error('   node setup-firebase-credentials.js\n');
    process.exit(1);
  }
}

function askQuestion(prompt) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise(resolve => {
    rl.question(prompt, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

// Negative emotions progression over 20 days (gets progressively worse)
const negativeEmotionsProgression = [
  // Week 1: Starting to feel down (Days 1-5)
  { type: 'Sad', intensity: 3, notes: 'Feeling a bit down today' },
  { type: 'Tired', intensity: 3, notes: 'Feeling exhausted, no energy' },
  { type: 'Anxious', intensity: 3, notes: 'Feeling some anxiety, worried about things' },
  { type: 'Stressed', intensity: 3, notes: 'Work stress getting to me' },
  { type: 'Sad', intensity: 4, notes: 'Mood worsening, hard to stay positive' },

  // Week 2: Getting significantly worse (Days 6-10)
  { type: 'Depressed', intensity: 4, notes: 'Feeling depressed, hard to get out of bed' },
  { type: 'Anxious', intensity: 4, notes: 'Persistent anxiety, racing thoughts' },
  { type: 'Lonely', intensity: 4, notes: 'Feeling isolated and alone' },
  { type: 'Hopeless', intensity: 4, notes: 'Losing hope, everything feels pointless' },
  { type: 'Sad', intensity: 5, notes: 'Severe sadness, hard to focus on anything' },

  // Week 3: Critical level (Days 11-15)
  { type: 'Depressed', intensity: 5, notes: 'Deep depression, dark thoughts consuming me' },
  { type: 'Overwhelmed', intensity: 5, notes: 'Completely overwhelmed, unable to cope' },
  { type: 'Anxious', intensity: 5, notes: 'Severe anxiety attacks, panic episodes' },
  { type: 'Hopeless', intensity: 5, notes: 'Feeling hopeless about the future' },
  { type: 'Lonely', intensity: 5, notes: 'Extreme loneliness, disconnected from everything' },

  // Week 4: Very severe critical (Days 16-20)
  { type: 'Depressed', intensity: 5, notes: 'Struggling with persistent depression, losing will' },
  { type: 'Fearful', intensity: 4, notes: 'Feeling fearful and vulnerable' },
  { type: 'Anxious', intensity: 5, notes: 'Constant anxiety, unable to relax, intrusive thoughts' },
  { type: 'Sad', intensity: 5, notes: 'Overwhelming sadness, crying frequently' },
  { type: 'Hopeless', intensity: 5, notes: 'Severe hopelessness, desperately need support' },
];

async function createUserWithMoodHistory(email, userName, password) {
  const db = admin.firestore();
  const auth = admin.auth();

  try {
    console.log('\n🌱 Creating User with 20 Days of Bad Mood History\n');

    // Step 1: Create Firebase Auth user
    console.log(`📝 Step 1: Creating user account...`);
    let userRecord;
    try {
      userRecord = await auth.createUser({
        email: email,
        password: password,
        displayName: userName,
      });
      console.log(`✓ Auth user created`);
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log(`⚠ User already exists, using existing account`);
        userRecord = await auth.getUserByEmail(email);
      } else {
        throw error;
      }
    }

    const userID = userRecord.uid;

    // Step 2: Create Firestore user document
    console.log(`📁 Step 2: Creating user document...`);
    const userDoc = {
      userID,
      userName,
      userEmail: email,
      role: 'user',
      isDisabled: false,
      lastLogin: admin.firestore.Timestamp.now(),
      age: 28,
      gender: 'Not specified',
      settings: {
        darkMode: false,
        language: 'en',
        notificationPrefs: {},
        equippedAvatar: 'default',
        unlockedAvatars: ['default'],
      },
      // Counseling flags
      requiresCounseling: true,
      counselingNotes: 'User with 20-day deteriorating mood pattern - URGENT counseling required',
      counselingFlagDate: admin.firestore.Timestamp.now(),
    };

    await db.collection('users').doc(userID).set(userDoc);
    console.log(`✓ User document created\n`);

    // Step 3: Generate and add 20 days of mood logs
    console.log(`📊 Step 3: Generating 20 days of mood logs...`);
    console.log(`   (This simulates 20 days of progressively worsening mood)\n`);

    const moodLogs = [];
    const today = new Date();

    // Start from 20 days ago
    for (let daysAgo = 20; daysAgo > 0; daysAgo--) {
      const logDate = new Date(today);
      logDate.setDate(logDate.getDate() - daysAgo);
      // Random time between 8am and 8pm
      logDate.setHours(Math.floor(Math.random() * 12) + 8, Math.floor(Math.random() * 60));

      // Use progressively worsening emotions (index 0 = 20 days ago, index 19 = yesterday)
      const emotion = negativeEmotionsProgression[20 - daysAgo];

      moodLogs.push({
        logID: uuidv4(),
        userID: userID,
        emotionType: emotion.type,
        intensityScore: emotion.intensity,
        notes: emotion.notes,
        timestamp: admin.firestore.Timestamp.fromDate(logDate),
      });
    }

    // Add logs in batches
    const batchSize = 100;
    let totalAdded = 0;

    for (let i = 0; i < moodLogs.length; i += batchSize) {
      const batch = db.batch();
      const batchLogs = moodLogs.slice(i, Math.min(i + batchSize, moodLogs.length));

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
      process.stdout.write(`\r   ✓ Added ${totalAdded}/${moodLogs.length} mood logs`);
    }
    console.log('\n');

    // Step 4: Display summary
    console.log(`\n${'='.repeat(80)}`);
    console.log(`✅ USER CREATED SUCCESSFULLY WITH 20-DAY BAD MOOD HISTORY\n`);
    console.log(`📋 USER DETAILS:`);
    console.log(`   📧 Email: ${email}`);
    console.log(`   🔐 Password: ${password}`);
    console.log(`   👤 Name: ${userName}`);
    console.log(`   🆔 User ID: ${userID}\n`);

    console.log(`📊 MOOD PROGRESSION (20 Days):\n`);

    // Show weekly breakdown
    const weeks = [
      { title: 'WEEK 1: Initial Decline', range: [0, 5], severity: 'Low-Moderate' },
      { title: 'WEEK 2: Worsening', range: [5, 10], severity: 'Moderate-High' },
      { title: 'WEEK 3: Critical Level', range: [10, 15], severity: 'High-Critical' },
      { title: 'WEEK 4: Severe', range: [15, 20], severity: 'Critical' },
    ];

    weeks.forEach(week => {
      console.log(`   ${week.title} (${week.severity})`);
      const startIdx = week.range[0];
      const endIdx = week.range[1];
      for (let i = startIdx; i < endIdx; i++) {
        const log = moodLogs[i];
        const dayNum = i + 1;
        const intensity = '█'.repeat(log.intensityScore) + '░'.repeat(5 - log.intensityScore);
        console.log(`      Day ${String(dayNum).padStart(2)}: ${log.emotionType.padEnd(15)} [${intensity}] ${log.intensity || '   '}`);
      }
      console.log();
    });

    console.log(`⚠️  CLINICAL ASSESSMENT:\n`);
    console.log(`   • Timeline: 20-day progression`);
    console.log(`   • Starting Intensity: 3/5 (Low-Moderate)`);
    console.log(`   • Final Intensity: 5/5 (Critical)`);
    console.log(`   • Emotional Progression: Sadness → Anxiety → Depression → Hopelessness`);
    console.log(`   • Pattern: RAPID DETERIORATION`);
    console.log(`   • Status: 🚨 REQUIRES IMMEDIATE COUNSELING & INTERVENTION\n`);

    console.log(`🔔 SYSTEM NOTIFICATIONS:\n`);
    console.log(`   ✓ High-risk flag automatically set`);
    console.log(`   ✓ Counseling required flag enabled`);
    console.log(`   ✓ Admin notifications will be triggered\n`);

    console.log(`📋 ADMIN ACTION ITEMS:\n`);
    console.log(`   1. 🚨 PRIORITY: Mark as CRITICAL CASE`);
    console.log(`   2. 👨‍⚕️  Assign experienced counselor/therapist immediately`);
    console.log(`   3. 📞 Schedule URGENT counseling appointment (within 24 hours)`);
    console.log(`   4. 📝 Create intensive support plan`);
    console.log(`   5. 🏥 Consider referral to mental health professional`);
    console.log(`   6. 📞 Provide crisis hotline numbers`);
    console.log(`   7. 📊 Set up daily mood check-ins\n`);

    console.log(`🧪 TESTING IN APP:\n`);
    console.log(`   • Log in with: ${email}`);
    console.log(`   • Password: ${password}`);
    console.log(`   • Admin dashboard will show as HIGH-RISK user`);
    console.log(`   • Mood history displays 20-day deterioration trend\n`);

    console.log(`${'='.repeat(80)}\n`);

    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error creating user:', error.message);
    console.error(error);
    process.exit(1);
  }
}

// Main
async function main() {
  initializeFirebase();

  console.log('\n🌱 Create User with 20 Days of Bad Mood History\n');

  const email = process.argv[2];
  const userName = process.argv[3];
  const password = process.argv[4];

  let finalEmail = email;
  let finalName = userName;
  let finalPassword = password;

  // If arguments not provided, ask interactively
  if (!finalEmail) {
    finalEmail = await askQuestion('📧 Email address: ');
  }

  if (!finalName) {
    finalName = await askQuestion('👤 Display name: ');
  }

  if (!finalPassword) {
    finalPassword = await askQuestion('🔐 Password (min 6 chars): ');
  }

  // Validation
  if (!finalEmail || !finalName || !finalPassword) {
    console.error('\n❌ All fields are required\n');
    process.exit(1);
  }

  if (!finalEmail.includes('@')) {
    console.error('\n❌ Invalid email format\n');
    process.exit(1);
  }

  if (finalPassword.length < 6) {
    console.error('\n❌ Password must be at least 6 characters\n');
    process.exit(1);
  }

  await createUserWithMoodHistory(finalEmail, finalName, finalPassword);
}

main().catch(error => {
  console.error('\n❌ Error:', error.message);
  process.exit(1);
});
