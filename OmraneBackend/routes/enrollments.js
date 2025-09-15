const express = require('express');
const fileStorage = require('../utils/fileStorage');
const router = express.Router();

// Get all enrollments (admin only)
router.get('/', async (req, res) => {
    try {
        // Check if user is authenticated and is admin
        if (!req.session.user || req.session.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const enrollmentsData = await fileStorage.getEnrollments();
        const coursesData = await fileStorage.getCourses();
        const usersData = await fileStorage.getUsers();

        const enrichedEnrollments = enrollmentsData.enrollments.map(enrollment => {
            const course = coursesData.courses.find(c => c.id === enrollment.courseId);
            const student = usersData.users.find(u => u.id === enrollment.studentId && u.role === 'student');

            return {
                id: enrollment.id,
                studentId: enrollment.studentId,
                studentName: student ? student.name : 'Unknown Student',
                studentNumber: student ? student.studentId : 'Unknown',
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
            enrollments: enrichedEnrollments
        });

    } catch (error) {
        console.error('Get enrollments error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch enrollments'
        });
    }
});

// Enroll student in course
router.post('/', async (req, res) => {
    try {
        // Check authentication
        if (!req.session.user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required'
            });
        }

        const { courseId } = req.body;
        let { studentId } = req.body;

        // If student is enrolling themselves, use their ID from session
        if (req.session.user.role === 'student') {
            studentId = req.session.user.id;
        } else if (req.session.user.role === 'admin' && !studentId) {
            return res.status(400).json({
                success: false,
                message: 'Student ID is required for admin enrollment'
            });
        }

        if (!courseId) {
            return res.status(400).json({
                success: false,
                message: 'Course ID is required'
            });
        }

        // Verify course exists
        const coursesData = await fileStorage.getCourses();
        const course = coursesData.courses.find(c => c.id === courseId);
        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // Verify student exists
        const usersData = await fileStorage.getUsers();
        const student = usersData.users.find(u => u.id === studentId && u.role === 'student');
        if (!student) {
            return res.status(404).json({
                success: false,
                message: 'Student not found'
            });
        }

        // Check if student is already enrolled
        const enrollmentsData = await fileStorage.getEnrollments();
        const existingEnrollment = enrollmentsData.enrollments.find(
            e => e.studentId === studentId && e.courseId === courseId
        );
        if (existingEnrollment) {
            return res.status(409).json({
                success: false,
                message: 'Student is already enrolled in this course'
            });
        }

        // Check course capacity
        const currentEnrollments = enrollmentsData.enrollments.filter(e => e.courseId === courseId).length;
        if (currentEnrollments >= course.maxStudents) {
            return res.status(400).json({
                success: false,
                message: 'Course is full'
            });
        }

        // Create enrollment
        const newEnrollment = {
            id: fileStorage.generateId(),
            studentId,
            courseId,
            enrollmentDate: new Date().toISOString(),
            status: 'enrolled',
            grade: null
        };

        enrollmentsData.enrollments.push(newEnrollment);
        await fileStorage.saveEnrollments(enrollmentsData);

        res.status(201).json({
            success: true,
            message: 'Enrollment successful',
            enrollment: {
                id: newEnrollment.id,
                studentName: student.name,
                courseName: course.name,
                courseNumber: course.courseNumber,
                enrollmentDate: newEnrollment.enrollmentDate,
                status: newEnrollment.status
            }
        });

    } catch (error) {
        console.error('Enrollment error:', error);
        res.status(500).json({
            success: false,
            message: 'Enrollment failed'
        });
    }
});

// Get student's enrollments
router.get('/my-courses', async (req, res) => {
    try {
        // Check if user is authenticated and is a student
        if (!req.session.user || req.session.user.role !== 'student') {
            return res.status(403).json({
                success: false,
                message: 'Student access required'
            });
        }

        const studentId = req.session.user.id;
        const enrollmentsData = await fileStorage.getEnrollments();
        const coursesData = await fileStorage.getCourses();

        const studentEnrollments = enrollmentsData.enrollments
            .filter(enrollment => enrollment.studentId === studentId)
            .map(enrollment => {
                const course = coursesData.courses.find(c => c.id === enrollment.courseId);
                return {
                    enrollmentId: enrollment.id,
                    courseId: enrollment.courseId,
                    courseName: course ? course.name : 'Unknown Course',
                    courseNumber: course ? course.courseNumber : 'Unknown',
                    startDate: course ? course.startDate : null,
                    endDate: course ? course.endDate : null,
                    price: course ? course.price : 0,
                    credits: course ? course.credits : 0,
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
            message: 'Failed to fetch enrollments'
        });
    }
});

// Unenroll from course (students can unenroll themselves, admins can unenroll any student)
router.delete('/:enrollmentId', async (req, res) => {
    try {
        // Check authentication
        if (!req.session.user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required'
            });
        }

        const { enrollmentId } = req.params;
        const enrollmentsData = await fileStorage.getEnrollments();
        const enrollmentIndex = enrollmentsData.enrollments.findIndex(e => e.id === enrollmentId);

        if (enrollmentIndex === -1) {
            return res.status(404).json({
                success: false,
                message: 'Enrollment not found'
            });
        }

        const enrollment = enrollmentsData.enrollments[enrollmentIndex];

        // Check authorization
        if (req.session.user.role === 'student' && req.session.user.id !== enrollment.studentId) {
            return res.status(403).json({
                success: false,
                message: 'You can only unenroll from your own courses'
            });
        }

        // Get course and student info for response
        const coursesData = await fileStorage.getCourses();
        const usersData = await fileStorage.getUsers();
        const course = coursesData.courses.find(c => c.id === enrollment.courseId);
        const student = usersData.users.find(u => u.id === enrollment.studentId);

        // Remove enrollment
        enrollmentsData.enrollments.splice(enrollmentIndex, 1);
        await fileStorage.saveEnrollments(enrollmentsData);

        // Also remove related payments
        const paymentsData = await fileStorage.getPayments();
        paymentsData.payments = paymentsData.payments.filter(
            payment => !(payment.studentId === enrollment.studentId && payment.courseId === enrollment.courseId)
        );
        await fileStorage.savePayments(paymentsData);

        res.json({
            success: true,
            message: 'Unenrollment successful',
            unenrolledFrom: {
                courseName: course ? course.name : 'Unknown Course',
                courseNumber: course ? course.courseNumber : 'Unknown',
                studentName: student ? student.name : 'Unknown Student'
            }
        });

    } catch (error) {
        console.error('Unenrollment error:', error);
        res.status(500).json({
            success: false,
            message: 'Unenrollment failed'
        });
    }
});

// Update enrollment status/grade (admin only)
router.put('/:enrollmentId', async (req, res) => {
    try {
        // Check if user is authenticated and is admin
        if (!req.session.user || req.session.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const { enrollmentId } = req.params;
        const { status, grade } = req.body;

        const enrollmentsData = await fileStorage.getEnrollments();
        const enrollmentIndex = enrollmentsData.enrollments.findIndex(e => e.id === enrollmentId);

        if (enrollmentIndex === -1) {
            return res.status(404).json({
                success: false,
                message: 'Enrollment not found'
            });
        }

        // Update enrollment
        if (status) {
            enrollmentsData.enrollments[enrollmentIndex].status = status;
        }
        if (grade !== undefined) {
            enrollmentsData.enrollments[enrollmentIndex].grade = grade;
        }

        await fileStorage.saveEnrollments(enrollmentsData);

        res.json({
            success: true,
            message: 'Enrollment updated successfully',
            enrollment: enrollmentsData.enrollments[enrollmentIndex]
        });

    } catch (error) {
        console.error('Update enrollment error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update enrollment'
        });
    }
});

module.exports = router;