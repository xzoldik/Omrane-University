const express = require('express');
const fileStorage = require('../utils/fileStorage');
const router = express.Router();

// Get all payments (admin only)
router.get('/', async (req, res) => {
    try {
        // Check if user is authenticated and is admin
        if (!req.session.user || req.session.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const paymentsData = await fileStorage.getPayments();
        const coursesData = await fileStorage.getCourses();
        const usersData = await fileStorage.getUsers();

        const enrichedPayments = paymentsData.payments.map(payment => {
            const course = coursesData.courses.find(c => c.id === payment.courseId);
            const student = usersData.users.find(u => u.id === payment.studentId && u.role === 'student');

            return {
                id: payment.id,
                studentId: payment.studentId,
                studentName: student ? student.name : 'Unknown Student',
                studentNumber: student ? student.studentId : 'Unknown',
                courseId: payment.courseId,
                courseName: course ? course.name : 'Unknown Course',
                courseNumber: course ? course.courseNumber : 'Unknown',
                amount: payment.amount,
                paymentDate: payment.paymentDate,
                paymentMethod: payment.paymentMethod,
                status: payment.status,
                transactionId: payment.transactionId
            };
        });

        res.json({
            success: true,
            payments: enrichedPayments
        });

    } catch (error) {
        console.error('Get payments error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch payments'
        });
    }
});

// Get student's payment history
router.get('/my-payments', async (req, res) => {
    try {
        // Check if user is authenticated and is a student
        if (!req.session.user || req.session.user.role !== 'student') {
            return res.status(403).json({
                success: false,
                message: 'Student access required'
            });
        }

        const studentId = req.session.user.id;
        const paymentsData = await fileStorage.getPayments();
        const coursesData = await fileStorage.getCourses();

        const studentPayments = paymentsData.payments
            .filter(payment => payment.studentId === studentId)
            .map(payment => {
                const course = coursesData.courses.find(c => c.id === payment.courseId);
                return {
                    id: payment.id,
                    courseId: payment.courseId,
                    courseName: course ? course.name : 'Unknown Course',
                    courseNumber: course ? course.courseNumber : 'Unknown',
                    amount: payment.amount,
                    paymentDate: payment.paymentDate,
                    paymentMethod: payment.paymentMethod,
                    status: payment.status,
                    transactionId: payment.transactionId
                };
            });

        res.json({
            success: true,
            payments: studentPayments
        });

    } catch (error) {
        console.error('Get student payments error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch payment history'
        });
    }
});

// Get student's outstanding fees
router.get('/my-fees', async (req, res) => {
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
        const paymentsData = await fileStorage.getPayments();

        // Get student's enrollments
        const studentEnrollments = enrollmentsData.enrollments.filter(e => e.studentId === studentId);

        const outstandingFees = [];
        let totalOwed = 0;

        for (const enrollment of studentEnrollments) {
            const course = coursesData.courses.find(c => c.id === enrollment.courseId);
            if (!course) continue;

            // Calculate total paid for this course
            const coursePaid = paymentsData.payments
                .filter(p => p.studentId === studentId && p.courseId === enrollment.courseId && p.status === 'completed')
                .reduce((sum, payment) => sum + payment.amount, 0);

            const amountOwed = course.price - coursePaid;

            if (amountOwed > 0) {
                outstandingFees.push({
                    courseId: course.id,
                    courseName: course.name,
                    courseNumber: course.courseNumber,
                    totalFee: course.price,
                    paidAmount: coursePaid,
                    amountOwed: amountOwed,
                    enrollmentDate: enrollment.enrollmentDate
                });
                totalOwed += amountOwed;
            }
        }

        res.json({
            success: true,
            outstandingFees,
            totalOwed,
            summary: {
                totalCourses: studentEnrollments.length,
                coursesWithOutstandingFees: outstandingFees.length,
                totalAmountOwed: totalOwed
            }
        });

    } catch (error) {
        console.error('Get student fees error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch outstanding fees'
        });
    }
});

// Make a payment
router.post('/', async (req, res) => {
    try {
        // Check authentication
        if (!req.session.user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required'
            });
        }

        const { courseId, amount, paymentMethod } = req.body;
        let { studentId } = req.body;

        // If student is making payment for themselves, use their ID from session
        if (req.session.user.role === 'student') {
            studentId = req.session.user.id;
        } else if (req.session.user.role === 'admin' && !studentId) {
            return res.status(400).json({
                success: false,
                message: 'Student ID is required for admin payment entry'
            });
        }

        if (!courseId || !amount || !paymentMethod) {
            return res.status(400).json({
                success: false,
                message: 'Course ID, amount, and payment method are required'
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

        // Verify student exists and is enrolled in the course
        const usersData = await fileStorage.getUsers();
        const student = usersData.users.find(u => u.id === studentId && u.role === 'student');
        if (!student) {
            return res.status(404).json({
                success: false,
                message: 'Student not found'
            });
        }

        const enrollmentsData = await fileStorage.getEnrollments();
        const enrollment = enrollmentsData.enrollments.find(
            e => e.studentId === studentId && e.courseId === courseId
        );
        if (!enrollment) {
            return res.status(400).json({
                success: false,
                message: 'Student is not enrolled in this course'
            });
        }

        // Check if payment amount is valid
        const paymentsData = await fileStorage.getPayments();
        const totalPaid = paymentsData.payments
            .filter(p => p.studentId === studentId && p.courseId === courseId && p.status === 'completed')
            .reduce((sum, payment) => sum + payment.amount, 0);

        const remainingAmount = course.price - totalPaid;
        const paymentAmount = parseFloat(amount);

        if (paymentAmount <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Payment amount must be greater than 0'
            });
        }

        if (paymentAmount > remainingAmount) {
            return res.status(400).json({
                success: false,
                message: `Payment amount exceeds remaining balance. Remaining: $${remainingAmount.toFixed(2)}`
            });
        }

        // Create payment record
        const newPayment = {
            id: fileStorage.generateId(),
            studentId,
            courseId,
            amount: paymentAmount,
            paymentDate: new Date().toISOString(),
            paymentMethod,
            status: 'completed', // In a real system, this would be 'pending' until processed
            transactionId: `TXN${Date.now()}`
        };

        paymentsData.payments.push(newPayment);
        await fileStorage.savePayments(paymentsData);

        const newTotalPaid = totalPaid + paymentAmount;
        const newRemainingAmount = course.price - newTotalPaid;

        res.status(201).json({
            success: true,
            message: 'Payment processed successfully',
            payment: {
                id: newPayment.id,
                courseName: course.name,
                courseNumber: course.courseNumber,
                studentName: student.name,
                amount: paymentAmount,
                paymentDate: newPayment.paymentDate,
                paymentMethod: newPayment.paymentMethod,
                status: newPayment.status,
                transactionId: newPayment.transactionId,
                remainingBalance: newRemainingAmount
            }
        });

    } catch (error) {
        console.error('Payment processing error:', error);
        res.status(500).json({
            success: false,
            message: 'Payment processing failed'
        });
    }
});

// Get payment by ID
router.get('/:id', async (req, res) => {
    try {
        // Check authentication
        if (!req.session.user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required'
            });
        }

        const { id } = req.params;
        const paymentsData = await fileStorage.getPayments();
        const payment = paymentsData.payments.find(p => p.id === id);

        if (!payment) {
            return res.status(404).json({
                success: false,
                message: 'Payment not found'
            });
        }

        // Check authorization - students can only view their own payments
        if (req.session.user.role === 'student' && req.session.user.id !== payment.studentId) {
            return res.status(403).json({
                success: false,
                message: 'Access denied'
            });
        }

        // Get course and student info
        const coursesData = await fileStorage.getCourses();
        const usersData = await fileStorage.getUsers();
        const course = coursesData.courses.find(c => c.id === payment.courseId);
        const student = usersData.users.find(u => u.id === payment.studentId);

        res.json({
            success: true,
            payment: {
                id: payment.id,
                studentId: payment.studentId,
                studentName: student ? student.name : 'Unknown Student',
                courseId: payment.courseId,
                courseName: course ? course.name : 'Unknown Course',
                courseNumber: course ? course.courseNumber : 'Unknown',
                amount: payment.amount,
                paymentDate: payment.paymentDate,
                paymentMethod: payment.paymentMethod,
                status: payment.status,
                transactionId: payment.transactionId
            }
        });

    } catch (error) {
        console.error('Get payment error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch payment'
        });
    }
});

// Update payment status (admin only)
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
        const { status } = req.body;

        if (!status || !['pending', 'completed', 'failed', 'refunded'].includes(status)) {
            return res.status(400).json({
                success: false,
                message: 'Valid status is required (pending, completed, failed, refunded)'
            });
        }

        const paymentsData = await fileStorage.getPayments();
        const paymentIndex = paymentsData.payments.findIndex(p => p.id === id);

        if (paymentIndex === -1) {
            return res.status(404).json({
                success: false,
                message: 'Payment not found'
            });
        }

        // Update payment status
        paymentsData.payments[paymentIndex].status = status;
        await fileStorage.savePayments(paymentsData);

        res.json({
            success: true,
            message: 'Payment status updated successfully',
            payment: paymentsData.payments[paymentIndex]
        });

    } catch (error) {
        console.error('Update payment error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update payment status'
        });
    }
});

module.exports = router;