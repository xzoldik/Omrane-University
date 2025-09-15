const fs = require('fs').promises;
const path = require('path');

class FileStorage {
    constructor() {
        this.dataDir = path.join(__dirname, '..', 'data');
    }

    async readFile(filename) {
        try {
            const filePath = path.join(this.dataDir, filename);
            const data = await fs.readFile(filePath, 'utf8');
            return JSON.parse(data);
        } catch (error) {
            console.error(`Error reading ${filename}:`, error);
            throw new Error(`Failed to read ${filename}`);
        }
    }

    async writeFile(filename, data) {
        try {
            const filePath = path.join(this.dataDir, filename);
            await fs.writeFile(filePath, JSON.stringify(data, null, 2), 'utf8');
            return true;
        } catch (error) {
            console.error(`Error writing ${filename}:`, error);
            throw new Error(`Failed to write ${filename}`);
        }
    }

    // Users operations
    async getUsers() {
        return await this.readFile('users.json');
    }

    async saveUsers(users) {
        return await this.writeFile('users.json', users);
    }

    // Courses operations
    async getCourses() {
        return await this.readFile('courses.json');
    }

    async saveCourses(courses) {
        return await this.writeFile('courses.json', courses);
    }

    // Enrollments operations
    async getEnrollments() {
        return await this.readFile('enrollments.json');
    }

    async saveEnrollments(enrollments) {
        return await this.writeFile('enrollments.json', enrollments);
    }

    // Payments operations
    async getPayments() {
        return await this.readFile('payments.json');
    }

    async savePayments(payments) {
        return await this.writeFile('payments.json', payments);
    }

    // Generate unique ID
    generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    }
}

module.exports = new FileStorage();