// api/login.js - Login API route for Vercel
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import xss from 'xss';
import validator from 'validator';

// In production, admin users should come from a database
// For demo purposes only, using a hardcoded admin user
// IMPORTANT: Change these credentials before deploying to production!
let adminUsers = [];

// Initialize admin user with proper password handling
const initializeAdminUser = async () => {
  // Check if we have a pre-hashed password in the environment
  if (process.env.ADMIN_PASSWORD_HASH) {
    adminUsers = [
      {
        id: 1,
        username: process.env.ADMIN_USERNAME || 'admin',
        password: process.env.ADMIN_PASSWORD_HASH
      }
    ];
  } else {
    // If no pre-hashed password, hash the plain text password from env
    const plainPassword = process.env.ADMIN_PASSWORD || 'admin123';
    const hashedPassword = bcrypt.hashSync(plainPassword, 10);
    adminUsers = [
      {
        id: 1,
        username: process.env.ADMIN_USERNAME || 'admin',
        password: hashedPassword
      }
    ];
  }
};

// Initialize admin user
initializeAdminUser();

// Sanitize input function
const sanitizeInput = (input) => {
  if (typeof input === 'string') {
    // Sanitize using xss library and validator
    return xss(input).trim();
  } else if (typeof input === 'object' && input !== null) {
    const sanitized = {};
    for (const [key, value] of Object.entries(input)) {
      sanitized[key] = sanitizeInput(value); // Recursively sanitize
    }
    return sanitized;
  }
  return input;
};

export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    let { username, password } = req.body;

    // Validate and sanitize inputs
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }

    // Sanitize inputs
    username = sanitizeInput(username);
    password = sanitizeInput(password);

    // Validate username format (alphanumeric and some special chars)
    if (!validator.isAlphanumeric(username.replace(/[_\-@.]/g, '')) || username.length > 50) {
      return res.status(400).json({ error: 'Invalid username format' });
    }

    // Validate password length
    if (password.length < 6 || password.length > 128) {
      return res.status(400).json({ error: 'Password must be between 6 and 128 characters' });
    }

    // Find user
    const user = adminUsers.find(u => u.username === username);
    if (!user) {
      // To prevent user enumeration, we still do a hash comparison
      await bcrypt.hash('dummy', 10); // Perform dummy hash to maintain timing consistency
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Verify password using bcrypt (compare plain text with hashed password)
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Create JWT token
    const token = jwt.sign(
      { 
        id: user.id, 
        username: user.username,
        iat: Math.floor(Date.now() / 1000), // issued at time
        exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60) // expires in 24 hours
      },
      process.env.JWT_SECRET || 'fallback_secret_for_dev'
    );

    res.status(200).json({
      token,
      user: {
        id: user.id,
        username: user.username
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}