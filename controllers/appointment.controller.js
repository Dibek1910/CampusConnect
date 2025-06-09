import Appointment from "../models/Appointment.js";
import Student from "../models/Student.js";
import Faculty from "../models/Faculty.js";
import Availability from "../models/Availability.js";
import User from "../models/User.js";
import { sendAppointmentEmail } from "../utils/sendEmail.js";

/**
 * @swagger
 * /api/appointments:
 *   post:
 *     summary: Book an appointment
 *     tags: [Appointments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - facultyId
 *               - date
 *               - purpose
 *               - purposeCategory
 *             properties:
 *               facultyId:
 *                 type: string
 *               availabilityId:
 *                 type: string
 *                 description: Required for slot booking, not for direct requests
 *               date:
 *                 type: string
 *                 format: date
 *               startTime:
 *                 type: string
 *                 description: Required for direct requests
 *               duration:
 *                 type: number
 *                 enum: [15, 30, 45, 60]
 *                 description: Required for direct requests
 *               purpose:
 *                 type: string
 *                 maxLength: 200
 *               purposeCategory:
 *                 type: string
 *                 enum: [Academic, Personal, Project, Other]
 *               customPurposeText:
 *                 type: string
 *                 description: Optional additional details
 *               isDirectRequest:
 *                 type: boolean
 *                 default: false
 *     responses:
 *       201:
 *         description: Appointment booked successfully
 *       400:
 *         description: Invalid input or slot already booked
 *       404:
 *         description: Faculty or availability not found
 */
export const bookAppointment = async (req, res) => {
  try {
    const {
      facultyId,
      availabilityId,
      date,
      startTime,
      duration,
      purpose,
      purposeCategory,
      customPurposeText,
      isDirectRequest = false,
    } = req.body;

    const student = await Student.findOne({ user: req.user.id });
    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    const faculty = await Faculty.findById(facultyId);
    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    const appointmentDate = new Date(date);
    const dayOfWeek = appointmentDate.getDay();
    if (dayOfWeek === 0 || dayOfWeek === 6) {
      return res.status(400).json({
        success: false,
        message:
          "Appointments can only be scheduled on weekdays (Monday to Friday)",
      });
    }

    let endTime;
    const appointmentData = {
      student: student._id,
      faculty: faculty._id,
      date: appointmentDate,
      purpose,
      purposeCategory,
      customPurposeText,
      status: "pending",
      isDirectRequest,
    };

    if (isDirectRequest) {
      if (!startTime || !duration) {
        return res.status(400).json({
          success: false,
          message:
            "Start time and duration are required for direct appointment requests",
        });
      }

      const [hours, minutes] = startTime.split(":").map(Number);
      if (hours < 9 || (hours === 18 && minutes > 0) || hours > 18) {
        return res.status(400).json({
          success: false,
          message:
            "Appointments can only be scheduled between 9:00 AM and 6:00 PM",
        });
      }

      const startDateTime = new Date(`1970-01-01T${startTime}:00`);
      const endDateTime = new Date(startDateTime.getTime() + duration * 60000);
      endTime = `${endDateTime
        .getHours()
        .toString()
        .padStart(2, "0")}:${endDateTime
        .getMinutes()
        .toString()
        .padStart(2, "0")}`;

      if (
        endDateTime.getHours() > 18 ||
        (endDateTime.getHours() === 18 && endDateTime.getMinutes() > 0)
      ) {
        return res.status(400).json({
          success: false,
          message: "Appointment end time cannot be after 6:00 PM",
        });
      }

      appointmentData.startTime = startTime;
      appointmentData.endTime = endTime;
      appointmentData.duration = duration;
    } else {
      if (!availabilityId) {
        return res.status(400).json({
          success: false,
          message: "Availability slot ID is required for slot booking",
        });
      }

      const availability = await Availability.findById(availabilityId);
      if (!availability) {
        return res.status(404).json({
          success: false,
          message: "Availability slot not found",
        });
      }

      if (availability.faculty.toString() !== facultyId) {
        return res.status(400).json({
          success: false,
          message: "Availability slot does not belong to this faculty",
        });
      }

      if (!availability.isActive) {
        return res.status(400).json({
          success: false,
          message: "Availability slot is not active",
        });
      }

      if (availability.isBooked) {
        return res.status(400).json({
          success: false,
          message: "Availability slot is already booked",
        });
      }

      appointmentData.availability = availability._id;
      appointmentData.startTime = availability.startTime;
      appointmentData.endTime = availability.endTime;

      availability.isBooked = true;
      await availability.save();
    }

    const existingAppointment = await Appointment.findOne({
      student: student._id,
      date: appointmentDate,
      status: { $in: ["pending", "accepted"] },
      $or: [
        { startTime: appointmentData.startTime },
        {
          $and: [
            { startTime: { $lt: appointmentData.endTime } },
            { endTime: { $gt: appointmentData.startTime } },
          ],
        },
      ],
    });

    if (existingAppointment) {
      return res.status(400).json({
        success: false,
        message: "You already have an appointment at this time",
      });
    }

    const appointment = await Appointment.create(appointmentData);

    student.appointments.push(appointment._id);
    await student.save();

    faculty.appointments.push(appointment._id);
    await faculty.save();

    const studentUser = await User.findById(student.user);
    const facultyUser = await User.findById(faculty.user);

    await sendAppointmentEmail(
      studentUser.email,
      "Appointment Request Submitted",
      `Your appointment request with ${
        faculty.name
      } on ${appointmentDate.toDateString()} at ${
        appointmentData.startTime
      } has been submitted and is pending approval.`
    );

    await sendAppointmentEmail(
      facultyUser.email,
      "New Appointment Request",
      `You have a new appointment request from ${
        student.name
      } on ${appointmentDate.toDateString()} at ${appointmentData.startTime}.
      ${isDirectRequest ? `Duration: ${duration} minutes` : ""}
      Purpose: ${purposeCategory}${
        customPurposeText ? ` - ${customPurposeText}` : ""
      }`
    );

    res.status(201).json({
      success: true,
      message: "Appointment booked successfully",
      data: appointment,
    });
  } catch (error) {
    console.error("Book appointment error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/appointments/student:
 *   get:
 *     summary: Get student appointments
 *     tags: [Appointments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, accepted, rejected, completed, all]
 *         description: Filter appointments by status
 *     responses:
 *       200:
 *         description: List of student appointments
 *       404:
 *         description: Student not found
 */
export const getStudentAppointments = async (req, res) => {
  try {
    const { status } = req.query;

    const student = await Student.findOne({ user: req.user.id });
    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    const query = { student: student._id };

    if (status && status !== "all") {
      query.status = status;
    }

    const appointments = await Appointment.find(query)
      .populate({
        path: "faculty",
        select: "name phoneNumber",
        populate: {
          path: "department",
          select: "name",
        },
      })
      .populate("availability", "day startTime endTime")
      .sort({ date: 1 });

    res.status(200).json({
      success: true,
      count: appointments.length,
      data: appointments,
    });
  } catch (error) {
    console.error("Get student appointments error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/appointments/faculty:
 *   get:
 *     summary: Get faculty appointments
 *     tags: [Appointments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, accepted, rejected, completed, all]
 *         description: Filter appointments by status
 *     responses:
 *       200:
 *         description: List of faculty appointments
 *       404:
 *         description: Faculty not found
 */
export const getFacultyAppointments = async (req, res) => {
  try {
    const { status } = req.query;

    const faculty = await Faculty.findOne({ user: req.user.id });
    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    const query = { faculty: faculty._id };

    if (status && status !== "all") {
      query.status = status;
    }

    const appointments = await Appointment.find(query)
      .populate({
        path: "student",
        select:
          "name registrationNumber course branch currentYear currentSemester phoneNumber",
      })
      .populate("availability", "day startTime endTime")
      .sort({ date: 1 });

    res.status(200).json({
      success: true,
      count: appointments.length,
      data: appointments,
    });
  } catch (error) {
    console.error("Get faculty appointments error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/appointments/{appointmentId}/status:
 *   put:
 *     summary: Update appointment status (faculty only)
 *     tags: [Appointments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: appointmentId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [accepted, rejected]
 *               reason:
 *                 type: string
 *                 description: Required if status is rejected
 *     responses:
 *       200:
 *         description: Appointment status updated
 *       400:
 *         description: Invalid status or appointment already processed
 *       403:
 *         description: Not authorized
 *       404:
 *         description: Appointment not found
 */
export const updateAppointmentStatus = async (req, res) => {
  try {
    const { appointmentId } = req.params;
    const { status, reason } = req.body;

    if (!["accepted", "rejected"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid status. Status must be accepted or rejected",
      });
    }

    const faculty = await Faculty.findOne({ user: req.user.id });
    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    const appointment = await Appointment.findById(appointmentId);
    if (!appointment) {
      return res.status(404).json({
        success: false,
        message: "Appointment not found",
      });
    }

    if (appointment.faculty.toString() !== faculty._id.toString()) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to update this appointment",
      });
    }

    if (appointment.status !== "pending") {
      return res.status(400).json({
        success: false,
        message: `Appointment is already ${appointment.status}`,
      });
    }

    appointment.status = status;
    if (status === "rejected" && reason) {
      appointment.cancelReason = reason;
    }
    await appointment.save();

    if (status === "rejected" && appointment.availability) {
      const availability = await Availability.findById(
        appointment.availability
      );
      if (availability) {
        availability.isBooked = false;
        await availability.save();
      }
    }

    const student = await Student.findById(appointment.student);
    const studentUser = await User.findById(student.user);
    const facultyUser = await User.findById(faculty.user);

    const statusText = status === "accepted" ? "accepted" : "rejected";
    const reasonText = reason ? ` Reason: ${reason}` : "";

    await sendAppointmentEmail(
      studentUser.email,
      `Appointment ${statusText.charAt(0).toUpperCase() + statusText.slice(1)}`,
      `Your appointment with ${
        faculty.name
      } on ${appointment.date.toDateString()} at ${
        appointment.startTime
      } has been ${statusText}.${reasonText}`
    );

    res.status(200).json({
      success: true,
      message: `Appointment ${statusText} successfully`,
      data: appointment,
    });
  } catch (error) {
    console.error("Update appointment status error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/appointments/{appointmentId}/cancel:
 *   put:
 *     summary: Cancel appointment
 *     tags: [Appointments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: appointmentId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Appointment cancelled
 *       400:
 *         description: Appointment already cancelled or rejected
 *       403:
 *         description: Not authorized
 *       404:
 *         description: Appointment not found
 */
export const cancelAppointment = async (req, res) => {
  try {
    const { appointmentId } = req.params;
    const { reason } = req.body;

    const appointment = await Appointment.findById(appointmentId);
    if (!appointment) {
      return res.status(404).json({
        success: false,
        message: "Appointment not found",
      });
    }

    if (appointment.status === "cancelled") {
      return res.status(400).json({
        success: false,
        message: "Appointment is already cancelled",
      });
    }

    if (appointment.status === "rejected") {
      return res.status(400).json({
        success: false,
        message: "Cannot cancel a rejected appointment",
      });
    }

    if (appointment.status === "completed") {
      return res.status(400).json({
        success: false,
        message: "Cannot cancel a completed appointment",
      });
    }

    let role;

    const student = await Student.findOne({ user: req.user.id });
    if (student) {
      if (appointment.student.toString() !== student._id.toString()) {
        return res.status(403).json({
          success: false,
          message: "Not authorized to cancel this appointment",
        });
      }
      role = "student";
    } else {
      const faculty = await Faculty.findOne({ user: req.user.id });
      if (!faculty) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }

      if (appointment.faculty.toString() !== faculty._id.toString()) {
        return res.status(403).json({
          success: false,
          message: "Not authorized to cancel this appointment",
        });
      }
      role = "faculty";
    }

    appointment.status = "cancelled";
    appointment.cancelledBy = role;
    if (reason) {
      appointment.cancelReason = reason;
    }
    await appointment.save();

    if (appointment.availability) {
      const availability = await Availability.findById(
        appointment.availability
      );
      if (availability) {
        availability.isBooked = false;
        await availability.save();
      }
    }

    const studentObj = await Student.findById(appointment.student);
    const facultyObj = await Faculty.findById(appointment.faculty);
    const studentUser = await User.findById(studentObj.user);
    const facultyUser = await User.findById(facultyObj.user);

    const cancelledBy = role === "student" ? studentObj.name : facultyObj.name;
    const reasonText = reason ? ` Reason: ${reason}` : "";

    await sendAppointmentEmail(
      studentUser.email,
      "Appointment Cancelled",
      `Your appointment with ${
        facultyObj.name
      } on ${appointment.date.toDateString()} at ${
        appointment.startTime
      } has been cancelled by ${cancelledBy}.${reasonText}`
    );

    await sendAppointmentEmail(
      facultyUser.email,
      "Appointment Cancelled",
      `Your appointment with ${
        studentObj.name
      } on ${appointment.date.toDateString()} at ${
        appointment.startTime
      } has been cancelled by ${cancelledBy}.${reasonText}`
    );

    res.status(200).json({
      success: true,
      message: "Appointment cancelled successfully",
      data: appointment,
    });
  } catch (error) {
    console.error("Cancel appointment error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/appointments/{appointmentId}/complete:
 *   put:
 *     summary: Mark appointment as completed (faculty only)
 *     tags: [Appointments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: appointmentId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Appointment marked as completed
 *       400:
 *         description: Appointment not accepted
 *       403:
 *         description: Not authorized
 *       404:
 *         description: Appointment not found
 */
export const completeAppointment = async (req, res) => {
  try {
    const { appointmentId } = req.params;

    const faculty = await Faculty.findOne({ user: req.user.id });
    if (!faculty) {
      return res.status(404).json({
        success: false,
        message: "Faculty not found",
      });
    }

    const appointment = await Appointment.findById(appointmentId);
    if (!appointment) {
      return res.status(404).json({
        success: false,
        message: "Appointment not found",
      });
    }

    if (appointment.faculty.toString() !== faculty._id.toString()) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to complete this appointment",
      });
    }

    if (appointment.status !== "accepted") {
      return res.status(400).json({
        success: false,
        message: `Appointment must be accepted before it can be completed. Current status: ${appointment.status}`,
      });
    }

    appointment.status = "completed";
    await appointment.save();

    if (appointment.availability) {
      const availability = await Availability.findById(
        appointment.availability
      );
      if (availability) {
        availability.isBooked = false;
        await availability.save();
      }
    }

    const student = await Student.findById(appointment.student);
    const studentUser = await User.findById(student.user);

    await sendAppointmentEmail(
      studentUser.email,
      "Appointment Completed",
      `Your appointment with ${
        faculty.name
      } on ${appointment.date.toDateString()} at ${
        appointment.startTime
      } has been marked as completed.`
    );

    res.status(200).json({
      success: true,
      message: "Appointment marked as completed",
      data: appointment,
    });
  } catch (error) {
    console.error("Complete appointment error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/appointments/direct-request:
 *   post:
 *     summary: Create a direct appointment request
 *     tags: [Appointments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - facultyId
 *               - date
 *               - startTime
 *               - duration
 *               - purposeCategory
 *             properties:
 *               facultyId:
 *                 type: string
 *               date:
 *                 type: string
 *                 format: date
 *               startTime:
 *                 type: string
 *                 pattern: '^([01]\d|2[0-3]):([0-5]\d)$'
 *               duration:
 *                 type: number
 *                 enum: [15, 30, 45, 60]
 *               purposeCategory:
 *                 type: string
 *                 enum: [Academic, Personal, Project, Other]
 *               customPurposeText:
 *                 type: string
 *     responses:
 *       201:
 *         description: Direct appointment request created successfully
 *       400:
 *         description: Invalid input
 *       404:
 *         description: Faculty not found
 */
export const createDirectRequest = async (req, res) => {
  try {
    const {
      facultyId,
      date,
      startTime,
      duration,
      purposeCategory,
      customPurposeText,
    } = req.body;

    if (!facultyId || !date || !startTime || !duration || !purposeCategory) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields for direct appointment request",
      });
    }

    const purpose = customPurposeText
      ? `${purposeCategory}: ${customPurposeText}`
      : purposeCategory;

    req.body.isDirectRequest = true;
    req.body.purpose = purpose;

    return await bookAppointment(req, res);
  } catch (error) {
    console.error("Direct request error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};
