const express = require('express');
const fileStorage = require('../utils/fileStorage');
const router = express.Router();

// Login endpoint
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email and password are required'
            });
        }

        // Get users from storage
        const usersData = await fileStorage.getUsers();
        const user = usersData.users.find(u => u.email === email && u.password === password);

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }

        // Store user in session
        req.session.user = {
            id: user.id,
            email: user.email,
            role: user.role,
            name: user.name,
            studentId: user.studentId || null
        };

        res.json({
            success: true,
            message: 'Login successful',
            user: {
                id: user.id,
                email: user.email,
                role: user.role,
                name: user.name,
                studentId: user.studentId || null
            }
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Login failed'
        });
    }
});

// Logout endpoint
router.post('/logout', (req, res) => {
    try {
        req.session.destroy((err) => {
            if (err) {
                return res.status(500).json({
                    success: false,
                    message: 'Logout failed'
                });
            }

            res.json({
                success: true,
                message: 'Logout successful'
            });
        });
    } catch (error) {
        console.error('Logout error:', error);
        res.status(500).json({
            success: false,
            message: 'Logout failed'
        });
    }
});

// Get current user (check session)
router.get('/me', (req, res) => {
    if (!req.session.user) {
        return res.status(401).json({
            success: false,
            message: 'Not authenticated'
        });
    }

    res.json({
        success: true,
        user: req.session.user
    });
});

// Register new student (admin only)
router.post('/register', async (req, res) => {
    try {
        // Check if user is authenticated and is admin
        if (!req.session.user || req.session.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const { email, password, name, studentId } = req.body;

        if (!email || !password || !name || !studentId) {
            return res.status(400).json({
                success: false,
                message: 'All fields are required'
            });
        }

        // Get users from storage
        const usersData = await fileStorage.getUsers();

        // Check if email or studentId already exists
        const existingUser = usersData.users.find(u => u.email === email || u.studentId === studentId);
        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: 'Email or Student ID already exists'
            });
        }

        // Create new student
        const newStudent = {
            id: fileStorage.generateId(),
            email,
            password,
            role: 'student',
            name,
            studentId,
            createdAt: new Date().toISOString()
        };

        usersData.users.push(newStudent);
        await fileStorage.saveUsers(usersData);

        res.status(201).json({
            success: true,
            message: 'Student registered successfully',
            student: {
                id: newStudent.id,
                email: newStudent.email,
                name: newStudent.name,
                studentId: newStudent.studentId,
                role: newStudent.role
            }
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            message: 'Registration failed'
        });
    }
});

// Self-register new student (public)
router.post('/self-register', async (req, res) => {
    try {
        const { email, password, name, studentId } = req.body;

        if (!email || !password || !name || !studentId) {
            return res.status(400).json({
                success: false,
                message: 'All fields are required'
            });
        }

        const usersData = await fileStorage.getUsers();
        const existingUser = usersData.users.find(u => u.email === email || u.studentId === studentId);
        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: 'Email or Student ID already exists'
            });
        }

        const newStudent = {
            id: fileStorage.generateId(),
            email,
            password,
            role: 'student',
            name,
            studentId,
            createdAt: new Date().toISOString()
        };

        usersData.users.push(newStudent);
        await fileStorage.saveUsers(usersData);

        // Auto-login the newly registered student
        req.session.user = {
            id: newStudent.id,
            email: newStudent.email,
            role: newStudent.role,
            name: newStudent.name,
            studentId: newStudent.studentId
        };

        res.status(201).json({
            success: true,
            message: 'Registration successful',
            user: req.session.user
        });
    } catch (error) {
        console.error('Self-Registration error:', error);
        res.status(500).json({
            success: false,
            message: 'Registration failed'
        });
    }
});

module.exports = router;