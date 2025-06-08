import Faculty from "../models/Faculty.js";
import Availability from "../models/Availability.js";

/**
 * @swagger
 * /api/faculty/profile:
 *   get:
 *     summary: Get faculty profile
 *     tags: [Faculty]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Faculty profile retrieved
 *       404:
 *         description: Faculty not found
 */
export const getFacultyProfile = async (req, res) => {
  try {
    const faculty = await Faculty.findOne({ user: req.user.id })
      .select("-__v")
      .populate("user", "email isVerified")
      .populate("department", "name");

    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    res.status(200).json({
      success: true,
      data: faculty,
    });
  } catch (error) {
    console.error("Get faculty profile error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/faculty/profile:
 *   put:
 *     summary: Update faculty profile
 *     tags: [Faculty]
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
 *               phoneNumber:
 *                 type: string
 *               isOTPVerified:
 *                 type: boolean
 *                 description: Must be true to update profile
 *     responses:
 *       200:
 *         description: Faculty profile updated
 *       401:
 *         description: OTP verification required
 *       404:
 *         description: Faculty not found
 */
export const updateFacultyProfile = async (req, res) => {
  try {
    const { name, phoneNumber, isOTPVerified } = req.body;

    if (!isOTPVerified) {
      return res.status(401).json({
        success: false,
        message: "OTP verification required for profile update",
      });
    }

    const faculty = await Faculty.findOne({ user: req.user.id });
    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    if (name) faculty.name = name;
    if (phoneNumber) faculty.phoneNumber = phoneNumber;

    await faculty.save();

    res.status(200).json({
      success: true,
      message: "Faculty profile updated successfully",
      data: faculty,
    });
  } catch (error) {
    console.error("Update faculty profile error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/faculty/availability:
 *   post:
 *     summary: Add availability slot
 *     tags: [Faculty]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - date
 *               - startTime
 *               - endTime
 *             properties:
 *               date:
 *                 type: string
 *                 format: date
 *                 description: Date for availability (must be current or future weekday)
 *               startTime:
 *                 type: string
 *                 pattern: '^(09|1[0-7]):([0-5]\d)$'
 *                 description: Start time between 09:00 and 17:59
 *               endTime:
 *                 type: string
 *                 pattern: '^(09|1[0-8]):([0-5]\d)$'
 *                 description: End time between 09:00 and 18:00
 *     responses:
 *       201:
 *         description: Availability slot added
 *       400:
 *         description: Invalid date or time, or overlapping slot
 *       404:
 *         description: Faculty not found
 */
export const addAvailabilitySlot = async (req, res) => {
  try {
    const { date, startTime, endTime } = req.body;

    const faculty = await Faculty.findOne({ user: req.user.id });
    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    // Validate date is not in the past and is a weekday
    const availabilityDate = new Date(date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    availabilityDate.setHours(0, 0, 0, 0);

    if (availabilityDate < today) {
      return res.status(400).json({
        success: false,
        message: "Cannot set availability for past dates",
      });
    }

    const dayOfWeek = availabilityDate.getDay();
    if (dayOfWeek === 0 || dayOfWeek === 6) {
      return res.status(400).json({
        success: false,
        message: "Availability can only be set for weekdays (Monday to Friday)",
      });
    }

    // Check for overlapping slots on the same date
    const existingSlots = await Availability.find({
      faculty: faculty._id,
      date: availabilityDate,
      isActive: true,
    });

    const newStart = new Date(`1970-01-01T${startTime}:00`);
    const newEnd = new Date(`1970-01-01T${endTime}:00`);

    for (const slot of existingSlots) {
      const existingStart = new Date(`1970-01-01T${slot.startTime}:00`);
      const existingEnd = new Date(`1970-01-01T${slot.endTime}:00`);

      if (
        (newStart >= existingStart && newStart < existingEnd) ||
        (newEnd > existingStart && newEnd <= existingEnd) ||
        (newStart <= existingStart && newEnd >= existingEnd)
      ) {
        return res.status(400).json({
          success: false,
          message: "Time slot overlaps with existing availability",
        });
      }
    }

    const availability = await Availability.create({
      faculty: faculty._id,
      date: availabilityDate,
      startTime,
      endTime,
      isBooked: false,
      isActive: true,
    });

    faculty.availabilities.push(availability._id);
    await faculty.save();

    res.status(201).json({
      success: true,
      message: "Availability slot added successfully",
      data: availability,
    });
  } catch (error) {
    console.error("Add availability slot error:", error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "A slot with the same date and start time already exists",
      });
    }

    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/faculty/availability/{availabilityId}:
 *   put:
 *     summary: Update availability slot
 *     tags: [Faculty]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: availabilityId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               date:
 *                 type: string
 *                 format: date
 *               startTime:
 *                 type: string
 *                 pattern: '^(09|1[0-7]):([0-5]\d)$'
 *               endTime:
 *                 type: string
 *                 pattern: '^(09|1[0-8]):([0-5]\d)$'
 *               isActive:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Availability slot updated
 *       400:
 *         description: Cannot update booked slot or invalid data
 *       403:
 *         description: Not authorized
 *       404:
 *         description: Availability slot not found
 */
export const updateAvailabilitySlot = async (req, res) => {
  try {
    const { availabilityId } = req.params;
    const { date, startTime, endTime, isActive } = req.body;

    const faculty = await Faculty.findOne({ user: req.user.id });
    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    const availability = await Availability.findById(availabilityId);
    if (!availability) {
      return res.status(404).json({
        success: false,
        message: "Availability slot not found",
      });
    }

    if (availability.faculty.toString() !== faculty._id.toString()) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to update this availability slot",
      });
    }

    if (availability.isBooked && (date || startTime || endTime)) {
      return res.status(400).json({
        success: false,
        message: "Cannot update date or time for a booked slot",
      });
    }

    // If updating date, validate it's not in the past and is a weekday
    if (date) {
      const availabilityDate = new Date(date);
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      availabilityDate.setHours(0, 0, 0, 0);

      if (availabilityDate < today) {
        return res.status(400).json({
          success: false,
          message: "Cannot set availability for past dates",
        });
      }

      const dayOfWeek = availabilityDate.getDay();
      if (dayOfWeek === 0 || dayOfWeek === 6) {
        return res.status(400).json({
          success: false,
          message:
            "Availability can only be set for weekdays (Monday to Friday)",
        });
      }

      availability.date = availabilityDate;
    }

    if (startTime) availability.startTime = startTime;
    if (endTime) availability.endTime = endTime;
    if (isActive !== undefined) availability.isActive = isActive;

    await availability.save();

    res.status(200).json({
      success: true,
      message: "Availability slot updated successfully",
      data: availability,
    });
  } catch (error) {
    console.error("Update availability slot error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/faculty/availability/{availabilityId}:
 *   delete:
 *     summary: Delete availability slot
 *     tags: [Faculty]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: availabilityId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Availability slot deleted
 *       400:
 *         description: Cannot delete booked slot
 *       403:
 *         description: Not authorized
 *       404:
 *         description: Availability slot not found
 */
export const deleteAvailabilitySlot = async (req, res) => {
  try {
    const { availabilityId } = req.params;

    const faculty = await Faculty.findOne({ user: req.user.id });
    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    const availability = await Availability.findById(availabilityId);
    if (!availability) {
      return res.status(404).json({
        success: false,
        message: "Availability slot not found",
      });
    }

    if (availability.faculty.toString() !== faculty._id.toString()) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to delete this availability slot",
      });
    }

    if (availability.isBooked) {
      return res.status(400).json({
        success: false,
        message: "Cannot delete a booked slot",
      });
    }

    faculty.availabilities = faculty.availabilities.filter(
      (id) => id.toString() !== availabilityId
    );
    await faculty.save();

    await Availability.findByIdAndDelete(availabilityId);

    res.status(200).json({
      success: true,
      message: "Availability slot deleted successfully",
    });
  } catch (error) {
    console.error("Delete availability slot error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/faculty/availability:
 *   get:
 *     summary: Get all availability slots
 *     tags: [Faculty]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of availability slots
 *       404:
 *         description: Faculty not found
 */
export const getAllAvailabilitySlots = async (req, res) => {
  try {
    const faculty = await Faculty.findOne({ user: req.user.id });
    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    const availabilities = await Availability.find({
      faculty: faculty._id,
    }).sort({ date: 1, startTime: 1 });

    res.status(200).json({
      success: true,
      count: availabilities.length,
      data: availabilities,
    });
  } catch (error) {
    console.error("Get all availability slots error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};
