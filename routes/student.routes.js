import express from "express";
import {
  getStudentProfile,
  updateStudentProfile,
  getAllFaculty,
  getFacultyAvailability,
  getAllDepartments,
} from "../controllers/student.controller.js";
import { protect, authorize } from "../middleware/auth.js";

const router = express.Router();

router.use(protect);
router.use(authorize("student"));

router.get("/profile", getStudentProfile);
router.put("/profile", updateStudentProfile);

router.get("/faculty", getAllFaculty);
router.get("/faculty/:facultyId/availability", getFacultyAvailability);

router.get("/departments", getAllDepartments);

export default router;
