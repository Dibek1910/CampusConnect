import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import morgan from "morgan";
import cookieParser from "cookie-parser";
import helmet from "helmet";
import xss from "xss-clean";
import rateLimit from "express-rate-limit";
import hpp from "hpp";
import mongoSanitize from "express-mongo-sanitize";
import swaggerJsDoc from "swagger-jsdoc";
import swaggerUi from "swagger-ui-express";
import connectDB from "./config/database.js";
import authRoutes from "./routes/auth.routes.js";
import studentRoutes from "./routes/student.routes.js";
import facultyRoutes from "./routes/faculty.routes.js";
import appointmentRoutes from "./routes/appointment.routes.js";
import departmentRoutes from "./routes/department.routes.js";

dotenv.config();

const app = express();

app.set("trust proxy", 1);

const swaggerOptions = {
  swaggerDefinition: {
    openapi: "3.0.0",
    info: {
      title: "Faculty Appointment Booking API",
      version: "1.0.0",
      description:
        "API documentation for the Faculty Appointment Booking System",
      contact: {
        name: "Developer",
        email: "todihritik@gmail.com",
      },
      servers: [
        {
          url: `http://localhost:${process.env.PORT || 5001}`,
          description: "Development server",
        },
      ],
    },
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  apis: [
    "./controllers/*.js",
    "./routes/*.js",
    "./models/*.js",
    "./middleware/*.js",
  ],
};

const swaggerDocs = swaggerJsDoc(swaggerOptions);

app.use(helmet());
app.use(xss());
app.use(mongoSanitize());
app.use(hpp());

const limiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 100,
});
app.use("/api", limiter);

app.use(
  cors({
    origin: "http://localhost:3000",
    credentials: true,
  })
);
app.use(express.json());
app.use(cookieParser());

if (process.env.NODE_ENV === "development") {
  app.use(morgan("dev"));
}

app.use("/docs", swaggerUi.serve, swaggerUi.setup(swaggerDocs));

connectDB();

app.use("/api/auth", authRoutes);
app.use("/api/students", studentRoutes);
app.use("/api/faculty", facultyRoutes);
app.use("/api/appointments", appointmentRoutes);
app.use("/api/departments", departmentRoutes);

app.get("/", (req, res) => {
  res.json({
    message: "Welcome to Faculty Appointment Booking API",
    documentation: "/docs",
  });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: "Something went wrong",
    error:
      process.env.NODE_ENV === "development" ? err.message : "Server error",
  });
});

const PORT = process.env.PORT || 5001;

app.listen(PORT, () => {
  console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
  console.log(`API Documentation available at http://localhost:${PORT}/docs`);
});
