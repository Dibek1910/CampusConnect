import mongoose from "mongoose";

/**
 * @swagger
 * components:
 *   schemas:
 *     Faculty:
 *       type: object
 *       required:
 *         - user
 *         - name
 *         - phoneNumber
 *         - department
 *         - facultyId
 *       properties:
 *         _id:
 *           type: string
 *           description: Auto-generated MongoDB ID
 *         user:
 *           type: string
 *           description: Reference to User model
 *         facultyId:
 *           type: string
 *           description: Unique faculty identifier
 *         name:
 *           type: string
 *           description: Full name of the faculty
 *         phoneNumber:
 *           type: string
 *           pattern: '^\d{10}$'
 *         department:
 *           type: string
 *           description: Reference to Department model
 *         availabilities:
 *           type: array
 *           items:
 *             type: string
 *             description: Reference to Availability model
 *         appointments:
 *           type: array
 *           items:
 *             type: string
 *             description: Reference to Appointment model
 *         createdAt:
 *           type: string
 *           format: date-time
 */
const facultySchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    facultyId: {
      type: String,
      unique: true,
      required: [true, "Please provide faculty ID"],
      trim: true,
    },
    name: {
      type: String,
      required: [true, "Please provide your full name"],
      trim: true,
    },
    phoneNumber: {
      type: String,
      required: [true, "Please provide phone number"],
      match: [/^\d{10}$/, "Please provide a valid 10-digit phone number"],
    },
    department: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Department",
      required: [true, "Please provide department"],
    },
    availabilities: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Availability",
      },
    ],
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

const Faculty = mongoose.model("Faculty", facultySchema);

export default Faculty;
