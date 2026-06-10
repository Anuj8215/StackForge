require("dotenv").config();
const express = require("express");
const cors = require("cors");
const connectDb = require("./utils/db");
const authRoutes = require("./routes/auth.routes");

const app = express();

app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? process.env.FRONTEND_URL
    : ['http://localhost:5173', 'http://localhost:5174'],
  credentials: true
}));
app.use(express.json());

app.use("/api/auth", authRoutes);

app.get("/health", (req, res) => {
  res.json({ status: "ok", message: "Server is running" });
});
const startServer = async () => {
  try {
    await connectDb(process.env.MONGO_URI);

    const PORT = process.env.PORT || 4000;
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`Health check available at http://localhost:${PORT}/health`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
