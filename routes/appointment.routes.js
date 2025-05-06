import express from "express";
import {
  bookAppointment,
  createDirectRequest,
  getStudentAppointments,
  getFacultyAppointments,
  updateAppointmentStatus,
  cancelAppointment,
  completeAppointment,
} from "../controllers/appointment.controller.js";
import { protect, authorize } from "../middleware/auth.js";

const router = express.Router();

router.use(protect);

router.post("/", authorize("student"), bookAppointment);
router.post("/request", authorize("student"), createDirectRequest);
router.get("/student", authorize("student"), getStudentAppointments);

router.get("/faculty", authorize("faculty"), getFacultyAppointments);
router.put(
  "/:appointmentId/status",
  authorize("faculty"),
  updateAppointmentStatus
);
router.put(
  "/:appointmentId/complete",
  authorize("faculty"),
  completeAppointment
);

router.put("/:appointmentId/cancel", cancelAppointment);

export default router;
