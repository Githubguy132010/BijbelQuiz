# BijbelQuiz Admin Portal

A secure, web-based admin portal for managing the BijbelQuiz application, including tracking data analysis, error reporting, store management, and message management.

## Features

- **Tracking Data Analysis**: View and analyze user engagement and feature usage
- **Error Reporting**: Monitor and manage application errors with detailed information
- **Store Management**: Manage in-app purchases, themes, and powerups
- **Message Management**: Create and manage in-app messages and announcements
- **Secure Authentication**: JWT-based authentication with rate limiting
- **Responsive Design**: Works on desktop and mobile devices

## Security Features

- JWT-based authentication with token expiration
- Rate limiting to prevent brute force attacks
- Input validation and sanitization
- Helmet.js for security headers
- Content Security Policy (CSP)
- SQL injection prevention

## Prerequisites

- Node.js (version 14 or higher)
- npm or yarn package manager

## Installation

1. Clone the repository or copy the admin portal files

2. Navigate to the admin portal directory:
```bash
cd websites/admin.bijbelquiz.app
```

3. Install dependencies:
```bash
npm install
```

4. Create a `.env` file in the root directory with the following content:
```env
# Server Configuration
PORT=3000

# JWT Secret - should be a strong, random string in production
JWT_SECRET=your_strong_jwt_secret_key_here_change_this_in_production

# Supabase Configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key_here

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,https://admin.bijbelquiz.app
```

> **Important**: Change the `JWT_SECRET` to a strong, random string in production!

## Configuration

### Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Get your Supabase URL and Service Role Key from the project settings
3. Add these to your `.env` file as `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`

### Admin User Setup

1. To set up your admin user credentials, update your `.env` file with:
   ```env
   ADMIN_USERNAME=your_admin_username
   ADMIN_PASSWORD_HASH=your_bcrypt_hashed_password
   ```
   
2. To generate a bcrypt hash for your password, you can use an online bcrypt generator or Node.js:
   ```bash
   # Install bcrypt package
   npm install -g bcryptjs
   
   # Generate hash
   node -e "console.log(require('bcryptjs').hashSync('your_password', 10));"
   ```

> **Important**: For production use, store admin credentials in a secure database rather than environment variables.

### Database Tables

The admin portal expects the following tables in your Supabase database:

1. `tracking_events` - for tracking data
2. `error_reports` - for error reports
3. `store_items` - for in-app purchase items
4. `messages` - for in-app messages

## Usage

### Development

To run the admin portal in development mode:

```bash
npm run dev
```

This will start the server with nodemon for automatic restarts on file changes.

### Production

To run the admin portal in production:

```bash
npm start
```

### Accessing the Portal

1. Start the server using one of the commands above
2. Open your browser and navigate to `http://localhost:3000` (or your configured port)
3. Login with the default credentials:
   - Username: `admin`
   - Password: `admin123`
4. You'll be redirected to the dashboard after successful authentication

> **Important**: Change the default credentials in production!

## API Endpoints

The admin portal uses the following API endpoints:

- `POST /api/login` - User authentication
- `GET /api/tracking` - Get tracking data
- `GET /api/errors` - Get error reports
- `DELETE /api/errors/:id` - Delete an error report
- `GET /api/store` - Get store items
- `POST /api/store` - Create a new store item
- `PUT /api/store/:id` - Update a store item
- `DELETE /api/store/:id` - Delete a store item
- `GET /api/messages` - Get messages
- `POST /api/messages` - Create a new message
- `PUT /api/messages/:id` - Update a message
- `DELETE /api/messages/:id` - Delete a message
- `GET /health` - Health check endpoint

## Security Best Practices

1. Always use HTTPS in production
2. Use strong, unique passwords for admin accounts
3. Regularly rotate the JWT secret
4. Limit network access to the admin portal
5. Regularly update dependencies
6. Monitor access logs for suspicious activity

## Customization

### Adding Admin Users

To add more admin users, modify the `adminUsers` array in `server.js` with bcrypt-hashed passwords:

```javascript
const bcrypt = require('bcrypt');

// To generate a hash for a new password:
const passwordHash = await bcrypt.hash('your_password', 10);
```

### Theming

The admin portal uses CSS variables for theming. You can customize colors by modifying the `:root` section in `styles.css`.

## Support

If you encounter any issues or have questions, please open an issue in the repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.