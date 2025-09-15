const express = require('express');
const fileStorage = require('../utils/fileStorage');
const router = express.Router();

// Get all courses (accessible to both students and admins)
router.get('/', async (req, res) => {
    try {
        // Check authentication
        if (!req.session.user) {
            return res.status(401).json({
                success: false,
                message: 'Authentication required'
            });
        }

        const coursesData = await fileStorage.getCourses();

        res.json({
            success: true,
            courses: coursesData.courses
        });

    } catch (error) {
        console.error('Get courses error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch courses'
        });
    }
});

// Get course by ID
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
        const coursesData = await fileStorage.getCourses();
        const course = coursesData.courses.find(c => c.id === id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        res.json({
            success: true,
            course
        });

    } catch (error) {
        console.error('Get course error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch course'
        });
    }
});

// Create new course (admin only)
router.post('/', async (req, res) => {
    try {
        // Check if user is authenticated and is admin
        if (!req.session.user || req.session.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const { courseNumber, name, startDate, endDate, price, description, credits, maxStudents } = req.body;

        // Validate required fields (allow price=0 but require it to be present)
        if (!name || !startDate || !endDate || price === undefined || price === null || price === '') {
            return res.status(400).json({
                success: false,
                message: 'Name, start date, end date, and price are required'
            });
        }

        const coursesData = await fileStorage.getCourses();

        // Generate a course number if not provided (e.g., CRS-0001 style)
        let finalCourseNumber = (courseNumber || '').toString().trim();
        if (!finalCourseNumber) {
            const prefix = 'CRS-';
            // find max numeric suffix from existing CRS-
            const maxNum = coursesData.courses
                .map(c => c.courseNumber)
                .filter(n => typeof n === 'string' && n.startsWith(prefix))
                .map(n => parseInt(n.replace(prefix, ''), 10))
                .filter(n => !isNaN(n))
                .reduce((a, b) => Math.max(a, b), 0);
            const nextNum = (maxNum || 0) + 1;
            finalCourseNumber = `${prefix}${nextNum.toString().padStart(4, '0')}`;
        } else {
            // Ensure uniqueness if provided by client
            const existingCourse = coursesData.courses.find(c => c.courseNumber === finalCourseNumber);
            if (existingCourse) {
                return res.status(409).json({
                    success: false,
                    message: 'Course number already exists'
                });
            }
        }

        // Create new course
        // Normalize dates to ISO if possible
        const start = new Date(startDate);
        const end = new Date(endDate);
        if (isNaN(start.getTime()) || isNaN(end.getTime())) {
            return res.status(400).json({
                success: false,
                message: 'Invalid start or end date'
            });
        }

        const newCourse = {
            id: fileStorage.generateId(),
            courseNumber: finalCourseNumber,
            name,
            startDate: start.toISOString().slice(0, 10),
            endDate: end.toISOString().slice(0, 10),
            price: parseFloat(price),
            description: description || '',
            credits: credits || 3,
            maxStudents: maxStudents || 30,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        coursesData.courses.push(newCourse);
        await fileStorage.saveCourses(coursesData);

        res.status(201).json({
            success: true,
            message: 'Course created successfully',
            course: newCourse
        });

    } catch (error) {
        console.error('Create course error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create course'
        });
    }
});

// Update course (admin only)
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
        const { courseNumber, name, startDate, endDate, price, description, credits, maxStudents } = req.body;

        // Validate required fields (courseNumber can be generated/preserved if missing)
        if (!name || !startDate || !endDate || price === undefined || price === null || price === '') {
            return res.status(400).json({
                success: false,
                message: 'Name, start date, end date, and price are required'
            });
        }

        const coursesData = await fileStorage.getCourses();
        const courseIndex = coursesData.courses.findIndex(c => c.id === id);

        if (courseIndex === -1) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // Resolve final course number:
        // - If provided and non-empty, ensure uniqueness (excluding current course)
        // - If missing/empty: preserve existing if present; otherwise generate new like POST
        let finalCourseNumber = (courseNumber || '').toString().trim();
        if (finalCourseNumber) {
            const existingCourse = coursesData.courses.find(
                c => c.id !== id && c.courseNumber === finalCourseNumber
            );
            if (existingCourse) {
                return res.status(409).json({
                    success: false,
                    message: 'Course number already exists'
                });
            }
        } else {
            const current = coursesData.courses[courseIndex];
            if (current.courseNumber && current.courseNumber.toString().trim()) {
                finalCourseNumber = current.courseNumber;
            } else {
                const prefix = 'CRS-';
                const maxNum = coursesData.courses
                    .map(c => c.courseNumber)
                    .filter(n => typeof n === 'string' && n.startsWith(prefix))
                    .map(n => parseInt(n.replace(prefix, ''), 10))
                    .filter(n => !isNaN(n))
                    .reduce((a, b) => Math.max(a, b), 0);
                const nextNum = (maxNum || 0) + 1;
                finalCourseNumber = `${prefix}${nextNum.toString().padStart(4, '0')}`;
            }
        }

        // Normalize dates
        const start = new Date(startDate);
        const end = new Date(endDate);
        if (isNaN(start.getTime()) || isNaN(end.getTime())) {
            return res.status(400).json({
                success: false,
                message: 'Invalid start or end date'
            });
        }

        // Update course
        coursesData.courses[courseIndex] = {
            ...coursesData.courses[courseIndex],
            courseNumber: finalCourseNumber,
            name,
            startDate: start.toISOString().slice(0, 10),
            endDate: end.toISOString().slice(0, 10),
            price: parseFloat(price),
            description: description || coursesData.courses[courseIndex].description,
            credits: credits || coursesData.courses[courseIndex].credits,
            maxStudents: maxStudents || coursesData.courses[courseIndex].maxStudents,
            updatedAt: new Date().toISOString()
        };

        await fileStorage.saveCourses(coursesData);

        res.json({
            success: true,
            message: 'Course updated successfully',
            course: coursesData.courses[courseIndex]
        });

    } catch (error) {
        console.error('Update course error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update course'
        });
    }
});

// Delete course (admin only)
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
        const coursesData = await fileStorage.getCourses();
        const courseIndex = coursesData.courses.findIndex(c => c.id === id);

        if (courseIndex === -1) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        // Check if there are enrollments for this course
        const enrollmentsData = await fileStorage.getEnrollments();
        const hasEnrollments = enrollmentsData.enrollments.some(e => e.courseId === id);

        if (hasEnrollments) {
            return res.status(400).json({
                success: false,
                message: 'Cannot delete course with existing enrollments'
            });
        }

        // Remove course
        const deletedCourse = coursesData.courses.splice(courseIndex, 1)[0];
        await fileStorage.saveCourses(coursesData);

        res.json({
            success: true,
            message: 'Course deleted successfully',
            deletedCourse: {
                id: deletedCourse.id,
                courseNumber: deletedCourse.courseNumber,
                name: deletedCourse.name
            }
        });

    } catch (error) {
        console.error('Delete course error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete course'
        });
    }
});

// Get enrolled students for a course (admin only)
router.get('/:id/students', async (req, res) => {
    try {
        // Check if user is authenticated and is admin
        if (!req.session.user || req.session.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: 'Admin access required'
            });
        }

        const { id } = req.params;

        // Check if course exists
        const coursesData = await fileStorage.getCourses();
        const course = coursesData.courses.find(c => c.id === id);

        if (!course) {
            return res.status(404).json({
                success: false,
                message: 'Course not found'
            });
        }

        const enrollmentsData = await fileStorage.getEnrollments();
        const usersData = await fileStorage.getUsers();

        const enrolledStudents = enrollmentsData.enrollments
            .filter(enrollment => enrollment.courseId === id)
            .map(enrollment => {
                const student = usersData.users.find(u => u.id === enrollment.studentId && u.role === 'student');
                return {
                    enrollmentId: enrollment.id,
                    studentId: enrollment.studentId,
                    studentName: student ? student.name : 'Unknown Student',
                    studentEmail: student ? student.email : 'Unknown Email',
                    studentNumber: student ? student.studentId : 'Unknown',
                    enrollmentDate: enrollment.enrollmentDate,
                    status: enrollment.status,
                    grade: enrollment.grade
                };
            });

        res.json({
            success: true,
            course: {
                id: course.id,
                courseNumber: course.courseNumber,
                name: course.name
            },
            enrolledStudents
        });

    } catch (error) {
        console.error('Get course students error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch enrolled students'
        });
    }
});

module.exports = router;