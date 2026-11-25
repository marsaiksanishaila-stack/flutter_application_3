import 'package:flutter_application_2/screens/auth/login_page.dart';
import 'package:flutter_application_2/screens/auth/register_page.dart';

import 'package:flutter_application_2/screens/dashboard/dashboard_page.dart';
import 'package:flutter_application_2/screens/dashboard/survey_detail_page.dart';
import 'package:flutter_application_2/screens/dashboard/survey_form_page.dart';

import 'package:flutter_application_2/screens/profile/edit_profile_page.dart';
import 'package:flutter_application_2/screens/profile/profile_page.dart';

import 'package:flutter_application_2/screens/splash/splash_page.dart';

import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',

  routes: [
    // SPLASH
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),

    // LOGIN
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),

    // REGISTER
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // DASHBOARD
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),

    // PROFILE
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),

    // EDIT PROFILE
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) {
        final profile = state.extra as Map<String, dynamic>?;

        return EditProfilePage(
          profile: profile,
        );
      },
    ),

    // DETAIL SURVEY
    GoRoute(
      path: '/survey-detail',
      builder: (context, state) {
        final surveyId = state.extra as int;

        return SurveyDetailPage(
          surveyId: surveyId,
        );
      },
    ),

    // TAMBAH SURVEY
    GoRoute(
      path: '/add-survey',
      builder: (context, state) {
        return const SurveyFormPage();
      },
    ),

    // EDIT SURVEY
    GoRoute(
      path: '/edit-survey',
      builder: (context, state) {
        final survey = state.extra as Map<String, dynamic>;

        return SurveyFormPage(
          survey: survey,
        );
      },
    ),
  ],
);