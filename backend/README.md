# Speaksy Authenticator Backend

The server-side component of the Speaksy Authenticator TOTP-based authentication system.

## Overview

This backend provides the API services for the Speaksy Authenticator application, handling user authentication, service management, and TOTP code generation and verification.

## Technologies Used

- **Node.js & Express**: Server framework
- **MongoDB with Mongoose**: Database ORM
- **JWT**: Authentication and authorization
- **Speakeasy**: TOTP code generation and verification
- **Bcrypt**: Password hashing

## Setup Instructions

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Environment Configuration**:
   Create a `.env` file with the following variables:
   ```
   PORT=4000
   NODE_ENV=development
   MONGO_URI=your_mongodb_connection_string
   JWT_SECRET=your_jwt_secret
   JWT_EXPIRATION=7d
   TOTP_ISSUER=SpeaksyAuth
   TOTP_DIGITS=6
   TOTP_STEP=30
   ```

3. **Start the server**:
   ```bash
   # Development mode (with nodemon)
   npm run dev
   
   # Production mode
   npm start
   ```

## API Documentation

### Authentication Endpoints

#### `POST /api/auth/register`
Register a new user account.

**Request Body**:
```json
{
  "username": "user123",
  "password": "securePassword123"
}
```

**Response**:
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "username": "user123"
  }
}
```

#### `POST /api/auth/login`
Login with existing credentials.

**Request Body**:
```json
{
  "username": "user123",
  "password": "securePassword123"
}
```

**Response**:
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "username": "user123"
  }
}
```

### TOTP Service Endpoints

#### `POST /api/auth/register-service`
Register a new service manually.

**Headers**:
```
Authorization: Bearer jwt_token_here
```

**Request Body**:
```json
{
  "name": "Service Name",
  "secret": "BASE32SECRET",
  "issuer": "Optional Issuer"
}
```

#### `POST /api/auth/register-service-scan`
Register a service via OTP URL.

**Headers**:
```
Authorization: Bearer jwt_token_here
```

**Request Body**:
```json
{
  "otpauth_url": "otpauth://totp/Example:user@example.com?secret=BASE32SECRET&issuer=Example"
}
```

#### `GET /api/auth/services`
Get all services with current TOTP codes.

**Headers**:
```
Authorization: Bearer jwt_token_here
```

#### `DELETE /api/auth/services/:id`
Delete a service.

**Headers**:
```
Authorization: Bearer jwt_token_here
```

## Project Structure

```
backend/
├── middleware/          # Authentication middleware
│   └── auth.middleware.js
├── models/              # Database models
│   └── User.js
├── routes/              # API route definitions
│   └── auth.routes.js
├── utils/               # Utility functions
│   └── db.js
├── server.js            # Main application entry
├── package.json
└── README.md
```

## Database Schema Details

### User Model
```javascript
{
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true }, // Hashed with bcrypt
  createdAt: { type: Date, default: Date.now },
  services: [
    {
      name: { type: String, required: true },
      secret: { type: String, required: true }, // Encrypted TOTP secret
      issuer: { type: String },
      createdAt: { type: Date, default: Date.now }
    }
  ]
}
```

## API Implementation Details

### Authentication Flow
1. User submits credentials
2. Server validates credentials
3. On success, generates JWT token with user ID
4. Token is returned to client
5. Client includes token in Authorization header for subsequent requests

### TOTP Implementation
- Secret keys are generated using cryptographically secure random bytes
- Base32 encoding is used for secret keys (per RFC specifications)
- Default period is 30 seconds
- 6-digit codes are generated
- Time drift tolerance is configured to allow for slight time differences

## Security Implementation

### Authentication Security
- Password hashing using bcrypt with proper salt rounds
- JWT tokens with appropriate expiration time
- HTTP-only cookies option for token storage
- CORS protection with proper origin validation
- Rate limiting on authentication endpoints

### Data Security
- Encrypted storage of TOTP secrets
- Input validation and sanitization
- MongoDB injection prevention
- No sensitive data in logs or error messages

### API Security
- Authentication middleware on protected routes
- Request validation
- Proper error handling
- Secure HTTP headers implementation

## Development

To contribute to this backend:
1. Follow the main project contribution guidelines
2. Ensure all API endpoints maintain proper authentication
3. Write tests for new functionality
4. Maintain error handling and validation standards

### Testing
```bash
# Run tests
npm test

# Run tests with coverage
npm run test:coverage
```

### Code Structure Best Practices
- Follow the MVC pattern (routes, controllers, models)
- Use middleware for cross-cutting concerns
- Keep business logic separate from route handlers
- Use async/await for asynchronous operations
- Implement proper error handling

### Deployment Considerations
- Set NODE_ENV to 'production'
- Use process managers like PM2
- Configure proper logging
- Set up monitoring
- Implement database backups
