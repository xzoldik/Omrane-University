# University Management System API

A RESTful API for a university class registration system built with Node.js and Express.js.

## Features

- **Authentication**: Student and Admin login/logout using sessions
- **Student Management**: Admin can manage students and view student lists
- **Course Management**: Admin can add, edit, and delete courses
- **Student Enrollment**: Students can register for classes
- **Financial Management**: Payment entry and fee tracking
- **Course Lists**: View enrolled students and registered courses

## Technology Stack

- **Backend**: Node.js with Express.js
- **Storage**: JSON files for data persistence
- **Authentication**: Express sessions (no JWT)
- **CORS**: Enabled for cross-origin requests

## Setup Instructions

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Start the Server**
   ```bash
   npm start
   # or
   npm run dev
   ```

3. **Access the API**
   - Server runs on: `http://localhost:3000`
   - Health check: `http://localhost:3000/api/health`

## Default Users

### Admin User
- **Email**: `admin@university.edu`
- **Password**: `admin123`
- **Role**: `admin`

### Student Users
- **Email**: `john.doe@student.edu`
- **Password**: `student123`
- **Role**: `student`
- **Student ID**: `STU001`

- **Email**: `jane.smith@student.edu`
- **Password**: `student123`
- **Role**: `student`
- **Student ID**: `STU002`

## API Endpoints

### Authentication

#### POST `/api/auth/login`
Login with email and password.

**Request Body:**
```json
{
  "email": "admin@university.edu",
  "password": "admin123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": "admin1",
    "email": "admin@university.edu",
    "role": "admin",
    "name": "Admin User"
  }
}
```

#### POST `/api/auth/logout`
Logout current user.

#### GET `/api/auth/me`
Get current user information.

#### POST `/api/auth/register`
Register new student (Admin only).

**Request Body:**
```json
{
  "email": "newstudent@student.edu",
  "password": "password123",
  "name": "New Student",
  "studentId": "STU003"
}
```

### Students (Admin Access Required)

#### GET `/api/students`
Get all students.

#### GET `/api/students/:id`
Get student by ID.

#### PUT `/api/students/:id`
Update student information.

#### DELETE `/api/students/:id`
Delete student and related data.

#### GET `/api/students/:id/enrollments`
Get student's enrollments.

### Courses

#### GET `/api/courses`
Get all courses (Students and Admins).

#### GET `/api/courses/:id`
Get course by ID.

#### POST `/api/courses` (Admin only)
Create new course.

**Request Body:**
```json
{
  "courseNumber": "CS102",
  "name": "Data Structures",
  "startDate": "2025-09-01",
  "endDate": "2025-12-15",
  "price": 1600.00,
  "description": "Introduction to data structures and algorithms",
  "credits": 4,
  "maxStudents": 25
}
```

#### PUT `/api/courses/:id` (Admin only)
Update course.

#### DELETE `/api/courses/:id` (Admin only)
Delete course (if no enrollments exist).

#### GET `/api/courses/:id/students` (Admin only)
Get enrolled students for a course.

### Enrollments

#### GET `/api/enrollments` (Admin only)
Get all enrollments.

#### POST `/api/enrollments`
Enroll in a course.

**Request Body (Student):**
```json
{
  "courseId": "course1"
}
```

**Request Body (Admin enrolling student):**
```json
{
  "studentId": "student1",
  "courseId": "course1"
}
```

#### GET `/api/enrollments/my-courses` (Students only)
Get current user's enrolled courses.

#### DELETE `/api/enrollments/:enrollmentId`
Unenroll from course.

#### PUT `/api/enrollments/:enrollmentId` (Admin only)
Update enrollment status/grade.

### Payments

#### GET `/api/payments` (Admin only)
Get all payments.

#### GET `/api/payments/my-payments` (Students only)
Get current user's payment history.

#### GET `/api/payments/my-fees` (Students only)
Get outstanding fees.

#### POST `/api/payments`
Make a payment.

**Request Body (Student):**
```json
{
  "courseId": "course1",
  "amount": 1500.00,
  "paymentMethod": "credit_card"
}
```

**Request Body (Admin processing payment):**
```json
{
  "studentId": "student1",
  "courseId": "course1",
  "amount": 1500.00,
  "paymentMethod": "credit_card"
}
```

#### GET `/api/payments/:id`
Get payment by ID.

#### PUT `/api/payments/:id` (Admin only)
Update payment status.

## Data Models

### User
```json
{
  "id": "string",
  "email": "string",
  "password": "string",
  "role": "admin|student",
  "name": "string",
  "studentId": "string (students only)",
  "createdAt": "ISO Date"
}
```

### Course
```json
{
  "id": "string",
  "courseNumber": "string",
  "name": "string",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "price": "number",
  "description": "string",
  "credits": "number",
  "maxStudents": "number",
  "createdAt": "ISO Date",
  "updatedAt": "ISO Date"
}
```

### Enrollment
```json
{
  "id": "string",
  "studentId": "string",
  "courseId": "string",
  "enrollmentDate": "ISO Date",
  "status": "enrolled|completed|dropped",
  "grade": "string|null"
}
```

### Payment
```json
{
  "id": "string",
  "studentId": "string",
  "courseId": "string",
  "amount": "number",
  "paymentDate": "ISO Date",
  "paymentMethod": "credit_card|debit_card|bank_transfer|cash|check",
  "status": "pending|completed|failed|refunded",
  "transactionId": "string"
}
```

## Response Format

All API responses follow this format:

**Success Response:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error description"
}
```

## Error Codes

- `400` - Bad Request (validation errors)
- `401` - Unauthorized (authentication required)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (duplicate data)
- `429` - Too Many Requests (rate limiting)
- `500` - Internal Server Error

## Security Features

- Session-based authentication
- Role-based access control
- Input validation and sanitization
- Rate limiting
- CORS protection

## File Structure

```
├── server.js              # Main server file
├── package.json           # Dependencies and scripts
├── data/                  # JSON data storage
│   ├── users.json        # User accounts
│   ├── courses.json      # Course catalog
│   ├── enrollments.json  # Student enrollments
│   └── payments.json     # Payment records
├── routes/               # API route handlers
│   ├── auth.js          # Authentication routes
│   ├── students.js      # Student management
│   ├── courses.js       # Course management
│   ├── enrollments.js   # Enrollment handling
│   └── payments.js      # Payment processing
├── middleware/          # Custom middleware
│   └── auth.js         # Authentication & validation
└── utils/              # Utility functions
    └── fileStorage.js  # File operations
```

## Development Notes

- Data is persisted in JSON files in the `data/` directory
- Sessions are stored in memory (will reset on server restart)
- No external database required
- Suitable for development and testing purposes
- For production, consider using a proper database and session store