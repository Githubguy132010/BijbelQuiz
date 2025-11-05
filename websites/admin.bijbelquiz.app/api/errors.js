// api/errors.js - Error reports API route for Vercel
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

// Validate ID parameter
const validateIdParam = (id) => {
  if (!id || !validator.isInt(id, { min: 1, max: 999999 })) {
    return { valid: false, error: 'Invalid ID parameter' };
  }
  
  return { valid: true };
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

  // Extract the ID from the path if present
  const pathParts = req.url.split('/');
  const id = pathParts[pathParts.length - 1] !== 'errors' ? pathParts[pathParts.length - 1] : null;

  if (req.method === 'GET') {
    // Handle GET requests (all errors or specific error by ID)
    if (id) {
      // Get specific error by ID
      const validation = validateIdParam(id);
      if (!validation.valid) {
        return res.status(400).json({ error: validation.error });
      }

      try {
        const { data, error } = await supabase
          .from('error_reports')
          .select('*')
          .eq('id', id)
          .single();
        
        if (error) {
          console.error('Error fetching error report:', error);
          return res.status(500).json({ error: 'Failed to fetch error report' });
        }
        
        res.status(200).json(data);
      } catch (error) {
        console.error('Error fetching error report:', error);
        res.status(500).json({ error: 'Failed to fetch error report' });
      }
    } else {
      // Get all errors with filters
      const validation = validateAndSanitizeQuery(req);
      if (!validation.valid) {
        return res.status(400).json({ error: validation.error });
      }
      
      req.query = validation.sanitizedQuery;
      
      try {
        // Build query with filters
        let query = supabase.from('error_reports').select('*').order('timestamp', { ascending: false });
        
        const { type, user, question, search } = req.query;
        
        // Apply filters
        if (type) query = query.eq('error_type', type);
        if (user) query = query.ilike('user_id', `%${user}%`);
        if (question) query = query.eq('question_id', question);
        if (search) query = query.or(`error_message.ilike.%${search}%,user_message.ilike.%${search}%`);
        
        const { data, error } = await query;
        
        if (error) {
          console.error('Error fetching error reports:', error);
          return res.status(500).json({ error: 'Failed to fetch error reports' });
        }
        
        res.status(200).json(data);
      } catch (error) {
        console.error('Error fetching error reports:', error);
        res.status(500).json({ error: 'Failed to fetch error reports' });
      }
    }
  } else if (req.method === 'DELETE') {
    // Handle DELETE requests (delete specific error by ID)
    if (!id) {
      return res.status(400).json({ error: 'Error ID is required for deletion' });
    }

    const validation = validateIdParam(id);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }

    try {
      const { data, error } = await supabase
        .from('error_reports')
        .delete()
        .eq('id', id);
      
      if (error) {
        console.error('Error deleting error report:', error);
        return res.status(500).json({ error: 'Failed to delete error report' });
      }
      
      res.status(200).json({ message: `Error report ${id} deleted successfully` });
    } catch (error) {
      console.error('Error deleting error report:', error);
      res.status(500).json({ error: 'Failed to delete error report' });
    }
  } else {
    return res.status(405).json({ error: 'Method not allowed' });
  }
}