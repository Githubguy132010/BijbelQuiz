// api/tracking.js - Tracking API route for Vercel
import { createClient } from '@supabase/supabase-js';
import jwt from 'jsonwebtoken';
import xss from 'xss';
import validator from 'validator';

// Initialize Supabase client
let supabase;
if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY) {
    supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
} else {
    console.error("Supabase configuration is missing. Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in your environment.");
}

// Verify token middleware
const authenticateToken = (req) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return { authenticated: false, error: 'Access token required' };
  }

  try {
    const user = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret_for_dev');
    return { authenticated: true, user };
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return { authenticated: false, error: 'Token expired' };
    } else if (err.name === 'JsonWebTokenError') {
      return { authenticated: false, error: 'Invalid token' };
    }
    return { authenticated: false, error: 'Invalid or expired token' };
  }
};

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

// Validate and sanitize query parameters
const validateAndSanitizeQuery = (req) => {
  const { type, user, question, search } = req.query || {};
  const sanitizedQuery = { ...req.query };
  
  // Sanitize all query parameters
  if (type) sanitizedQuery.type = sanitizeInput(type);
  if (user) sanitizedQuery.user = sanitizeInput(user);
  if (question) sanitizedQuery.question = sanitizeInput(question);
  if (search) sanitizedQuery.search = sanitizeInput(search);
  
  // Validate query parameters
  if (type && (!validator.isAscii(type) || type.length > 50)) {
    return { valid: false, error: 'Invalid type parameter' };
  }
  
  if (user && (!validator.isAscii(user) || user.length > 100)) {
    return { valid: false, error: 'Invalid user parameter' };
  }
  
  if (question && (!validator.isAscii(question) || question.length > 50)) {
    return { valid: false, error: 'Invalid question parameter' };
  }
  
  if (search && (!validator.isAscii(search) || search.length > 100)) {
    return { valid: false, error: 'Invalid search parameter' };
  }
  
  return { valid: true, sanitizedQuery };
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

  // Authenticate the request
  const authResult = authenticateToken(req);
  if (!authResult.authenticated) {
    return res.status(401).json({ error: authResult.error });
  }

  // Only allow GET requests
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const validation = validateAndSanitizeQuery(req);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    req.query = validation.sanitizedQuery;
    
    // Build query with filters
    let query = supabase.from('tracking_events').select('*').order('timestamp', { ascending: false });
    
    const { type, user, question, search } = req.query;
    
    // Apply filters
    if (type) query = query.eq('event_type', type);
    if (user) query = query.ilike('user_id', `%${user}%`);
    if (question) query = query.eq('question_id', question);
    if (search) query = query.or(`event_name.ilike.%${search}%,user_id.ilike.%${search}%`);
    
    const { data, error } = await query;
    
    if (error) {
      console.error('Error fetching tracking data:', error);
      return res.status(500).json({ error: 'Failed to fetch tracking data' });
    }
    
    res.status(200).json(data);
  } catch (error) {
    console.error('Error fetching tracking data:', error);
    res.status(500).json({ error: 'Failed to fetch tracking data' });
  }
}