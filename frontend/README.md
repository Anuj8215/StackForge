# Speaksy Authenticator Frontend

The client-side application for the Speaksy Authenticator TOTP-based authentication system.

## Overview

This React application provides the user interface for managing and viewing TOTP authentication codes. It features a responsive design with modern animations and a security-focused aesthetic.

## Features

- **User Authentication**: Login and registration system
- **Dashboard**: View all your TOTP authentication services in one place
- **Real-time TOTP Codes**: Codes update automatically with visual countdown
- **Service Management**: Add and remove authentication services
- **Responsive Design**: Works on mobile and desktop devices

## Technologies

- **React**: UI library
- **React Router**: Client-side routing
- **Axios**: API communication
- **React Circular Progressbar**: Visual countdown for TOTP codes
- **Modern CSS**: Custom styling with animations

## Getting Started

### Installation

```bash
# Install dependencies
npm install
```

### Development

```bash
# Start development server
npm start
```

This runs the app in development mode. Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

### Production Build

```bash
# Create production build
npm run build
```

This builds the app for production to the `build` folder, optimized for the best performance with minified files and hashed filenames.

## Project Structure

```
frontend/
├── public/              # Static files
│   └── assets/          # Images and other assets
├── src/                 # Source code
│   ├── components/      # React components
│   │   ├── Auth/        # Authentication components
│   │   └── Dashboard/   # Dashboard components
│   ├── services/        # API services
│   ├── utils/           # Utility functions
│   ├── App.jsx          # Main App component
│   ├── App.css          # Global styles
│   └── index.jsx        # Application entry point
└── package.json         # Dependencies and scripts
```

## Key Components

### Authentication

- **Login.jsx**: User login form
- **Register.jsx**: User registration form
- **Auth.css**: Styling for auth components

### Dashboard

- **Dashboard.jsx**: Main dashboard view
- **TOTPCard.jsx**: Component to display TOTP code for a service
- **AddServiceModal.jsx**: Modal for adding new services

## API Integration

The frontend communicates with the backend using Axios. The main services are:

- **auth.jsx**: Authentication and service management API calls

## Security Features

- **JWT Token Management**: Stored in memory (not in localStorage)
- **Protected Routes**: Prevents unauthorized access to the dashboard
- **Authentication Middleware**: Ensures API requests are authenticated
- **Code Expiry**: Visual indication of code validity

## Customization

The UI is built with a modular component structure and clean CSS, making it easy to customize colors, fonts, and layouts. The primary styling file is `App.css`.

## Learn More

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app). You can learn more about React in the [React documentation](https://reactjs.org/).
