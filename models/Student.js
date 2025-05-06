import mongoose from "mongoose";

/**
 * @swagger
 * components:
 *   schemas:
 *     Student:
 *       type: object
 *       required:
 *         - user
 *         - name
 *         - registrationNumber
 *         - course
 *         - branch
 *         - currentYear
 *         - currentSemester
 *         - phoneNumber
 *       properties:
 *         _id:
 *           type: string
 *           description: Auto-generated MongoDB ID
 *         user:
 *           type: string
 *           description: Reference to User model
 *         name:
 *           type: string
 *           description: Full name of the student
 *         registrationNumber:
 *           type: string
 *           description: Unique registration number
 *         course:
 *           type: string
 *           description: Course name (e.g., B.Tech)
 *         branch:
 *           type: string
 *           description: Branch name (e.g., Computer Science)
 *         currentYear:
 *           type: integer
 *           minimum: 1
 *           maximum: 5
 *         currentSemester:
 *           type: integer
 *           minimum: 1
 *           maximum: 10
 *         phoneNumber:
 *           type: string
 *           pattern: '^\d{10}$'
 *         appointments:
 *           type: array
 *           items:
 *             type: string
 *             description: Reference to Appointment model
 *         createdAt:
 *           type: string
 *           format: date-time
 */
const studentSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    name: {
      type: String,
      required: [true, "Please provide your full name"],
      trim: true,
    },
    registrationNumber: {
      type: String,
      required: [true, "Please provide registration number"],
      unique: true,
      trim: true,
    },
    course: {
      type: String,
      required: [true, "Please provide course name"],
    },
    branch: {
      type: String,
      required: [true, "Please provide branch name"],
    },
    currentYear: {
      type: Number,
      required: [true, "Please provide current year"],
      min: 1,
      max: 5,
    },
    currentSemester: {
      type: Number,
      required: [true, "Please provide current semester"],
      min: 1,
      max: 10,
    },
    phoneNumber: {
      type: String,
      required: [true, "Please provide phone number"],
      match: [/^\d{10}$/, "Please provide a valid 10-digit phone number"],
    },
    appointments: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Appointment",
      },
    ],
  },
  {
    timestamps: true,
  }
);

const Student = mongoose.model("Student", studentSchema);

export default Student;
