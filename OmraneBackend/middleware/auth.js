// Authentication middleware
const requireAuth = (req, res, next) => {
    if (!req.session.user) {
        return res.status(401).json({
            success: false,
            message: 'Authentication required'
        });
    }
    next();
};

// Admin authorization middleware
const requireAdmin = (req, res, next) => {
    if (!req.session.user) {
        return res.status(401).json({
            success: false,
            message: 'Authentication required'
        });
    }

    if (req.session.user.role !== 'admin') {
        return res.status(403).json({
            success: false,
            message: 'Admin access required'
        });
    }

    next();
};

// Student authorization middleware
const requireStudent = (req, res, next) => {
    if (!req.session.user) {
        return res.status(401).json({
            success: false,
            message: 'Authentication required'
        });
    }

    if (req.session.user.role !== 'student') {
        return res.status(403).json({
            success: false,
            message: 'Student access required'
        });
    }

    next();
};

// Student or Admin authorization middleware
const requireStudentOrAdmin = (req, res, next) => {
    if (!req.session.user) {
        return res.status(401).json({
            success: false,
            message: 'Authentication required'
        });
    }

    if (!['student', 'admin'].includes(req.session.user.role)) {
        return res.status(403).json({
            success: false,
            message: 'Student or admin access required'
        });
    }

    next();
};

// Validation middleware for email format
const validateEmail = (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
};

// Input validation middleware
const validateLoginInput = (req, res, next) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({
            success: false,
            message: 'Email and password are required'
        });
    }

    if (!validateEmail(email)) {
        return res.status(400).json({
            success: false,
            message: 'Invalid email format'
        });
    }

    if (password.length < 6) {
        return res.status(400).json({
            success: false,
            message: 'Password must be at least 6 characters long'
        });
    }

    next();
};

// Validation middleware for course data
const validateCourseInput = (req, res, next) => {
    const { courseNumber, name, startDate, endDate, price } = req.body;

    if (!courseNumber || !name || !startDate || !endDate || price === undefined) {
        return res.status(400).json({
            success: false,
            message: 'Course number, name, start date, end date, and price are required'
        });
    }

    // Validate dates
    const start = new Date(startDate);
    const end = new Date(endDate);

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
        return res.status(400).json({
            success: false,
            message: 'Invalid date format'
        });
    }

    if (start >= end) {
        return res.status(400).json({
            success: false,
            message: 'End date must be after start date'
        });
    }

    // Validate price
    const coursePrice = parseFloat(price);
    if (isNaN(coursePrice) || coursePrice < 0) {
        return res.status(400).json({
            success: false,
            message: 'Price must be a valid positive number'
        });
    }

    next();
};

// Validation middleware for student registration
const validateStudentInput = (req, res, next) => {
    const { email, password, name, studentId } = req.body;

    if (!email || !password || !name || !studentId) {
        return res.status(400).json({
            success: false,
            message: 'All fields are required'
        });
    }

    if (!validateEmail(email)) {
        return res.status(400).json({
            success: false,
            message: 'Invalid email format'
        });
    }

    if (password.length < 6) {
        return res.status(400).json({
            success: false,
            message: 'Password must be at least 6 characters long'
        });
    }

    if (name.trim().length < 2) {
        return res.status(400).json({
            success: false,
            message: 'Name must be at least 2 characters long'
        });
    }

    if (studentId.trim().length < 3) {
        return res.status(400).json({
            success: false,
            message: 'Student ID must be at least 3 characters long'
        });
    }

    next();
};

// Validation middleware for payment data
const validatePaymentInput = (req, res, next) => {
    const { courseId, amount, paymentMethod } = req.body;

    if (!courseId || !amount || !paymentMethod) {
        return res.status(400).json({
            success: false,
            message: 'Course ID, amount, and payment method are required'
        });
    }

    const paymentAmount = parseFloat(amount);
    if (isNaN(paymentAmount) || paymentAmount <= 0) {
        return res.status(400).json({
            success: false,
            message: 'Amount must be a valid positive number'
        });
    }

    const validPaymentMethods = ['credit_card', 'debit_card', 'bank_transfer', 'cash', 'check'];
    if (!validPaymentMethods.includes(paymentMethod)) {
        return res.status(400).json({
            success: false,
            message: 'Invalid payment method'
        });
    }

    next();
};

// Error handling middleware
const errorHandler = (err, req, res, next) => {
    console.error('Error:', err);

    // Default error
    let error = { message: err.message || 'Something went wrong!' };

    // Mongoose bad ObjectId
    if (err.name === 'CastError') {
        error.message = 'Resource not found';
        return res.status(404).json({
            success: false,
            message: error.message
        });
    }

    // Mongoose duplicate key
    if (err.code === 11000) {
        error.message = 'Duplicate field value entered';
        return res.status(400).json({
            success: false,
            message: error.message
        });
    }

    // Mongoose validation error
    if (err.name === 'ValidationError') {
        const messages = Object.values(err.errors).map(val => val.message);
        error.message = messages.join(', ');
        return res.status(400).json({
            success: false,
            message: error.message
        });
    }

    res.status(err.statusCode || 500).json({
        success: false,
        message: error.message
    });
};

// Rate limiting middleware (simple in-memory implementation)
const rateLimiter = (() => {
    const requests = new Map();
    const WINDOW_SIZE = 15 * 60 * 1000; // 15 minutes
    const MAX_REQUESTS = 100; // Max requests per window

    return (req, res, next) => {
        const clientId = req.ip || req.connection.remoteAddress;
        const now = Date.now();

        // Clean old entries
        const cutoff = now - WINDOW_SIZE;
        for (const [key, value] of requests.entries()) {
            if (value.timestamp < cutoff) {
                requests.delete(key);
            }
        }

        // Check current client
        const clientRequests = requests.get(clientId) || { count: 0, timestamp: now };

        if (clientRequests.timestamp < cutoff) {
            // Reset if outside window
            clientRequests.count = 1;
            clientRequests.timestamp = now;
        } else {
            // Increment within window
            clientRequests.count++;
        }

        requests.set(clientId, clientRequests);

        if (clientRequests.count > MAX_REQUESTS) {
            return res.status(429).json({
                success: false,
                message: 'Too many requests, please try again later'
            });
        }

        next();
    };
})();

module.exports = {
    requireAuth,
    requireAdmin,
    requireStudent,
    requireStudentOrAdmin,
    validateLoginInput,
    validateCourseInput,
    validateStudentInput,
    validatePaymentInput,
    errorHandler,
    rateLimiter
};