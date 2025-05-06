import mongoose from "mongoose";

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       required:
 *         - email
 *         - role
 *       properties:
 *         _id:
 *           type: string
 *           description: Auto-generated MongoDB ID
 *         email:
 *           type: string
 *           format: email
 *           description: Must be a valid email address (students must use muj.manipal.edu domain)
 *         role:
 *           type: string
 *           enum: [student, faculty, admin]
 *           default: student
 *         isVerified:
 *           type: boolean
 *           default: false
 *         createdAt:
 *           type: string
 *           format: date-time
 *       example:
 *         email: john.doe@muj.manipal.edu
 *         role: student
 *         isVerified: false
 */
const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, "Please provide email address"],
    unique: true,
    trim: true,
    lowercase: true,
    match: [
      /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/,
      "Please provide a valid email",
    ],
  },
  role: {
    type: String,
    enum: ["student", "faculty", "admin"],
    default: "student",
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

userSchema.methods.isValidDomain = function () {
  if (this.role === "student" && !this.email.endsWith("@muj.manipal.edu")) {
    return false;
  }

  return true;
};

const User = mongoose.model("User", userSchema);

export default User;
