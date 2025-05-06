import mongoose from "mongoose";

/**
 * @swagger
 * components:
 *   schemas:
 *     OTP:
 *       type: object
 *       required:
 *         - email
 *         - otp
 *         - purpose
 *       properties:
 *         _id:
 *           type: string
 *           description: Auto-generated MongoDB ID
 *         email:
 *           type: string
 *           format: email
 *         otp:
 *           type: string
 *           description: 6-digit OTP code
 *         purpose:
 *           type: string
 *           enum: [registration, login, profile-update]
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: OTP expires after 10 minutes
 */
const otpSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    trim: true,
    lowercase: true,
  },
  otp: {
    type: String,
    required: true,
  },
  purpose: {
    type: String,
    enum: ["registration", "login", "profile-update"],
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
    expires: 600,
  },
});

const OTP = mongoose.model("OTP", otpSchema);

export default OTP;
