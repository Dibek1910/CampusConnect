import Student from "../models/Student.js";
import Faculty from "../models/Faculty.js";
import Availability from "../models/Availability.js";
import Department from "../models/Department.js";

/**
 * @swagger
 * /api/students/profile:
 *   get:
 *     summary: Get student profile
 *     tags: [Students]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Student profile retrieved
 *       404:
 *         description: Student not found
 */
export const getStudentProfile = async (req, res) => {
  try {
    const student = await Student.findOne({ user: req.user.id })
      .select("-__v")
      .populate("user", "email isVerified");

    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    res.status(200).json({
      success: true,
      data: student,
    });
  } catch (error) {
    console.error("Get student profile error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/students/profile:
 *   put:
 *     summary: Update student profile
 *     tags: [Students]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - isOTPVerified
 *             properties:
 *               name:
 *                 type: string
 *               course:
 *                 type: string
 *               branch:
 *                 type: string
 *               currentYear:
 *                 type: integer
 *               currentSemester:
 *                 type: integer
 *               phoneNumber:
 *                 type: string
 *               isOTPVerified:
 *                 type: boolean
 *                 description: Must be true to update profile
 *     responses:
 *       200:
 *         description: Student profile updated
 *       401:
 *         description: OTP verification required
 *       404:
 *         description: Student not found
 */
export const updateStudentProfile = async (req, res) => {
  try {
    const {
      name,
      course,
      branch,
      currentYear,
      currentSemester,
      phoneNumber,
      isOTPVerified,
    } = req.body;

    if (!isOTPVerified) {
      return res.status(401).json({
        success: false,
        message: "OTP verification required for profile update",
      });
    }

    const student = await Student.findOne({ user: req.user.id });
    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    if (name) student.name = name;
    if (course) student.course = course;
    if (branch) student.branch = branch;
    if (currentYear) student.currentYear = currentYear;
    if (currentSemester) student.currentSemester = currentSemester;
    if (phoneNumber) student.phoneNumber = phoneNumber;

    await student.save();

    res.status(200).json({
      success: true,
      message: "Student profile updated successfully",
      data: student,
    });
  } catch (error) {
    console.error("Update student profile error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/students/faculty:
 *   get:
 *     summary: Get all faculty members
 *     tags: [Students]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of all faculty members
 */
export const getAllFaculty = async (req, res) => {
  try {
    const faculty = await Faculty.find()
      .populate("user", "email")
      .populate("department", "name")
      .select("-__v");

    res.status(200).json({
      success: true,
      count: faculty.length,
      data: faculty,
    });
  } catch (error) {
    console.error("Get all faculty error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/students/faculty/{facultyId}/availability:
 *   get:
 *     summary: Get faculty availability
 *     tags: [Students]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: facultyId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Faculty availability slots
 *       404:
 *         description: Faculty not found
 */
export const getFacultyAvailability = async (req, res) => {
  try {
    const { facultyId } = req.params;

    const faculty = await Faculty.findById(facultyId);
    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    const availabilities = await Availability.find({
      faculty: facultyId,
      isActive: true,
      isBooked: false,
    }).sort({ day: 1, startTime: 1 });

    res.status(200).json({
      success: true,
      count: availabilities.length,
      data: availabilities,
    });
  } catch (error) {
    console.error("Get faculty availability error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/students/departments:
 *   get:
 *     summary: Get all departments
 *     tags: [Students]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of all departments
 */
export const getAllDepartments = async (req, res) => {
  try {
    const departments = await Department.find().select("-__v");

    res.status(200).json({
      success: true,
      count: departments.length,
      data: departments,
    });
  } catch (error) {
    console.error("Get all departments error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};
