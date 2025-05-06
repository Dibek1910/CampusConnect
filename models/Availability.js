import mongoose from "mongoose";

/**
 * @swagger
 * components:
 *   schemas:
 *     Availability:
 *       type: object
 *       required:
 *         - faculty
 *         - day
 *         - startTime
 *         - endTime
 *       properties:
 *         _id:
 *           type: string
 *           description: Auto-generated MongoDB ID
 *         faculty:
 *           type: string
 *           description: Reference to Faculty model
 *         day:
 *           type: string
 *           enum: [Monday, Tuesday, Wednesday, Thursday, Friday]
 *         startTime:
 *           type: string
 *           pattern: '^([01]\d|2[0-3]):([0-5]\d)$'
 *           example: '10:00'
 *         endTime:
 *           type: string
 *           pattern: '^([01]\d|2[0-3]):([0-5]\d)$'
 *           example: '12:00'
 *         isBooked:
 *           type: boolean
 *           default: false
 *         isActive:
 *           type: boolean
 *           default: true
 *         createdAt:
 *           type: string
 *           format: date-time
 */
const availabilitySchema = new mongoose.Schema(
  {
    faculty: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Faculty",
      required: true,
    },
    day: {
      type: String,
      enum: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      required: true,
    },
    startTime: {
      type: String,
      required: [true, "Please provide start time in HH:MM format"],
      match: [
        /^([01]\d|2[0-3]):([0-5]\d)$/,
        "Please provide time in HH:MM format",
      ],
    },
    endTime: {
      type: String,
      required: [true, "Please provide end time in HH:MM format"],
      match: [
        /^([01]\d|2[0-3]):([0-5]\d)$/,
        "Please provide time in HH:MM format",
      ],
    },
    isBooked: {
      type: Boolean,
      default: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

availabilitySchema.pre("save", function (next) {
  const start = new Date(`1970-01-01T${this.startTime}:00`);
  const end = new Date(`1970-01-01T${this.endTime}:00`);

  if (end <= start) {
    return next(new Error("End time must be after start time"));
  }
  next();
});

availabilitySchema.index(
  { faculty: 1, day: 1, startTime: 1 },
  { unique: true }
);

const Availability = mongoose.model("Availability", availabilitySchema);

export default Availability;
