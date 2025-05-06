import express from "express";
import {
  getFacultyProfile,
  updateFacultyProfile,
  addAvailabilitySlot,
  updateAvailabilitySlot,
  deleteAvailabilitySlot,
  getAllAvailabilitySlots,
} from "../controllers/faculty.controller.js";
import { protect, authorize } from "../middleware/auth.js";

const router = express.Router();

router.use(protect);
router.use(authorize("faculty"));

router.get("/profile", getFacultyProfile);
router.put("/profile", updateFacultyProfile);

router.get("/availability", getAllAvailabilitySlots);
router.post("/availability", addAvailabilitySlot);
router.put("/availability/:availabilityId", updateAvailabilitySlot);
router.delete("/availability/:availabilityId", deleteAvailabilitySlot);

export default router;
