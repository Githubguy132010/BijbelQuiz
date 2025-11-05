// api/index.js - Vercel serverless function for Admin Dashboard API
import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcrypt';
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

// Main handler function for Vercel
export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Extract path and method
  const { path, method } = req;
  
  // Health check endpoint
  if (path === '/health' && method === 'GET') {
    return res.json({ status: 'OK', timestamp: new Date().toISOString() });
  }

  // Check if this is an API request
  if (path.startsWith('/api/')) {
    const endpoint = path.replace('/api/', '');
    
    // Login endpoint (public)
    if (endpoint === 'login' && method === 'POST') {
      return handleLogin(req, res);
    }
    
    // All other API endpoints require authentication
    const authResult = authenticateToken(req);
    if (!authResult.authenticated) {
      return res.status(401).json({ error: authResult.error });
    }
    
    // Handle protected endpoints
    switch (endpoint) {
      case 'tracking':
        if (method === 'GET') {
          return handleGetTracking(req, res);
        }
        break;
      case 'errors':
        if (method === 'GET') {
          return handleGetErrors(req, res);
        }
        break;
      case 'errors/':
        // This case handles errors with an ID (errors/{id})
        const errorId = req.query.id;
        if (method === 'GET') {
          return handleGetErrorById(req, res, errorId);
        } else if (method === 'DELETE') {
          return handleDeleteError(req, res, errorId);
        }
        break;
      case 'store':
        if (method === 'GET') {
          return handleGetStore(req, res);
        } else if (method === 'POST') {
          return handlePostStore(req, res);
        } else if (method === 'PUT' && req.query.id) {
          return handlePutStore(req, res, req.query.id);
        } else if (method === 'DELETE' && req.query.id) {
          return handleDeleteStore(req, res, req.query.id);
        }
        break;
      case 'store/':
        // This case handles store items with an ID (store/{id})
        if (method === 'GET' && req.query.id) {
          return handleGetStoreById(req, res, req.query.id);
        }
        break;
      case 'messages':
        if (method === 'GET') {
          return handleGetMessages(req, res);
        } else if (method === 'POST') {
          return handlePostMessages(req, res);
        } else if (method === 'PUT' && req.query.id) {
          return handlePutMessages(req, res, req.query.id);
        } else if (method === 'DELETE' && req.query.id) {
          return handleDeleteMessages(req, res, req.query.id);
        }
        break;
      case 'messages/':
        // This case handles messages with an ID (messages/{id})
        if (method === 'GET' && req.query.id) {
          return handleGetMessageById(req, res, req.query.id);
        }
        break;
      default:
        return res.status(404).json({ error: 'Endpoint not found' });
    }
  }
  
  // For any other routes, return 404
  return res.status(404).json({ error: 'Not found' });
}

// Login endpoint handler
async function handleLogin(req, res) {
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

// Get tracking data handler
async function handleGetTracking(req, res) {
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

// Get error reports handler
async function handleGetErrors(req, res) {
  try {
    const validation = validateAndSanitizeQuery(req);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    req.query = validation.sanitizedQuery;
    
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

// Get specific error report by ID handler
async function handleGetErrorById(req, res, errorId) {
  try {
    const validation = validateIdParam(errorId);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const { data, error } = await supabase
      .from('error_reports')
      .select('*')
      .eq('id', errorId)
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
}

// Delete error report handler
async function handleDeleteError(req, res, errorId) {
  try {
    const validation = validateIdParam(errorId);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const { data, error } = await supabase
      .from('error_reports')
      .delete()
      .eq('id', errorId);
    
    if (error) {
      console.error('Error deleting error report:', error);
      return res.status(500).json({ error: 'Failed to delete error report' });
    }
    
    res.status(200).json({ message: `Error report ${errorId} deleted successfully` });
  } catch (error) {
    console.error('Error deleting error report:', error);
    res.status(500).json({ error: 'Failed to delete error report' });
  }
}

// Get store items handler
async function handleGetStore(req, res) {
  try {
    const validation = validateAndSanitizeQuery(req);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    req.query = validation.sanitizedQuery;
    
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

// Get specific store item by ID handler
async function handleGetStoreById(req, res, itemId) {
  try {
    const validation = validateIdParam(itemId);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const { data, error } = await supabase
      .from('store_items')
      .select('*')
      .eq('id', itemId)
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
}

// Update store item handler
async function handlePutStore(req, res, itemId) {
  try {
    const validation = validateIdParam(itemId);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
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
      .eq('id', itemId);
    
    if (error) {
      console.error('Error updating store item:', error);
      return res.status(500).json({ error: 'Failed to update store item' });
    }
    
    res.status(200).json({ message: `Store item ${itemId} updated successfully` });
  } catch (error) {
    console.error('Error updating store item:', error);
    res.status(500).json({ error: 'Failed to update store item' });
  }
}

// Delete store item handler
async function handleDeleteStore(req, res, itemId) {
  try {
    const validation = validateIdParam(itemId);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const { data, error } = await supabase
      .from('store_items')
      .delete()
      .eq('id', itemId);
    
    if (error) {
      console.error('Error deleting store item:', error);
      return res.status(500).json({ error: 'Failed to delete store item' });
    }
    
    res.status(200).json({ message: `Store item ${itemId} deleted successfully` });
  } catch (error) {
    console.error('Error deleting store item:', error);
    res.status(500).json({ error: 'Failed to delete store item' });
  }
}

// Create new store item handler
async function handlePostStore(req, res) {
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
}

// Get messages handler
async function handleGetMessages(req, res) {
  try {
    const validation = validateAndSanitizeQuery(req);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    req.query = validation.sanitizedQuery;
    
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

// Update message handler
async function handlePutMessages(req, res, messageId) {
  try {
    const validation = validateIdParam(messageId);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
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
      .eq('id', messageId);
    
    if (error) {
      console.error('Error updating message:', error);
      return res.status(500).json({ error: 'Failed to update message' });
    }
    
    res.status(200).json({ message: `Message ${messageId} updated successfully` });
  } catch (error) {
    console.error('Error updating message:', error);
    res.status(500).json({ error: 'Failed to update message' });
  }
}

// Delete message handler
async function handleDeleteMessages(req, res, messageId) {
  try {
    const validation = validateIdParam(messageId);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const { data, error } = await supabase
      .from('messages')
      .delete()
      .eq('id', messageId);
    
    if (error) {
      console.error('Error deleting message:', error);
      return res.status(500).json({ error: 'Failed to delete message' });
    }
    
    res.status(200).json({ message: `Message ${messageId} deleted successfully` });
  } catch (error) {
    console.error('Error deleting message:', error);
    res.status(500).json({ error: 'Failed to delete message' });
  }
}

// Create new message handler
async function handlePostMessages(req, res) {
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
}

// Get specific message by ID handler
async function handleMessageById(req, res, messageId) {
  try {
    const validation = validateIdParam(messageId);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('id', messageId)
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
}