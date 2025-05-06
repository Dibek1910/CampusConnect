import User from "../models/User.js";
import Student from "../models/Student.js";
import Faculty from "../models/Faculty.js";
import OTP from "../models/OTP.js";
import Department from "../models/Department.js";
import { generateOTP, sendOTPEmail } from "../utils/sendEmail.js";
import jwt from "jsonwebtoken";

const ALLOWED_BRANCHES = [
  "Automobile engineering",
  "Biotechnology",
  "Chemical engineering",
  "Computer science & engineering",
  "IoT & intelligent systems(CSE)",
  "Artificial intelligence & machine learning (CSE)",
  "Computer and communication engineering",
  "Data science (CSE)",
  "Computer science and biosciences",
  "Electrical & electronics engineering",
  "Electrical and computer engineering",
  "Electronics & communication engineering",
  "VLSI Design and technology (Electronics engineering)",
  "Information technology",
  "Mechanical engineering",
  "Cyber security(CSE)",
  "Robotics and artificial intelligence",
];

const ALLOWED_DEPARTMENTS = ALLOWED_BRANCHES;

/**
 * @swagger
 * /api/auth/register/student:
 *   post:
 *     summary: Register a new student
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - registrationNumber
 *               - course
 *               - branch
 *               - currentYear
 *               - currentSemester
 *               - email
 *               - phoneNumber
 *             properties:
 *               name:
 *                 type: string
 *               registrationNumber:
 *                 type: string
 *               course:
 *                 type: string
 *               branch:
 *                 type: string
 *                 enum:
 *                   - Automobile engineering
 *                   - Biotechnology
 *                   - Chemical engineering
 *                   - Computer science & engineering
 *                   - IoT & intelligent systems (CSE)
 *                   - Artificial intelligence & machine learning (CSE)
 *                   - Computer and communication engineering
 *                   - Data science (CSE)
 *                   - Computer science and biosciences
 *                   - Electrical & electronics engineering
 *                   - Electrical and computer engineering
 *                   - Electronics & communication engineering
 *                   - VLSI Design and technology (Electronics engineering)
 *                   - Information technology
 *                   - Mechanical engineering
 *                   - Cyber security (CSE)
 *                   - Robotics and artificial intelligence
 *               currentYear:
 *                 type: integer
 *                 minimum: 1
 *               currentSemester:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 8
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Must be from muj.manipal.edu domain
 *               phoneNumber:
 *                 type: string
 *                 pattern: '^\d{10}$'
 *     responses:
 *       201:
 *         description: Student registered successfully, OTP sent
 *       400:
 *         description: Invalid input or email domain
 */
export const registerStudent = async (req, res) => {
  try {
    const {
      name,
      registrationNumber,
      course,
      branch,
      currentYear,
      currentSemester,
      email,
      phoneNumber,
    } = req.body;

    if (!email.endsWith("@muj.manipal.edu")) {
      return res.status(400).json({
        success: false,
        message: "Email must be from muj.manipal.edu domain",
      });
    }

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({
        success: false,
        message: "User already exists",
      });
    }

    const studentExists = await Student.findOne({ registrationNumber });
    if (studentExists) {
      return res.status(400).json({
        success: false,
        message: "Registration number already exists",
      });
    }

    if (!ALLOWED_BRANCHES.includes(branch)) {
      return res.status(400).json({
        success: false,
        message:
          "Invalid branch selected. Please choose from the allowed branches.",
      });
    }

    const user = await User.create({
      email,
      role: "student",
      isVerified: false,
    });

    const student = await Student.create({
      user: user._id,
      name,
      registrationNumber,
      course,
      branch,
      currentYear,
      currentSemester,
      phoneNumber,
    });

    const otp = generateOTP();

    await OTP.create({
      email,
      otp,
      purpose: "registration",
    });

    await sendOTPEmail(email, otp, "Registration");

    res.status(201).json({
      success: true,
      message:
        "Student registered successfully. Please verify your email with OTP.",
      data: {
        userId: user._id,
        email: user.email,
      },
    });
  } catch (error) {
    console.error("Register student error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/auth/register/faculty:
 *   post:
 *     summary: Register a new faculty
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - phoneNumber
 *               - department
 *               - email
 *             properties:
 *               name:
 *                 type: string
 *               phoneNumber:
 *                 type: string
 *                 pattern: '^\d{10}$'
 *               department:
 *                 type: string
 *                 description: Department name (must be from allowed departments list)
 *                 enum:
 *                   - Automobile engineering
 *                   - Biotechnology
 *                   - Chemical engineering
 *                   - Computer science & engineering
 *                   - IoT & intelligent systems (CSE)
 *                   - Artificial intelligence & machine learning (CSE)
 *                   - Computer and communication engineering
 *                   - Data science (CSE)
 *                   - Computer science and biosciences
 *                   - Electrical & electronics engineering
 *                   - Electrical and computer engineering
 *                   - Electronics & communication engineering
 *                   - VLSI Design and technology (Electronics engineering)
 *                   - Information technology
 *                   - Mechanical engineering
 *                   - Cyber security (CSE)
 *                   - Robotics and artificial intelligence
 *               email:
 *                 type: string
 *                 format: email
 *               facultyId:
 *                 type: string
 *                 description: Optional unique faculty ID
 *     responses:
 *       201:
 *         description: Faculty registered successfully, OTP sent
 *       400:
 *         description: Invalid input
 */
export const registerFaculty = async (req, res) => {
  try {
    const { name, phoneNumber, department, email, facultyId } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({
        success: false,
        message: "User already exists",
      });
    }

    if (!ALLOWED_DEPARTMENTS.includes(department)) {
      return res.status(400).json({
        success: false,
        message:
          "Invalid department selected. Please choose from the allowed departments.",
      });
    }

    const departmentCode =
      department.substring(0, 3).toUpperCase() +
      "-" +
      Math.floor(100 + Math.random() * 900);

    let departmentDoc = await Department.findOne({ name: department });

    if (!departmentDoc) {
      departmentDoc = await Department.create({
        name: department,
        code: departmentCode,
        description: `Department of ${department}`,
      });
    }

    const departmentId = departmentDoc._id;

    const user = await User.create({
      email,
      role: "faculty",
      isVerified: false,
    });

    const generatedFacultyId =
      facultyId || `FAC-${Math.floor(100000 + Math.random() * 900000)}`;

    const faculty = await Faculty.create({
      user: user._id,
      facultyId: generatedFacultyId,
      name,
      phoneNumber,
      department: departmentId,
    });

    departmentDoc.faculty.push(faculty._id);
    await departmentDoc.save();

    const otp = generateOTP();

    await OTP.create({
      email,
      otp,
      purpose: "registration",
    });

    await sendOTPEmail(email, otp, "Registration");

    res.status(201).json({
      success: true,
      message:
        "Faculty registered successfully. Please verify your email with OTP.",
      data: {
        userId: user._id,
        email: user.email,
      },
    });
  } catch (error) {
    console.error("Register faculty error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/auth/verify/registration:
 *   post:
 *     summary: Verify OTP for registration
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - otp
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               otp:
 *                 type: string
 *     responses:
 *       200:
 *         description: Email verified successfully
 *       400:
 *         description: Invalid OTP or OTP expired
 */
export const verifyRegistrationOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    const otpRecord = await OTP.findOne({
      email,
      otp,
      purpose: "registration",
    });

    if (!otpRecord) {
      return res.status(400).json({
        success: false,
        message: "Invalid OTP or OTP expired",
      });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    user.isVerified = true;
    await user.save();

    await OTP.deleteOne({ _id: otpRecord._id });

    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      message: "Email verified successfully",
      data: {
        userId: user._id,
        email: user.email,
        role: user.role,
        token,
      },
    });
  } catch (error) {
    console.error("Verify OTP error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user (send OTP)
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: OTP sent to email
 *       404:
 *         description: User not found
 */
export const loginUser = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (!user.isVerified) {
      return res.status(401).json({
        success: false,
        message: "Email not verified. Please complete registration first.",
      });
    }

    const otp = generateOTP();

    await OTP.create({
      email,
      otp,
      purpose: "login",
    });

    await sendOTPEmail(email, otp, "Login");

    res.status(200).json({
      success: true,
      message: "OTP sent to your email",
      data: {
        email: user.email,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/auth/verify/login:
 *   post:
 *     summary: Verify OTP for login
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - otp
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               otp:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *       400:
 *         description: Invalid OTP or OTP expired
 */
export const verifyLoginOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    const otpRecord = await OTP.findOne({
      email,
      otp,
      purpose: "login",
    });

    if (!otpRecord) {
      return res.status(400).json({
        success: false,
        message: "Invalid OTP or OTP expired",
      });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    await OTP.deleteOne({ _id: otpRecord._id });

    const token = generateToken(user._id);

    let userData;
    if (user.role === "student") {
      userData = await Student.findOne({ user: user._id }).select("-__v");
    } else if (user.role === "faculty") {
      userData = await Faculty.findOne({ user: user._id })
        .populate("department", "name")
        .select("-__v");
    }

    res.status(200).json({
      success: true,
      message: "Login successful",
      data: {
        userId: user._id,
        email: user.email,
        role: user.role,
        profile: userData,
        token,
      },
    });
  } catch (error) {
    console.error("Verify login OTP error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/auth/branches:
 *   get:
 *     summary: Get list of allowed branches for students
 *     tags: [Authentication]
 *     responses:
 *       200:
 *         description: List of branches retrieved successfully
 */
export const getAllowedBranches = async (req, res) => {
  try {
    res.status(200).json({
      success: true,
      data: ALLOWED_BRANCHES,
    });
  } catch (error) {
    console.error("Get branches error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/auth/departments:
 *   get:
 *     summary: Get list of allowed departments for faculty
 *     tags: [Authentication]
 *     responses:
 *       200:
 *         description: List of departments retrieved successfully
 */
export const getAllowedDepartments = async (req, res) => {
  try {
    res.status(200).json({
      success: true,
      data: ALLOWED_DEPARTMENTS,
    });
  } catch (error) {
    console.error("Get departments error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/auth/profile-update/send-otp:
 *   post:
 *     summary: Send OTP for profile update
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: OTP sent for profile update
 *       404:
 *         description: User not found
 */
export const sendProfileUpdateOTP = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const otp = generateOTP();

    await OTP.create({
      email,
      otp,
      purpose: "profile-update",
    });

    await sendOTPEmail(email, otp, "Profile Update");

    res.status(200).json({
      success: true,
      message: "OTP sent to your email for profile update",
      data: {
        email: user.email,
      },
    });
  } catch (error) {
    console.error("Send profile update OTP error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/auth/profile-update/verify-otp:
 *   post:
 *     summary: Verify OTP for profile update
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - otp
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               otp:
 *                 type: string
 *     responses:
 *       200:
 *         description: OTP verified for profile update
 *       400:
 *         description: Invalid OTP or OTP expired
 */
export const verifyProfileUpdateOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    const otpRecord = await OTP.findOne({
      email,
      otp,
      purpose: "profile-update",
    });

    if (!otpRecord) {
      return res.status(400).json({
        success: false,
        message: "Invalid OTP or OTP expired",
      });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    await OTP.deleteOne({ _id: otpRecord._id });

    res.status(200).json({
      success: true,
      message: "OTP verified successfully for profile update",
      data: {
        userId: user._id,
        email: user.email,
        isVerified: true,
      },
    });
  } catch (error) {
    console.error("Verify profile update OTP error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Logout user
 *     tags: [Authentication]
 *     responses:
 *       200:
 *         description: Logout successful
 */
export const logout = async (req, res) => {
  try {
    res.status(200).json({
      success: true,
      message: "Logged out successfully",
    });
  } catch (error) {
    console.error("Logout error:", error);
    res.status(500).json({
      success: false,
      message: "Server error during logout",
    });
  }
};

/**
 * @swagger
 * /api/auth/me:
 *   get:
 *     summary: Get current user profile
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile retrieved
 *       404:
 *         description: User not found
 */
export const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    let profile = null;
    if (user.role === "student") {
      profile = await Student.findOne({ user: user._id }).select("-__v");
    } else if (user.role === "faculty") {
      profile = await Faculty.findOne({ user: user._id }).populate(
        "department"
      );
    }

    res.status(200).json({
      success: true,
      data: {
        user,
        profile,
      },
    });
  } catch (error) {
    console.error("Get me error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || "30d",
  });
};
