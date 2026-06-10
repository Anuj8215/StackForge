import React from "react";
import { Navigate } from "react-router-dom";
import { isAuthenticated } from "./auth.jsx";

// Protected route component
export const PrivateRoute = ({ children }) => {
  if (!isAuthenticated()) {
    return <Navigate to="/login" replace />;
  }
  return children;
};

// Public route component (redirects to dashboard if authenticated)
export const PublicRoute = ({ children }) => {
  if (isAuthenticated()) {
    return <Navigate to="/dashboard" replace />;
  }
  return children;
};
