const mongoose = require("mongoose");

async function connectDb(uri) {
  try {
    mongoose.set("strictQuery", false);

    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      maxIdleTimeMS: 30000,
    });

    console.log("Database connected successfully");
    return mongoose.connection;
  } catch (error) {
    console.error("Database connection failed:", error);
    throw error;
  }
}

mongoose.connection.on("error", (err) => {
  console.error(`MongoDB connection error: ${err}`);
});

mongoose.connection.on("disconnected", () => {
  console.log("MongoDB disconnected");
});

mongoose.connection.on("reconnected", () => {
  console.log("MongoDB reconnected");
});

process.on("SIGINT", async () => {
  await mongoose.connection.close();
  console.log("MongoDB connection closed due to app termination");
  process.exit(0);
});

module.exports = connectDb;
