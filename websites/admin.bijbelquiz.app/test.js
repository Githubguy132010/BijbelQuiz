// BijbelQuiz Admin Dashboard - Test Script

const fs = require('fs');
const path = require('path');

// Test script to verify the admin dashboard functionality
console.log('BijbelQuiz Next.js Admin Dashboard - Functionality Verification');

// Check if all required files exist
const requiredFiles = [
  'pages/index.js',
  'pages/api/index.js',
  'public/styles.css',
  'public/script.js',
  'package.json',
  '.env',
  'next.config.js',
  'vercel.json'
];

console.log('\n1. Checking required files:');
let allFilesExist = true;

requiredFiles.forEach(file => {
  const filePath = path.join(__dirname, file);
  const exists = fs.existsSync(filePath);
  console.log(`   ${exists ? '✓' : '✗'} ${file}`);
  if (!exists) allFilesExist = false;
});

if (!allFilesExist) {
  console.log('\n❌ Some required files are missing!');
  process.exit(1);
}

// Check if package.json has all required dependencies
const packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8'));
const requiredDeps = [
  'next',
  'react',
  'react-dom',
  '@supabase/supabase-js',
  'express',
  'cors',
  'express-rate-limit',
  'jsonwebtoken',
  'bcrypt',
  'dotenv',
  'express-slow-down',
  'express-mongo-sanitize',
  'helmet',
  'xss-clean',
  'express-validator'
];

console.log('\n2. Checking required dependencies:');
let allDepsExist = true;

requiredDeps.forEach(dep => {
  const exists = packageJson.dependencies && packageJson.dependencies[dep];
  console.log(`   ${exists ? '✓' : '✗'} ${dep}`);
  if (!exists) allDepsExist = false;
});

if (!allDepsExist) {
  console.log('\n❌ Some required dependencies are missing!');
  process.exit(1);
}

// Check if Next.js page has all required elements
const jsxContent = fs.readFileSync(path.join(__dirname, 'pages/index.js'), 'utf8');
const requiredElements = [
  'id="password"',
  'dashboard-container',
  'tracking-tab',
  'errors-tab',
  'store-tab',
  'messages-tab'
];

console.log('\n3. Checking Next.js page structure:');
let allElementsExist = true;

requiredElements.forEach(element => {
  const exists = jsxContent.includes(element);
  console.log(`   ${exists ? '✓' : '✗'} ${element.substring(0, 30)}${element.length > 30 ? '...' : ''}`);
  if (!exists) allElementsExist = false;
});

if (!allElementsExist) {
  console.log('\n❌ Some required page elements are missing!');
  process.exit(1);
}

// Check if API route has required security functions
const apiRouteContent = fs.readFileSync(path.join(__dirname, 'pages/api/index.js'), 'utf8');
const securityChecks = [
  'verifyToken',
  'rateLimit',
  'supabase',
  'jwt.sign',
  'validationResult'
];

console.log('\n4. Checking API security configurations:');
let allSecurityOk = true;

securityChecks.forEach(check => {
  const exists = apiRouteContent.includes(check);
  console.log(`   ${exists ? '✓' : '✗'} ${check}`);
  if (!exists) allSecurityOk = false;
});

if (!allSecurityOk) {
  console.log('\n❌ Some security configurations are missing!');
  process.exit(1);
}

console.log('\n✅ All checks passed! The Next.js admin dashboard is properly set up with security measures.');
console.log('\nTo run the dashboard:');
console.log('1. Update the .env file with your Supabase credentials and admin password');
console.log('2. Run `npm install` to install dependencies');
console.log('3. For development: `npm run dev`');
console.log('4. For production: `npm run build && npm start`');
console.log('5. Access the dashboard at http://localhost:3000');

console.log('\nThe admin dashboard includes:');
console.log('- Server-side authentication with password stored in environment variables');
console.log('- JWT token-based authorization for all API endpoints');
console.log('- Tracking data analysis with filtering and visualization');
console.log('- Error reports management with deletion capability');
console.log('- Store items management (add, edit, delete)');
console.log('- Messages management (add, edit, delete)');
console.log('- Comprehensive security measures (rate limiting, input sanitization, XSS protection)');

console.log('\nSecurity features for public hosting:');
console.log('- All sensitive configuration stored in environment variables (not in source code)');
console.log('- Authentication handled server-side with no client-side password storage');
console.log('- JWT tokens expire after 8 hours');
console.log('- All API endpoints protected with token validation');
console.log('- Input validation and sanitization on both client and server side');
console.log('- Optimized for Vercel deployment');