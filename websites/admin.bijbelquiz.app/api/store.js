// api/store.js - Store management API route for Vercel
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
  const { type, search } = req.query || {};
  const sanitizedQuery = { ...req.query };
  
  // Sanitize all query parameters
  if (type) sanitizedQuery.type = sanitizeInput(type);
  if (search) sanitizedQuery.search = sanitizeInput(search);
  
  // Validate query parameters
  if (type && (!validator.isAscii(type) || type.length > 50)) {
    return { valid: false, error: 'Invalid type parameter' };
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
  const id = pathParts[pathParts.length - 1] !== 'store' ? pathParts[pathParts.length - 1] : null;

  if (req.method === 'GET') {
    // Handle GET requests (all store items or specific item by ID)
    if (id) {
      // Get specific store item by ID
      const validation = validateIdParam(id);
      if (!validation.valid) {
        return res.status(400).json({ error: validation.error });
      }

      try {
        const { data, error } = await supabase
          .from('store_items')
          .select('*')
          .eq('id', id)
          .single();
        
        if (error) {
          console.error('Error fetching store item:', error);
          return res.status(500).json({ error: 'Failed to fetch store item' });
        }
        
        res.status(200).json(data);
      } catch (error) {
        console.error('Error fetching store item:', error);
        res.status(500).json({ error: 'Failed to fetch store item' });
      }
    } else {
      // Get all store items with filters
      const validation = validateAndSanitizeQuery(req);
      if (!validation.valid) {
        return res.status(400).json({ error: validation.error });
      }
      
      req.query = validation.sanitizedQuery;
      
      try {
        // Build query with filters
        let query = supabase.from('store_items').select('*').order('item_name');
        
        const { type, search } = req.query;
        
        // Apply filters
        if (type) query = query.eq('item_type', type);
        if (search) query = query.ilike('item_name', `%${search}%`);
        
        const { data, error } = await query;
        
        if (error) {
          console.error('Error fetching store items:', error);
          return res.status(500).json({ error: 'Failed to fetch store items' });
        }
        
        res.status(200).json(data);
      } catch (error) {
        console.error('Error fetching store items:', error);
        res.status(500).json({ error: 'Failed to fetch store items' });
      }
    }
  } else if (req.method === 'POST') {
    // Handle POST requests (create new store item)
    try {
      const newItem = sanitizeInput(req.body);
      
      // Validate required fields
      if (!newItem.item_key || newItem.item_key.length > 50) {
        return res.status(400).json({ error: 'Item key is required and must be less than 50 characters' });
      }
      
      if (!newItem.item_name || newItem.item_name.length < 1 || newItem.item_name.length > 100) {
        return res.status(400).json({ error: 'Item name is required and must be between 1 and 100 characters' });
      }
      
      if (newItem.item_description && newItem.item_description.length > 500) {
        return res.status(400).json({ error: 'Item description must be less than 500 characters' });
      }
      
      if (!newItem.item_type || !['powerup', 'theme', 'feature'].includes(newItem.item_type)) {
        return res.status(400).json({ error: 'Item type must be one of: powerup, theme, feature' });
      }
      
      if (typeof newItem.base_price !== 'number' || newItem.base_price < 0) {
        return res.status(400).json({ error: 'Base price must be a non-negative number' });
      }
      
      const { data, error } = await supabase
        .from('store_items')
        .insert([newItem])
        .select();
      
      if (error) {
        console.error('Error creating store item:', error);
        return res.status(500).json({ error: 'Failed to create store item' });
      }
      
      res.status(200).json({ message: 'Store item created successfully', id: data[0].id });
    } catch (error) {
      console.error('Error creating store item:', error);
      res.status(500).json({ error: 'Failed to create store item' });
    }
  } else if (req.method === 'PUT' && id) {
    // Handle PUT requests (update specific store item by ID)
    const validation = validateIdParam(id);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    try {
      const updateData = sanitizeInput(req.body);
      
      // Validate updateData fields
      if (updateData.item_name && (updateData.item_name.length < 1 || updateData.item_name.length > 100)) {
        return res.status(400).json({ error: 'Item name must be between 1 and 100 characters' });
      }
      
      if (updateData.item_description && updateData.item_description.length > 500) {
        return res.status(400).json({ error: 'Item description must be less than 500 characters' });
      }
      
      if (updateData.base_price && (!Number.isInteger(updateData.base_price) || updateData.base_price < 0)) {
        return res.status(400).json({ error: 'Base price must be a non-negative integer' });
      }
      
      const { data, error } = await supabase
        .from('store_items')
        .update(updateData)
        .eq('id', id);
      
      if (error) {
        console.error('Error updating store item:', error);
        return res.status(500).json({ error: 'Failed to update store item' });
      }
      
      res.status(200).json({ message: `Store item ${id} updated successfully` });
    } catch (error) {
      console.error('Error updating store item:', error);
      res.status(500).json({ error: 'Failed to update store item' });
    }
  } else if (req.method === 'DELETE' && id) {
    // Handle DELETE requests (delete specific store item by ID)
    const validation = validateIdParam(id);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }

    try {
      const { data, error } = await supabase
        .from('store_items')
        .delete()
        .eq('id', id);
      
      if (error) {
        console.error('Error deleting store item:', error);
        return res.status(500).json({ error: 'Failed to delete store item' });
      }
      
      res.status(200).json({ message: `Store item ${id} deleted successfully` });
    } catch (error) {
      console.error('Error deleting store item:', error);
      res.status(500).json({ error: 'Failed to delete store item' });
    }
  } else {
    return res.status(405).json({ error: 'Method not allowed' });
  }
}