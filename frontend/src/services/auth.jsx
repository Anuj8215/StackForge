import axios from "axios";
import { getAuthToken } from "../utils/auth.jsx";

// Use environment variables
const API_URL = `${import.meta.env.VITE_API_URL || "http://localhost:4000/api"}/auth`;

// Configure axios to use auth token
axios.interceptors.request.use(
  (config) => {
    const token = getAuthToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Auth API calls
export const register = async (username, password) => {
  try {
    console.log("Making registration request to:", `${API_URL}/register`);
    const response = await axios.post(`${API_URL}/register`, {
      username,
      password,
    });
    console.log("Registration successful:", response.data);
    return response.data;
  } catch (error) {
    console.error("Registration API error:", error);
    if (error.response) {

      throw new Error(error.response.data.error || 'Registration failed');
    } else if (error.request) {

      throw new Error('No response from server. Please check your connection.');
    } else {

      throw new Error('Error setting up the request. Please try again.');
    }
  }
};

export const login = async (username, password) => {
  const response = await axios.post(`${API_URL}/login`, { username, password });
  return response.data;
};

export const getUser = async () => {
  const response = await axios.get(`${API_URL}/user`);
  return response.data.user;
};

// TOTP Service API calls
export const getServices = async () => {
  const response = await axios.get(`${API_URL}/services`);
  return response.data;
};

export const registerService = async (name, secret, issuer = "") => {
  const response = await axios.post(`${API_URL}/register-service`, {
    name,
    secret,
    issuer,
  });
  return response.data;
};

export const registerServiceScan = async (otpauth_url) => {
  const response = await axios.post(`${API_URL}/register-service-scan`, {
    otpauth_url,
  });
  return response.data;
};

export const deleteService = async (serviceId) => {
  const response = await axios.delete(`${API_URL}/services/${serviceId}`);
  return response.data;
};

export const verifyCode = async (serviceId, token) => {
  const response = await axios.post(`${API_URL}/verify`, {
    serviceId,
    token,
  });
  return response.data;
};
