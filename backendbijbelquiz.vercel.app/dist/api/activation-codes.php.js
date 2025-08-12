"use strict";
// Vercel Serverless Function: activation-codes API (replacing PHP)
// Route: /api/activation-codes.php
// Provides simple activation code verification with CORS
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = handler;
const CODES = [
    'BIJBEL2025',
    'QUIZ1234',
    'TESTCODE',
    'DEMO-0000-2025',
];
function setCors(res, origin) {
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    // Allow all origins; restrict to your domain if needed
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Requested-With');
}
function handler(req, res) {
    var _a, _b;
    setCors(res, (_a = req.headers) === null || _a === void 0 ? void 0 : _a.origin);
    if (req.method === 'OPTIONS') {
        res.status(204).end();
        return;
    }
    if (req.method !== 'GET') {
        res.status(405).json({ error: 'Method Not Allowed' });
        return;
    }
    const raw = (_b = req.query) === null || _b === void 0 ? void 0 : _b.code;
    const codeToCheck = Array.isArray(raw)
        ? raw[0]
        : typeof raw === 'string'
            ? raw
            : '';
    const normalized = (codeToCheck || '').trim().toUpperCase();
    if (normalized) {
        const valid = CODES.includes(normalized);
        res.status(200).json({ valid });
        return;
    }
    // Return list for debugging if no code was provided
    res.status(200).json({ codes: CODES });
}
//# sourceMappingURL=activation-codes.php.js.map