const mongoose = require('mongoose');
const User = require('./models/User');
const connectDb = require('./utils/db');
require('dotenv').config();

async function listUsers() {
    try {
        await connectDb(process.env.MONGO_URI);

        const users = await User.find({}, { password: 0 }); // Exclude password for security

        console.log('Users in database:');
        users.forEach(user => {
            console.log(`- Username: ${user.username}, Services: ${user.services.length}, Created: ${user.createdAt}`);
        });

        if (users.length === 0) {
            console.log('No users found.');
        }

        await mongoose.connection.close();
    } catch (error) {
        console.error('Error listing users:', error);
        process.exit(1);
    }
}

if (require.main === module) {
    listUsers();
}

module.exports = listUsers;
