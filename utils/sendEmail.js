import nodemailer from "nodemailer";

const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: process.env.SMTP_PORT === "465",
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASSWORD,
    },
  });
};

export const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

export const sendOTPEmail = async (email, otp, purpose) => {
  try {
    const transporter = createTransporter();

    const mailOptions = {
      from: `${process.env.FROM_NAME} <${process.env.FROM_EMAIL}>`,
      to: email,
      subject: `${purpose} OTP Verification`,
      html: `
        <div style="font-family: 'Arial', sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px; color: #333;">
          <h2 style="color: #0056b3; border-bottom: 2px solid #0056b3; padding-bottom: 10px; margin-bottom: 20px;">OTP Verification</h2>
          <p style="font-size: 16px;">Dear User,</p>
          <p style="font-size: 16px;">Your One-Time Password (OTP) for <strong>${purpose}</strong> is:</p>
          <div style="text-align: center; margin: 20px 0;">
            <strong style="font-size: 24px; background-color: #f0f8ff; padding: 10px 20px; border-radius: 6px; letter-spacing: 6px; color: #0056b3;">${otp}</strong>
          </div>
          <p style="font-size: 16px;">This OTP is valid for 10 minutes. Please do not share it with anyone.</p>
          <p style="font-size: 16px; margin-top: 30px;">If you did not request this OTP, please ignore this email.</p>
          <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
          <p style="text-align: center; font-size: 14px; color: #777;">This email was sent by Campus Connect. For any queries, contact us at ${process.env.FROM_EMAIL}.</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log(`OTP email sent to ${email}`);
    return true;
  } catch (error) {
    console.error("Send OTP email error:", error);
    return false;
  }
};

export const sendAppointmentEmail = async (email, subject, message) => {
  try {
    const transporter = createTransporter();

    const mailOptions = {
      from: `${process.env.FROM_NAME} <${process.env.FROM_EMAIL}>`,
      to: email,
      subject,
      html: `
        <div style="font-family: 'Arial', sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px; color: #333;">
          <h2 style="color: #0056b3; border-bottom: 2px solid #0056b3; padding-bottom: 10px; margin-bottom: 20px;">${subject}</h2>
          <p style="font-size: 16px;">Dear User,</p>
          <p style="font-size: 16px;">${message}</p>
          <p style="font-size: 16px; margin-top: 20px;">Thank you for using our appointment system.</p>
          <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
          <p style="text-align: center; font-size: 14px; color: #777;">This email was sent by Campus Connect. For any queries, contact us at ${process.env.FROM_EMAIL}.</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log(`Appointment email sent to ${email}`);
    return true;
  } catch (error) {
    console.error("Send appointment email error:", error);
    return false;
  }
};
