const express = require('express');
const fileStorage = require('../utils/fileStorage');
const router = express.Router();

// Get all students (admin only)
router.get('/', async (req, res) => {
    try {
        // Check if user is authenticated and is admin
        if (!req.session.user || req.session.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const usersData = await fileStorage.getUsers();
        const students = usersData.users
            .filter(user => user.role === 'student')
            .map(student => ({
                id: student.id,
                name: student.name,
                email: student.email,
                studentId: student.studentId,
                createdAt: student.createdAt
            }));

        res.json({
            success: true,
            students
        });

    } catch (error) {
        console.error('Get students error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch students'
        });
    }
});

// Get student by ID (admin only)
router.get('/:id', async (req, res) => {
    try {
        // Check if user is authenticated and is admin
        if (!req.session.user || req.session.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const { id } = req.params;
        const usersData = await fileStorage.getUsers();
        const student = usersData.users.find(user => user.id === id && user.role === 'student');

        if (!student) {
            return res.status(404).json({
                success: false,
                message: 'Student not found'
            });
        }

        res.json({
            success: true,
            student: {
                id: student.id,
                name: student.name,
                email: student.email,
                studentId: student.studentId,
                createdAt: student.createdAt
            }
        });

    } catch (error) {
        console.error('Get student error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch student'
        });
    }
});

// Update student (admin only)
router.put('/:id', async (req, res) => {
    try {
        // Check if user is authenticated and is admin
        if (!req.session.user || req.session.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const { id } = req.params;
        const { name, email, studentId } = req.body;

        if (!name || !email || !studentId) {
            return res.status(400).json({
                success: false,
                message: 'Name, email, and student ID are required'
            });
        }

        const usersData = await fileStorage.getUsers();
        const studentIndex = usersData.users.findIndex(user => user.id === id && user.role === 'student');

        if (studentIndex === -1) {
            return res.status(404).json({
                success: false,
                message: 'Student not found'
            });
        }

        // Check if email or studentId already exists (excluding current student)
        const existingUser = usersData.users.find(u =>
            u.id !== id && (u.email === email || u.studentId === studentId)
        );
        if (existingUser) {
            return res.status(409).json({
                success: false,
                message: 'Email or Student ID already exists'
            });
        }

        // Update student
        usersData.users[studentIndex] = {
            ...usersData.users[studentIndex],
            name,
            email,
            studentId,
            updatedAt: new Date().toISOString()
        };

        await fileStorage.saveUsers(usersData);

        res.json({
            success: true,
            message: 'Student updated successfully',
            student: {
                id: usersData.users[studentIndex].id,
                name: usersData.users[studentIndex].name,
                email: usersData.users[studentIndex].email,
                studentId: usersData.users[studentIndex].studentId,
                createdAt: usersData.users[studentIndex].createdAt,
                updatedAt: usersData.users[studentIndex].updatedAt
            }
        });

    } catch (error) {
        console.error('Update student error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update student'
        });
    }
});

// Delete student (admin only)
router.delete('/:id', async (req, res) => {
    try {
        // Check if user is authenticated and is admin
        if (!req.session.user || req.session.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const { id } = req.params;
        const usersData = await fileStorage.getUsers();
        const studentIndex = usersData.users.findIndex(user => user.id === id && user.role === 'student');

        if (studentIndex === -1) {
            return res.status(404).json({
                success: false,
                message: 'Student not found'
            });
        }

        // Remove student from users
        const deletedStudent = usersData.users.splice(studentIndex, 1)[0];
        await fileStorage.saveUsers(usersData);

        // Also remove related enrollments and payments
        const enrollmentsData = await fileStorage.getEnrollments();
        enrollmentsData.enrollments = enrollmentsData.enrollments.filter(
            enrollment => enrollment.studentId !== id
        );
        await fileStorage.saveEnrollments(enrollmentsData);

        const paymentsData = await fileStorage.getPayments();
        paymentsData.payments = paymentsData.payments.filter(
            payment => payment.studentId !== id
        );
        await fileStorage.savePayments(paymentsData);

        res.json({
            success: true,
            message: 'Student deleted successfully',
            deletedStudent: {
                id: deletedStudent.id,
                name: deletedStudent.name,
                email: deletedStudent.email,
                studentId: deletedStudent.studentId
            }
        });

    } catch (error) {
        console.error('Delete student error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete student'
        });
    }
});

// Get student enrollments (admin can view any student, students can view their own)
router.get('/:id/enrollments', async (req, res) => {
    try {
        const { id } = req.params;

        // Check authentication
        if (!req.session.user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required'
            });
        }

        // Check authorization
        if (req.session.user.role !== 'admin' && req.session.user.id !== id) {
            return res.status(403).json({
                success: false,
                message: 'Access denied'
            });
        }

        const enrollmentsData = await fileStorage.getEnrollments();
        const coursesData = await fileStorage.getCourses();

        const studentEnrollments = enrollmentsData.enrollments
            .filter(enrollment => enrollment.studentId === id)
            .map(enrollment => {
                const course = coursesData.courses.find(c => c.id === enrollment.courseId);
                return {
                    id: enrollment.id,
                    courseId: enrollment.courseId,
                    courseName: course ? course.name : 'Unknown Course',
                    courseNumber: course ? course.courseNumber : 'Unknown',
                    enrollmentDate: enrollment.enrollmentDate,
                    status: enrollment.status,
                    grade: enrollment.grade
                };
            });

        res.json({
            success: true,
            enrollments: studentEnrollments
        });

    } catch (error) {
        console.error('Get student enrollments error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch student enrollments'
        });
    }
});

module.exports = router;