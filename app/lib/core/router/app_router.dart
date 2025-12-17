import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/export/export_screen.dart';
import '../../features/history/match_history_screen.dart';
import '../../features/history/match_recap_screen.dart';
import '../../features/history/season_dashboard_screen.dart';
import '../../features/history/set_dashboard_screen.dart';
import '../../features/match_setup/home_screen.dart';
import '../../features/match_setup/match_setup_flow.dart';
import '../../features/match_setup/match_setup_landing_screen.dart';
import '../../features/match_setup/template_edit_screen.dart';
import '../../features/match_setup/template_list_screen.dart';
import '../../features/players/player_create_screen.dart';
import '../../features/players/player_edit_screen.dart';
import '../../features/players/player_list_screen.dart';
import '../../features/rally_capture/rally_capture_screen.dart';
import '../../features/teams/team_create_screen.dart';
import '../../features/teams/team_edit_screen.dart';
import '../../features/teams/team_list_screen.dart';
import '../../features/teams/team_selection_screen.dart';

/// Router configuration for the app using go_router
final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    // Home / Team Selection
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    // Team Selection (explicit route for navigation)
    GoRoute(
      path: '/teams/select',
      name: 'team-selection',
      builder: (context, state) => const TeamSelectionScreen(),
    ),

    // Match Setup Landing (after team selected)
    GoRoute(
      path: '/match-setup',
      name: 'match-setup-landing',
      builder: (context, state) => const MatchSetupLandingScreen(),
    ),

    // Teams
    GoRoute(
      path: '/teams',
      name: 'teams',
      builder: (context, state) => const TeamListScreen(),
    ),
    GoRoute(
      path: '/teams/create',
      name: 'team-create',
      builder: (context, state) => const TeamCreateScreen(),
    ),
    GoRoute(
      path: '/teams/:id/edit',
      name: 'team-edit',
      builder: (context, state) {
        final team = state.extra as dynamic;
        return TeamEditScreen(team: team);
      },
    ),

    // Players
    GoRoute(
      path: '/players',
      name: 'players',
      builder: (context, state) => const PlayerListScreen(),
    ),
    GoRoute(
      path: '/players/create',
      name: 'player-create',
      builder: (context, state) => const PlayerCreateScreen(),
    ),
    GoRoute(
      path: '/players/:id/edit',
      name: 'player-edit',
      builder: (context, state) {
        final player = state.extra as dynamic;
        return PlayerEditScreen(player: player);
      },
    ),

    // Templates
    GoRoute(
      path: '/templates',
      name: 'templates',
      builder: (context, state) => const TemplateListScreen(),
    ),
    GoRoute(
      path: '/templates/create',
      name: 'template-create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final playerIds = extra?['initialPlayerIds'];
        return TemplateEditScreen(
          initialPlayerIds: playerIds != null ? Set<String>.from(playerIds as Iterable) : null,
          initialRotation: extra?['initialRotation'] as Map<int, String>?,
        );
      },
    ),
    GoRoute(
      path: '/templates/:id/edit',
      name: 'template-edit',
      builder: (context, state) {
        final template = state.extra as dynamic;
        return TemplateEditScreen(template: template);
      },
    ),

    // Match Setup Flow (create new match)
    GoRoute(
      path: '/match/setup',
      name: 'match-setup',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return MatchSetupFlow(
          lastDraft: extra?['lastDraft'],
          template: extra?['fromTemplate'],
        );
      },
    ),

    // Match Setup Flow (edit existing match)
    GoRoute(
      path: '/match/:id/setup',
      name: 'match-setup-edit',
      builder: (context, state) {
        final matchId = state.pathParameters['id']!;
        return MatchSetupFlow(matchId: matchId);
      },
    ),

    // Rally Capture
    GoRoute(
      path: '/match/:id/rally',
      name: 'rally-capture',
      builder: (context, state) {
        final matchId = state.pathParameters['id']!;
        return RallyCaptureScreen(matchId: matchId);
      },
    ),

    // Set Dashboard
    GoRoute(
      path: '/match/:matchId/set/:setNumber/dashboard',
      name: 'set-dashboard',
      builder: (context, state) {
        final matchId = state.pathParameters['matchId']!;
        final setNumber = int.parse(state.pathParameters['setNumber']!);
        return SetDashboardScreen(
          matchId: matchId,
          setNumber: setNumber,
        );
      },
    ),

    // Match History
    GoRoute(
      path: '/history',
      name: 'match-history',
      builder: (context, state) => const MatchHistoryScreen(),
    ),

    // Match Recap
    GoRoute(
      path: '/match/:id/recap',
      name: 'match-recap',
      builder: (context, state) {
        final matchId = state.pathParameters['id']!;
        return MatchRecapScreen(matchId: matchId);
      },
    ),

    // Season Dashboard
    GoRoute(
      path: '/season',
      name: 'season-dashboard',
      builder: (context, state) => const SeasonDashboardScreen(),
    ),

    // Export
    GoRoute(
      path: '/export',
      name: 'export',
      builder: (context, state) => const ExportScreen(),
    ),

    // Auth (kept separate for when AuthGuard is not used)
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignUpScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '404: Page Not Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.uri.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
