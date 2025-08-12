"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const path_1 = __importDefault(require("path"));
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// Serve static files from the public directory
app.use(express_1.default.static('public'));
// Redirect route
app.get('/donate', (req, res) => {
    res.redirect(301, 'https://tikkie.me/pay/hrl9k9g0h7o7u207ih6o');
});
// Serve the HTML page (optional, if you want to keep the redirect message)
app.get('/donate-page', (req, res) => {
    res.sendFile(path_1.default.join(__dirname, 'public', 'donate.html'));
});
// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
//# sourceMappingURL=donate.js.map