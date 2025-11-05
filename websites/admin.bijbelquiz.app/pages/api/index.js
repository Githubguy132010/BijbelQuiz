// Next.js API endpoint for authentication
import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import Cors from 'cors';
import rateLimit from 'express-rate-limit';
import slowDown from 'express-slow-down';
import mongoSanitize from 'express-mongo-sanitize';
import xss from 'xss-clean';
import { body, validationResult } from 'express-validator';

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// Create middleware instances
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

const slowDownMiddleware = slowDown({
  windowMs: 15 * 60 * 1000, // 15 minutes
  delayAfter: 50, // Begin slowing down after 50 requests
  delayMs: 500 // Each request after the 50th will be delayed by 500ms
});

// JWT middleware to verify token
const verifyToken = (req, res, next) => {
  // Get token from header
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token.' });
  }
};

// Validation middleware
const validateLogin = [
  body('password')
    .trim()
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 1 })
    .withMessage('Password cannot be empty')
];

// API handler
export default async function handler(req, res) {
  // Apply rate limiting
  await new Promise((resolve, reject) => {
    limiter(req, res, (err) => {
      if (err) reject(err);
      else resolve();
    });
  });

  // Apply slow down
  await new Promise((resolve, reject) => {
    slowDownMiddleware(req, res, (err) => {
      if (err) reject(err);
      else resolve();
    });
  });

  // Apply input sanitization
  mongoSanitize()(req, res, () => {
    xss()(req, res, async () => {
      try {
        if (req.method === 'POST' && req.url.includes('/api/login')) {
          // Handle login
          const { password } = req.body;

          if (!password) {
            return res.status(400).json({ error: 'Password is required' });
          }

          if (password === process.env.ADMIN_PASSWORD) {
            // Create JWT token
            const token = jwt.sign(
              { 
                userId: 'admin', 
                role: 'admin',
                exp: Math.floor(Date.now() / 1000) + (60 * 60 * 8) // 8 hours
              },
              process.env.JWT_SECRET || 'fallback_secret'
            );

            res.status(200).json({ 
              success: true, 
              token,
              message: 'Login successful'
            });
          } else {
            res.status(401).json({ error: 'Invalid password' });
          }
        } 
        else if (req.method === 'POST' && req.url.includes('/api/verify')) {
          // Verify token
          verifyToken(req, res, () => {
            res.status(200).json({ valid: true, user: req.user });
          });
        }
        else if (req.method === 'GET' && req.url.includes('/api/tracking-data')) {
          // Verify token first
          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            // Fetch tracking data from Supabase
            let query = supabase
              .from('tracking_events')
              .select('*')
              .order('timestamp', { ascending: false });

            // Apply filters if provided
            const { feature, action, dateFrom, dateTo } = req.query;
            
            if (feature && feature !== 'All') {
              query = query.eq('event_name', feature);
            }
            
            if (action && action !== 'All') {
              query = query.eq('event_type', action);
            }
            
            if (dateFrom) {
              query = query.gte('timestamp', dateFrom);
            }
            
            if (dateTo) {
              query = query.lte('timestamp', dateTo);
            }

            const { data, error } = await query;

            if (error) {
              console.error('Error fetching tracking data:', error);
              return res.status(500).json({ error: 'Failed to fetch tracking data' });
            }

            res.status(200).json({ data });
          });
        }
        else if (req.method === 'GET' && req.url.includes('/api/error-reports')) {
          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            // Fetch error reports from Supabase
            let query = supabase
              .from('error_reports')
              .select('*')
              .order('timestamp', { ascending: false });

            // Apply filters if provided
            const { errorType, userId, questionId } = req.query;
            
            if (errorType && errorType !== '') {
              query = query.eq('error_type', errorType);
            }
            
            if (userId && userId !== '') {
              query = query.eq('user_id', userId);
            }
            
            if (questionId && questionId !== '') {
              query = query.eq('question_id', questionId);
            }

            const { data, error } = await query;

            if (error) {
              console.error('Error fetching error reports:', error);
              return res.status(500).json({ error: 'Failed to fetch error reports' });
            }

            res.status(200).json({ data });
          });
        }
        else if (req.method === 'DELETE' && req.url.includes('/api/error-reports/')) {
          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            // Extract ID from URL
            const parts = req.url.split('/');
            const errorId = parts[parts.length - 1];

            // Delete error report from Supabase
            const { error } = await supabase
              .from('error_reports')
              .delete()
              .eq('id', errorId);

            if (error) {
              console.error('Error deleting error report:', error);
              return res.status(500).json({ error: 'Failed to delete error report' });
            }

            res.status(200).json({ success: true, message: 'Error report deleted successfully' });
          });
        }
        else if (req.method === 'GET' && req.url.includes('/api/store-items')) {
          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            // Fetch store items from Supabase
            let query = supabase
              .from('store_items')
              .select('*')
              .order('item_name');

            // Apply filters if provided
            const { itemType, search } = req.query;
            
            if (itemType && itemType !== '') {
              query = query.eq('item_type', itemType);
            }
            
            if (search && search !== '') {
              query = query.ilike('item_name', `%${search}%`);
            }

            const { data, error } = await query;

            if (error) {
              console.error('Error fetching store items:', error);
              return res.status(500).json({ error: 'Failed to fetch store items' });
            }

            res.status(200).json({ data });
          });
        }
        else if (req.method === 'PUT' && req.url.includes('/api/store-items/')) {
          // Validation rules for store item
          const validationRules = [
            body('item_key')
              .trim()
              .isLength({ min: 1, max: 50 })
              .withMessage('Item key must be between 1 and 50 characters')
              .matches(/^[a-zA-Z0-9_-]+$/)
              .withMessage('Item key can only contain letters, numbers, hyphens, and underscores'),
              
            body('item_name')
              .trim()
              .isLength({ min: 1, max: 100 })
              .withMessage('Item name must be between 1 and 100 characters'),
              
            body('item_type')
              .isIn(['powerup', 'theme', 'feature'])
              .withMessage('Item type must be powerup, theme, or feature'),
              
            body('base_price')
              .isInt({ min: 0 })
              .withMessage('Base price must be a non-negative integer'),
              
            body('discount_percentage')
              .optional()
              .isInt({ min: 0, max: 100 })
              .withMessage('Discount percentage must be between 0 and 100')
          ];

          // Run validation
          for (const rule of validationRules) {
            await rule.run(req);
          }
          
          const errors = validationResult(req);
          if (!errors.isEmpty()) {
            return res.status(400).json({
              error: 'Validation failed',
              details: errors.array()
            });
          }

          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            // Extract ID from URL
            const parts = req.url.split('/');
            const itemId = parts[parts.length - 1];

            const updateData = req.body;

            // Update store item in Supabase
            const { data, error } = await supabase
              .from('store_items')
              .update(updateData)
              .eq('id', itemId)
              .select();

            if (error) {
              console.error('Error updating store item:', error);
              return res.status(500).json({ error: 'Failed to update store item' });
            }

            res.status(200).json({ success: true, data: data[0], message: 'Store item updated successfully' });
          });
        }
        else if (req.method === 'DELETE' && req.url.includes('/api/store-items/')) {
          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            // Extract ID from URL
            const parts = req.url.split('/');
            const itemId = parts[parts.length - 1];

            // Delete store item from Supabase
            const { error } = await supabase
              .from('store_items')
              .delete()
              .eq('id', itemId);

            if (error) {
              console.error('Error deleting store item:', error);
              return res.status(500).json({ error: 'Failed to delete store item' });
            }

            res.status(200).json({ success: true, message: 'Store item deleted successfully' });
          });
        }
        else if (req.method === 'POST' && req.url.includes('/api/store-items')) {
          // Validation rules for store item
          const validationRules = [
            body('item_key')
              .trim()
              .isLength({ min: 1, max: 50 })
              .withMessage('Item key must be between 1 and 50 characters')
              .matches(/^[a-zA-Z0-9_-]+$/)
              .withMessage('Item key can only contain letters, numbers, hyphens, and underscores'),
              
            body('item_name')
              .trim()
              .isLength({ min: 1, max: 100 })
              .withMessage('Item name must be between 1 and 100 characters'),
              
            body('item_type')
              .isIn(['powerup', 'theme', 'feature'])
              .withMessage('Item type must be powerup, theme, or feature'),
              
            body('base_price')
              .isInt({ min: 0 })
              .withMessage('Base price must be a non-negative integer'),
              
            body('discount_percentage')
              .optional()
              .isInt({ min: 0, max: 100 })
              .withMessage('Discount percentage must be between 0 and 100')
          ];

          // Run validation
          for (const rule of validationRules) {
            await rule.run(req);
          }
          
          const errors = validationResult(req);
          if (!errors.isEmpty()) {
            return res.status(400).json({
              error: 'Validation failed',
              details: errors.array()
            });
          }

          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            const newItemData = req.body;

            // Insert new store item to Supabase
            const { data, error } = await supabase
              .from('store_items')
              .insert([newItemData])
              .select();

            if (error) {
              console.error('Error adding store item:', error);
              return res.status(500).json({ error: 'Failed to add store item' });
            }

            res.status(200).json({ success: true, data: data[0], message: 'Store item added successfully' });
          });
        }
        else if (req.method === 'GET' && req.url.includes('/api/messages')) {
          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            // Fetch messages from Supabase
            let query = supabase
              .from('messages')
              .select('*')
              .order('created_at', { ascending: false });

            // Apply search filter if provided
            const { search } = req.query;
            
            if (search && search !== '') {
              query = query.or(`title.ilike.%${search}%,content.ilike.%${search}%`);
            }

            const { data, error } = await query;

            if (error) {
              console.error('Error fetching messages:', error);
              return res.status(500).json({ error: 'Failed to fetch messages' });
            }

            res.status(200).json({ data });
          });
        }
        else if (req.method === 'PUT' && req.url.includes('/api/messages/')) {
          // Validation rules for message
          const validationRules = [
            body('title')
              .trim()
              .isLength({ min: 1, max: 200 })
              .withMessage('Title must be between 1 and 200 characters'),
              
            body('content')
              .trim()
              .isLength({ min: 1, max: 5000 })
              .withMessage('Content must be between 1 and 5000 characters'),
              
            body('expiration_date')
              .isISO8601()
              .withMessage('Expiration date must be a valid ISO 8601 date')
          ];

          // Run validation
          for (const rule of validationRules) {
            await rule.run(req);
          }
          
          const errors = validationResult(req);
          if (!errors.isEmpty()) {
            return res.status(400).json({
              error: 'Validation failed',
              details: errors.array()
            });
          }

          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            // Extract ID from URL
            const parts = req.url.split('/');
            const messageId = parts[parts.length - 1];

            const updateData = req.body;

            // Update message in Supabase
            const { data, error } = await supabase
              .from('messages')
              .update(updateData)
              .eq('id', messageId)
              .select();

            if (error) {
              console.error('Error updating message:', error);
              return res.status(500).json({ error: 'Failed to update message' });
            }

            res.status(200).json({ success: true, data: data[0], message: 'Message updated successfully' });
          });
        }
        else if (req.method === 'DELETE' && req.url.includes('/api/messages/')) {
          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            // Extract ID from URL
            const parts = req.url.split('/');
            const messageId = parts[parts.length - 1];

            // Delete message from Supabase
            const { error } = await supabase
              .from('messages')
              .delete()
              .eq('id', messageId);

            if (error) {
              console.error('Error deleting message:', error);
              return res.status(500).json({ error: 'Failed to delete message' });
            }

            res.status(200).json({ success: true, message: 'Message deleted successfully' });
          });
        }
        else if (req.method === 'POST' && req.url.includes('/api/messages')) {
          // Validation rules for message
          const validationRules = [
            body('title')
              .trim()
              .isLength({ min: 1, max: 200 })
              .withMessage('Title must be between 1 and 200 characters'),
              
            body('content')
              .trim()
              .isLength({ min: 1, max: 5000 })
              .withMessage('Content must be between 1 and 5000 characters'),
              
            body('expiration_date')
              .isISO8601()
              .withMessage('Expiration date must be a valid ISO 8601 date')
          ];

          // Run validation
          for (const rule of validationRules) {
            await rule.run(req);
          }
          
          const errors = validationResult(req);
          if (!errors.isEmpty()) {
            return res.status(400).json({
              error: 'Validation failed',
              details: errors.array()
            });
          }

          verifyToken(req, res, async () => {
            // Verify the user has admin role
            if (req.user.role !== 'admin') {
              return res.status(403).json({ error: 'Access denied. Admin role required.' });
            }

            const newMessageData = req.body;

            // Insert new message to Supabase
            const { data, error } = await supabase
              .from('messages')
              .insert([newMessageData])
              .select();

            if (error) {
              console.error('Error adding message:', error);
              return res.status(500).json({ error: 'Failed to add message' });
            }

            res.status(200).json({ success: true, data: data[0], message: 'Message added successfully' });
          });
        }
        else if (req.method === 'POST' && req.url.includes('/api/logout')) {
          verifyToken(req, res, () => {
            res.status(200).json({ success: true, message: 'Logout successful' });
          });
        }
        else if (req.method === 'GET' && req.url.includes('/api/health')) {
          res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
        }
        else {
          res.status(404).json({ error: 'API endpoint not found' });
        }
      } catch (error) {
        console.error('Unhandled error:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    });
  });
}

export const config = {
  api: {
    bodyParser: {
      sizeLimit: '10mb',
    },
  },
};