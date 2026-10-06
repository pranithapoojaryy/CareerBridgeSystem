const express = require('express');
const router = express.Router();
const interviewController = require('../controllers/interviewController');

// POST /api/interview/submit
router.post('/submit', interviewController.submitInterview);

// GET /api/interview/history/:studentId
router.get('/history/:studentId', interviewController.getStudentHistory);

module.exports = router;
