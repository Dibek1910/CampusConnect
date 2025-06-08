import mongoose from "mongoose";

/**
 * @swagger
 * components:
 *   schemas:
 *     Availability:
 *       type: object
 *       required:
 *         - faculty
 *         - date
 *         - startTime
 *         - endTime
 *       properties:
 *         _id:
 *           type: string
 *           description: Auto-generated MongoDB ID
 *         faculty:
 *           type: string
 *           description: Reference to Faculty model
 *         date:
 *           type: string
 *           format: date
 *           description: Specific date for availability
 *         day:
 *           type: string
 *           enum: [Monday, Tuesday, Wednesday, Thursday, Friday]
 *           description: Day of the week (auto-calculated from date)
 *         startTime:
 *           type: string
 *           pattern: '^(09|1[0-7]):([0-5]\d)$'
 *           example: '10:00'
 *           description: Time between 09:00 and 17:59
 *         endTime:
 *           type: string
 *           pattern: '^(09|1[0-8]):([0-5]\d)$'
 *           example: '12:00'
 *           description: Time between 09:00 and 18:00
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
    date: {
      type: Date,
      required: [true, "Please provide availability date"],
      validate: {
        validator: (date) => {
          // Check if date is not in the past (allow today)
          const today = new Date();
          today.setHours(0, 0, 0, 0);
          const availabilityDate = new Date(date);
          availabilityDate.setHours(0, 0, 0, 0);

          // Check if it's a weekday (Monday = 1, Friday = 5)
          const dayOfWeek = availabilityDate.getDay();
          return availabilityDate >= today && dayOfWeek >= 1 && dayOfWeek <= 5;
        },
        message:
          "Availability can only be set for current or future weekdays (Monday to Friday)",
      },
    },
    day: {
      type: String,
      enum: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
    },
    startTime: {
      type: String,
      required: [true, "Please provide start time in HH:MM format"],
      match: [
        /^(09|1[0-7]):([0-5]\d)$/,
        "Start time must be between 09:00 and 17:59",
      ],
      validate: {
        validator: (time) => {
          const [hours, minutes] = time.split(":").map(Number);
          return hours >= 9 && (hours < 18 || (hours === 18 && minutes === 0));
        },
        message: "Start time must be between 9:00 AM and 6:00 PM",
      },
    },
    endTime: {
      type: String,
      required: [true, "Please provide end time in HH:MM format"],
      match: [
        /^(09|1[0-8]):([0-5]\d)$/,
        "End time must be between 09:00 and 18:00",
      ],
      validate: {
        validator: (time) => {
          const [hours, minutes] = time.split(":").map(Number);
          return hours >= 9 && (hours < 18 || (hours === 18 && minutes === 0));
        },
        message: "End time must be between 9:00 AM and 6:00 PM",
      },
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

// Pre-save middleware to set day from date and validate times
availabilitySchema.pre("save", function (next) {
  // Set day from date
  const dayNames = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];
  this.day = dayNames[this.date.getDay()];

  // Validate start and end times
  const start = new Date(`1970-01-01T${this.startTime}:00`);
  const end = new Date(`1970-01-01T${this.endTime}:00`);

  if (end <= start) {
    return next(new Error("End time must be after start time"));
  }

  // Check if the time slot is not in the past for today's date
  const now = new Date();
  const availabilityDate = new Date(this.date);

  if (availabilityDate.toDateString() === now.toDateString()) {
    const currentTime = `${now.getHours().toString().padStart(2, "0")}:${now
      .getMinutes()
      .toString()
      .padStart(2, "0")}`;
    if (this.startTime <= currentTime) {
      return next(new Error("Cannot set availability for past time slots"));
    }
  }

  next();
});

// Create compound index for faculty, date, and time to prevent overlapping slots
availabilitySchema.index(
  { faculty: 1, date: 1, startTime: 1 },
  { unique: true }
);

const Availability = mongoose.model("Availability", availabilitySchema);

export default Availability;
