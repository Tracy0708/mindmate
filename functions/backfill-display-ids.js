// One-time backfill: assigns human-readable display IDs (User0001, Admin0001) to
// existing user documents that don't have one yet, and seeds the
// counters/userDisplaySeq doc so new signups continue from the right number.
//
// Idempotent: re-running only fills in users that are still missing a displayId.
// The real document key (Firebase Auth uid) is never touched.
//
// Usage:  node functions/backfill-display-ids.js
// Requires the same credentials as the other functions scripts
// (service-account-key.json or GOOGLE_APPLICATION_CREDENTIALS).

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function initializeFirebase() {
  const serviceAccountPath = path.join(__dirname, 'service-account-key.json');
  if (fs.existsSync(serviceAccountPath)) {
    console.log('📄 Using service-account-key.json...');
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
    });
    return;
  }
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.log('📄 Using GOOGLE_APPLICATION_CREDENTIALS...');
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
    return;
  }
  console.log('📄 Attempting to use default credentials...');
  admin.initializeApp({
    projectId: 'mindmate-917e3',
    credential: admin.credential.applicationDefault(),
  });
}

initializeFirebase();
const db = admin.firestore();

function format(prefix, n) {
  return `${prefix}${String(n).padStart(4, '0')}`;
}

async function backfill() {
  const snapshot = await db.collection('users').get();

  // Process oldest first so numbering follows signup order.
  const docs = snapshot.docs.slice().sort((a, b) => {
    const ta = a.data().createdAt?.toMillis?.() ?? 0;
    const tb = b.data().createdAt?.toMillis?.() ?? 0;
    return ta - tb;
  });

  // Seed counters from any display IDs that already exist, so we never reuse a number.
  const counts = { user: 0, admin: 0 };
  for (const doc of docs) {
    const existing = doc.data().displayId;
    if (typeof existing === 'string') {
      const m = existing.match(/^(User|Admin)(\d+)$/);
      if (m) {
        const field = m[1] === 'Admin' ? 'admin' : 'user';
        counts[field] = Math.max(counts[field], parseInt(m[2], 10));
      }
    }
  }

  let batch = db.batch();
  let pending = 0;
  let assigned = 0;

  for (const doc of docs) {
    if (doc.data().displayId) continue; // already has one — skip

    const isAdmin = doc.data().role === 'admin';
    const field = isAdmin ? 'admin' : 'user';
    counts[field] += 1;
    const displayId = format(isAdmin ? 'Admin' : 'User', counts[field]);

    batch.update(doc.ref, { displayId });
    assigned += 1;
    pending += 1;
    console.log(`  ${displayId}  ←  ${doc.id} (${doc.data().userEmail || 'no email'})`);

    // Firestore batches cap at 500 writes.
    if (pending >= 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }

  // Persist the final counter so the Cloud Function continues from here.
  batch.set(
    db.collection('counters').doc('userDisplaySeq'),
    { user: counts.user, admin: counts.admin },
    { merge: true }
  );
  await batch.commit();

  console.log(`\n✅ Backfill complete: ${assigned} display ID(s) assigned.`);
  console.log(`   Counter now at user=${counts.user}, admin=${counts.admin}.`);
}

backfill()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('❌ Backfill failed:', err);
    process.exit(1);
  });
