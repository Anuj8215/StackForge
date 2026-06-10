const mongoose = require('mongoose');
const User = require('./models/User');
const connectDb = require('./utils/db');

async function clearAllUsers() {
    try {
        // Connect to the database
        await connectDb(process.env.MONGO_URI);
        
        // Delete all users from the database
        const result = await User.deleteMany({});
        
        console.log(`Successfully deleted ${result.deletedCount} users`);
        
        // Close the database connection
        await mongoose.connection.close();
        
        return result;
    } catch (error) {
        console.error('Error clearing users:', error);
        
        // Ensure the connection is closed even if there's an error
        if (mongoose.connection.readyState === 1) {
            await mongoose.connection.close();
        }
        
        throw error;
    }
}

// Execute the function if this file is run directly
if (require.main === module) {
    clearAllUsers()
        .then(() => {
            console.log('User clearing operation completed');
            process.exit(0);
        })
        .catch((error) => {
            console.error('Failed to clear users:', error);
            process.exit(1);
        });
}

module.exports = clearAllUsers;
