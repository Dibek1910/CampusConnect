import 'package:flutter/material.dart';
import 'package:campus_connect/screens/auth/splash_screen.dart';
import 'package:campus_connect/screens/auth/role_selection_screen.dart';
import 'package:campus_connect/screens/auth/login_screen.dart';
import 'package:campus_connect/screens/auth/register_screen.dart';
import 'package:campus_connect/screens/student/home_screen.dart';
import 'package:campus_connect/screens/faculty/faculty_dashboard.dart';
import 'package:campus_connect/screens/student/faculty_detail_screen.dart';
import 'package:campus_connect/screens/student/book_appointment_screen.dart';
import 'package:campus_connect/screens/student/appointment_history_screen.dart';
import 'package:campus_connect/screens/faculty/appointment_requests_screen.dart';
import 'package:campus_connect/screens/faculty/availability_screen.dart';
import 'package:campus_connect/screens/student/profile_screen.dart'; // Import StudentProfileScreen
import 'package:campus_connect/screens/faculty/profile_screen.dart'; // Import FacultyProfileScreen

class AppRouter {
  static const String splashRoute = '/';
  static const String roleSelectionRoute = '/role-selection';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String studentHomeRoute = '/student-home';
  static const String facultyDashboardRoute = '/faculty-dashboard';
  static const String facultyDetailRoute = '/faculty-detail';
  static const String bookAppointmentRoute = '/book-appointment';
  static const String appointmentHistoryRoute = '/appointment-history';
  static const String appointmentRequestsRoute = '/appointment-requests';
  static const String availabilityManagementRoute = '/availability-management';
  static const String studentProfileRoute =
      '/student-profile'; // Add student profile route
  static const String facultyProfileRoute =
      '/faculty-profile'; // Add faculty profile route

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case roleSelectionRoute:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case loginRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        final role = args?['role'] as String? ?? 'student';
        return MaterialPageRoute(builder: (_) => LoginScreen(role: role));
      case registerRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        final role = args?['role'] as String? ?? 'student';
        return MaterialPageRoute(builder: (_) => RegisterScreen(role: role));
      case studentHomeRoute:
        return MaterialPageRoute(builder: (_) => const StudentHomeScreen());
      case facultyDashboardRoute:
        return MaterialPageRoute(
            builder: (_) => const FacultyDashboardScreen());
      case facultyDetailRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => FacultyDetailScreen(
            facultyId: args['facultyId'],
            facultyName: args['facultyName'],
          ),
        );
      case bookAppointmentRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => BookAppointmentScreen(
            facultyId: args['facultyId'],
            facultyName: args['facultyName'],
            availabilityId: args['availabilityId'],
            day: args['day'],
            date: args['date'],
            startTime: args['startTime'],
            endTime: args['endTime'],
          ),
        );
      case appointmentHistoryRoute:
        return MaterialPageRoute(
            builder: (_) => const AppointmentHistoryScreen());
      case appointmentRequestsRoute:
        return MaterialPageRoute(
            builder: (_) => const AppointmentRequestsScreen());
      case availabilityManagementRoute:
        return MaterialPageRoute(builder: (_) => const AvailabilityScreen());
      case studentProfileRoute: // Define student profile route
        return MaterialPageRoute(builder: (_) => const StudentProfileScreen());
      case facultyProfileRoute: // Define faculty profile route
        return MaterialPageRoute(builder: (_) => const FacultyProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
