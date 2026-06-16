#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function main() {
  console.log('\n🔐 Firebase Credentials Setup\n');
  console.log('Your Firebase Project ID: mindmate-917e3\n');

  console.log('To seed demo data, you need to provide a Firebase service account key.\n');
  console.log('Steps:');
  console.log('1. Go to: https://console.firebase.google.com/');
  console.log('2. Select project "mindmate"');
  console.log('3. Click Project Settings (⚙️) → Service Accounts tab');
  console.log('4. Click "Generate New Private Key" (at bottom)');
  console.log('5. A JSON file will download\n');

  const hasFile = await question('Did you download the service account key? (y/n): ');

  if (hasFile.toLowerCase() !== 'y') {
    console.log('\n❌ Please download the service account key first, then run this script again.\n');
    rl.close();
    process.exit(1);
  }

  const filePath = await question('\nPaste the full path to your downloaded JSON file:\n(Example: C:\\Users\\YourName\\Downloads\\mindmate-917e3-xxxxx.json)\n> ');

  if (!filePath || filePath.trim() === '') {
    console.log('\n❌ No file path provided.\n');
    rl.close();
    process.exit(1);
  }

  const cleanPath = filePath.trim().replace(/^["']|["']$/g, '');

  if (!fs.existsSync(cleanPath)) {
    console.log(`\n❌ File not found: ${cleanPath}\n`);
    rl.close();
    process.exit(1);
  }

  try {
    const content = fs.readFileSync(cleanPath, 'utf8');
    const json = JSON.parse(content);

    if (!json.project_id || !json.private_key) {
      throw new Error('Invalid service account file');
    }

    const destPath = path.join(__dirname, 'functions', 'service-account-key.json');
    fs.copyFileSync(cleanPath, destPath);

    console.log('\n✅ Service account key copied successfully!');
    console.log(`📁 Saved to: ${destPath}\n`);
    console.log('You can now run the seed script:\n');
    console.log('   node functions/create-user-with-mood-history.js\n');

  } catch (error) {
    console.log(`\n❌ Error: ${error.message}\n`);
    rl.close();
    process.exit(1);
  }

  rl.close();
}

main();
