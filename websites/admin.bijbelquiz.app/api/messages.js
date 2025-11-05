// api/messages.js - Message management API route for Vercel
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
  const { search } = req.query || {};
  const sanitizedQuery = { ...req.query };
  
  // Sanitize all query parameters
  if (search) sanitizedQuery.search = sanitizeInput(search);
  
  // Validate query parameters
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
  const id = pathParts[pathParts.length - 1] !== 'messages' ? pathParts[pathParts.length - 1] : null;

  if (req.method === 'GET') {
    // Handle GET requests (all messages or specific message by ID)
    if (id) {
      // Get specific message by ID
      const validation = validateIdParam(id);
      if (!validation.valid) {
        return res.status(400).json({ error: validation.error });
      }

      try {
        const { data, error } = await supabase
          .from('messages')
          .select('*')
          .eq('id', id)
          .single();
        
        if (error) {
          console.error('Error fetching message:', error);
          return res.status(500).json({ error: 'Failed to fetch message' });
        }
        
        res.status(200).json(data);
      } catch (error) {
        console.error('Error fetching message:', error);
        res.status(500).json({ error: 'Failed to fetch message' });
      }
    } else {
      // Get all messages with search filter
      const validation = validateAndSanitizeQuery(req);
      if (!validation.valid) {
        return res.status(400).json({ error: validation.error });
      }
      
      req.query = validation.sanitizedQuery;
      
      try {
        // Build query with search filter
        let query = supabase.from('messages').select('*').order('created_at', { ascending: false });
        
        const { search } = req.query;
        
        // Apply search filter
        if (search) query = query.or(`title.ilike.%${search}%,content.ilike.%${search}%`);
        
        const { data, error } = await query;
        
        if (error) {
          console.error('Error fetching messages:', error);
          return res.status(500).json({ error: 'Failed to fetch messages' });
        }
        
        res.status(200).json(data);
      } catch (error) {
        console.error('Error fetching messages:', error);
        res.status(500).json({ error: 'Failed to fetch messages' });
      }
    }
  } else if (req.method === 'POST') {
    // Handle POST requests (create new message)
    try {
      const newMessage = sanitizeInput(req.body);
      
      // Validate required fields
      if (!newMessage.title || newMessage.title.length < 1 || newMessage.title.length > 200) {
        return res.status(400).json({ error: 'Title is required and must be between 1 and 200 characters' });
      }
      
      if (!newMessage.content || newMessage.content.length < 1 || newMessage.content.length > 2000) {
        return res.status(400).json({ error: 'Content is required and must be between 1 and 2000 characters' });
      }
      
      if (!newMessage.expiration_date || !validator.isISO8601(newMessage.expiration_date)) {
        return res.status(400).json({ error: 'Expiration date is required and must be in ISO8601 format' });
      }
      
      const { data, error } = await supabase
        .from('messages')
        .insert([newMessage])
        .select();
      
      if (error) {
        console.error('Error creating message:', error);
        return res.status(500).json({ error: 'Failed to create message' });
      }
      
      res.status(200).json({ message: 'Message created successfully', id: data[0].id });
    } catch (error) {
      console.error('Error creating message:', error);
      res.status(500).json({ error: 'Failed to create message' });
    }
  } else if (req.method === 'PUT' && id) {
    // Handle PUT requests (update specific message by ID)
    const validation = validateIdParam(id);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    try {
      const updateData = sanitizeInput(req.body);
      
      // Validate updateData fields
      if (updateData.title && (updateData.title.length < 1 || updateData.title.length > 200)) {
        return res.status(400).json({ error: 'Title must be between 1 and 200 characters' });
      }
      
      if (updateData.content && (updateData.content.length < 1 || updateData.content.length > 2000)) {
        return res.status(400).json({ error: 'Content must be between 1 and 2000 characters' });
      }
      
      if (updateData.expiration_date && !validator.isISO8601(updateData.expiration_date)) {
        return res.status(400).json({ error: 'Expiration date must be in ISO8601 format' });
      }
      
      const { data, error } = await supabase
        .from('messages')
        .update(updateData)
        .eq('id', id);
      
      if (error) {
        console.error('Error updating message:', error);
        return res.status(500).json({ error: 'Failed to update message' });
      }
      
      res.status(200).json({ message: `Message ${id} updated successfully` });
    } catch (error) {
      console.error('Error updating message:', error);
      res.status(500).json({ error: 'Failed to update message' });
    }
  } else if (req.method === 'DELETE' && id) {
    // Handle DELETE requests (delete specific message by ID)
    const validation = validateIdParam(id);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }

    try {
      const { data, error } = await supabase
        .from('messages')
        .delete()
        .eq('id', id);
      
      if (error) {
        console.error('Error deleting message:', error);
        return res.status(500).json({ error: 'Failed to delete message' });
      }
      
      res.status(200).json({ message: `Message ${id} deleted successfully` });
    } catch (error) {
      console.error('Error deleting message:', error);
      res.status(500).json({ error: 'Failed to delete message' });
    }
  } else {
    return res.status(405).json({ error: 'Method not allowed' });
  }
}