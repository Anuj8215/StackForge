const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const connectDb = require('./utils/db');
require('dotenv').config();

async function seedUsers() {
    try {
        await connectDb(process.env.MONGO_URI);

        const sampleUsers = [
            { username: 'testuser', password: 'password123' },
            { username: 'admin', password: 'admin123' }
        ];

        for (const userData of sampleUsers) {
            const existingUser = await User.findOne({ username: userData.username });
            if (existingUser) {
                console.log(`User ${userData.username} already exists, skipping.`);
                continue;
            }

            const hashedPassword = await bcrypt.hash(userData.password, 10);
            const user = new User({
                username: userData.username,
                password: hashedPassword,
                services: []
            });

            await user.save();
            console.log(`User ${userData.username} created successfully.`);
        }

        console.log('Seeding completed.');
        await mongoose.connection.close();
    } catch (error) {
        console.error('Error seeding users:', error);
        process.exit(1);
    }
}

if (require.main === module) {
    seedUsers();
}

module.exports = seedUsers;