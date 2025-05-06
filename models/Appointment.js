import mongoose from "mongoose";

/**
 * @swagger
 * components:
 *   schemas:
 *     Appointment:
 *       type: object
 *       required:
 *         - student
 *         - faculty
 *         - date
 *         - startTime
 *         - endTime
 *         - purpose
 *         - purposeCategory
 *       properties:
 *         _id:
 *           type: string
 *           description: Auto-generated MongoDB ID
 *         student:
 *           type: string
 *           description: Reference to Student model
 *         faculty:
 *           type: string
 *           description: Reference to Faculty model
 *         availability:
 *           type: string
 *           description: Reference to Availability model (optional for direct requests)
 *         date:
 *           type: string
 *           format: date
 *         startTime:
 *           type: string
 *           pattern: '^([01]\d|2[0-3]):([0-5]\d)$'
 *           example: '10:00'
 *         endTime:
 *           type: string
 *           pattern: '^([01]\d|2[0-3]):([0-5]\d)$'
 *           example: '11:00'
 *         duration:
 *           type: number
 *           description: Duration in minutes (for direct requests)
 *           enum: [15, 30, 45, 60]
 *         purpose:
 *           type: string
 *           maxLength: 200
 *         purposeCategory:
 *           type: string
 *           enum: [Academic, Personal, Project, Other]
 *           description: Category of appointment purpose
 *         customPurposeText:
 *           type: string
 *           description: Additional details for purpose (optional)
 *         status:
 *           type: string
 *           enum: [pending, accepted, rejected, cancelled, completed]
 *           default: pending
 *         cancelledBy:
 *           type: string
 *           enum: [student, faculty, null]
 *           default: null
 *         cancelReason:
 *           type: string
 *         isDirectRequest:
 *           type: boolean
 *           description: Whether this is a direct request or slot booking
 *           default: false
 *         createdAt:
 *           type: string
 *           format: date-time
 */
const appointmentSchema = new mongoose.Schema(
  {
    student: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Student",
      required: true,
    },
    faculty: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Faculty",
      required: true,
    },
    availability: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Availability",
    },
    date: {
      type: Date,
      required: [true, "Please provide appointment date"],
      validate: {
        validator: function (date) {
          const day = date.getDay();
          return day >= 1 && day <= 5;
        },
        message:
          "Appointments can only be scheduled on weekdays (Monday to Friday)",
      },
    },
    startTime: {
      type: String,
      required: [true, "Please provide start time in HH:MM format"],
      match: [
        /^([01]\d|2[0-3]):([0-5]\d)$/,
        "Please provide time in HH:MM format",
      ],
      validate: {
        validator: function (time) {
          const [hours, minutes] = time.split(":").map(Number);
          return (
            (hours > 9 || (hours === 9 && minutes >= 0)) &&
            (hours < 18 || (hours === 18 && minutes === 0))
          );
        },
        message:
          "Appointments can only be scheduled between 9:00 AM and 6:00 PM",
      },
    },
    endTime: {
      type: String,
      required: [true, "Please provide end time in HH:MM format"],
      match: [
        /^([01]\d|2[0-3]):([0-5]\d)$/,
        "Please provide time in HH:MM format",
      ],
    },
    duration: {
      type: Number,
      enum: [15, 30, 45, 60],
    },
    purpose: {
      type: String,
      required: [true, "Please provide purpose of appointment"],
      maxlength: [200, "Purpose cannot be more than 200 characters"],
    },
    purposeCategory: {
      type: String,
      required: [true, "Please provide purpose category"],
      enum: ["Academic", "Personal", "Project", "Other"],
    },
    customPurposeText: {
      type: String,
      maxlength: [
        200,
        "Custom purpose text cannot be more than 200 characters",
      ],
    },
    status: {
      type: String,
      enum: ["pending", "accepted", "rejected", "cancelled", "completed"],
      default: "pending",
    },
    cancelledBy: {
      type: String,
      enum: ["student", "faculty", null],
      default: null,
    },
    cancelReason: {
      type: String,
      maxlength: [200, "Cancel reason cannot be more than 200 characters"],
    },
    isDirectRequest: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

appointmentSchema.pre("save", function (next) {
  if (this.isDirectRequest && !this.duration) {
    return next(new Error("Direct appointment requests must include duration"));
  }

  const start = new Date(`1970-01-01T${this.startTime}:00`);
  const end = new Date(`1970-01-01T${this.endTime}:00`);

  if (end <= start) {
    return next(new Error("End time must be after start time"));
  }

  next();
});

const Appointment = mongoose.model("Appointment", appointmentSchema);

export default Appointment;
