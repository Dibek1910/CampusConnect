import express from "express";
import {
  registerStudent,
  registerFaculty,
  verifyRegistrationOTP,
  loginUser,
  verifyLoginOTP,
  sendProfileUpdateOTP,
  verifyProfileUpdateOTP,
  logout,
  getMe,
  getAllowedBranches,
  getAllowedDepartments,
} from "../controllers/auth.controller.js";
import { protect } from "../middleware/auth.js";

const router = express.Router();

router.post("/register/student", registerStudent);
router.post("/register/faculty", registerFaculty);
router.post("/verify/registration", verifyRegistrationOTP);

router.post("/login", loginUser);
router.post("/verify/login", verifyLoginOTP);

router.get("/branches", getAllowedBranches);
router.get("/departments", getAllowedDepartments);

router.post("/profile-update/send-otp", protect, sendProfileUpdateOTP);
router.post("/profile-update/verify-otp", protect, verifyProfileUpdateOTP);

router.post("/logout", logout);
router.get("/me", protect, getMe);

export default router;
