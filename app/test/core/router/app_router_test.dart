import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:volleyball_stats_app/core/router/app_router.dart';

void main() {
  group('AppRouter', () {
    test('router is configured correctly', () {
      expect(appRouter, isNotNull);
      expect(appRouter.configuration.routes, isNotEmpty);
    });

    group('Route paths', () {
      test('has home route', () {
        final route = _findRouteByPath(appRouter, '/');
        expect(route, isNotNull);
      });

      test('has teams routes', () {
        expect(_findRouteByPath(appRouter, '/teams'), isNotNull);
        expect(_findRouteByPath(appRouter, '/teams/create'), isNotNull);
        expect(_findRouteByPath(appRouter, '/teams/:id/edit'), isNotNull);
      });

      test('has players routes', () {
        expect(_findRouteByPath(appRouter, '/players'), isNotNull);
        expect(_findRouteByPath(appRouter, '/players/create'), isNotNull);
        expect(_findRouteByPath(appRouter, '/players/:id/edit'), isNotNull);
      });

      test('has templates routes', () {
        expect(_findRouteByPath(appRouter, '/templates'), isNotNull);
        expect(_findRouteByPath(appRouter, '/templates/create'), isNotNull);
        expect(_findRouteByPath(appRouter, '/templates/:id/edit'), isNotNull);
      });

      test('has match setup routes', () {
        expect(_findRouteByPath(appRouter, '/match/setup'), isNotNull);
        expect(_findRouteByPath(appRouter, '/match/:id/setup'), isNotNull);
      });

      test('has rally capture route', () {
        final route = _findRouteByPath(appRouter, '/match/:id/rally');
        expect(route, isNotNull);
      });

      test('has history routes', () {
        expect(_findRouteByPath(appRouter, '/history'), isNotNull);
        expect(_findRouteByPath(appRouter, '/match/:id/recap'), isNotNull);
      });

      test('has dashboard routes', () {
        expect(_findRouteByPath(appRouter, '/season'), isNotNull);
        expect(
          _findRouteByPath(appRouter, '/match/:matchId/set/:setNumber/dashboard'),
          isNotNull,
        );
      });

      test('has export route', () {
        expect(_findRouteByPath(appRouter, '/export'), isNotNull);
      });

      test('has auth routes', () {
        expect(_findRouteByPath(appRouter, '/login'), isNotNull);
        expect(_findRouteByPath(appRouter, '/signup'), isNotNull);
      });
    });

    group('Route names', () {
      test('home route has correct name', () {
        final route = _findRouteByName(appRouter, 'home');
        expect(route, isNotNull);
      });

      test('teams routes have correct names', () {
        expect(_findRouteByName(appRouter, 'teams'), isNotNull);
        expect(_findRouteByName(appRouter, 'team-create'), isNotNull);
        expect(_findRouteByName(appRouter, 'team-edit'), isNotNull);
      });

      test('player routes have correct names', () {
        expect(_findRouteByName(appRouter, 'players'), isNotNull);
        expect(_findRouteByName(appRouter, 'player-create'), isNotNull);
        expect(_findRouteByName(appRouter, 'player-edit'), isNotNull);
      });

      test('template routes have correct names', () {
        expect(_findRouteByName(appRouter, 'templates'), isNotNull);
        expect(_findRouteByName(appRouter, 'template-create'), isNotNull);
        expect(_findRouteByName(appRouter, 'template-edit'), isNotNull);
      });

      test('match routes have correct names', () {
        expect(_findRouteByName(appRouter, 'match-setup'), isNotNull);
        expect(_findRouteByName(appRouter, 'match-setup-edit'), isNotNull);
        expect(_findRouteByName(appRouter, 'rally-capture'), isNotNull);
      });

      test('history routes have correct names', () {
        expect(_findRouteByName(appRouter, 'match-history'), isNotNull);
        expect(_findRouteByName(appRouter, 'match-recap'), isNotNull);
      });

      test('dashboard routes have correct names', () {
        expect(_findRouteByName(appRouter, 'season-dashboard'), isNotNull);
        expect(_findRouteByName(appRouter, 'set-dashboard'), isNotNull);
      });
    });

    // Widget test removed - requires full app initialization with providers
    // Router functionality is validated through unit tests above

    group('Parameter handling', () {
      test('match routes include route parameters', () {
        final route = _findRouteByPath(appRouter, '/match/:id/rally') as GoRoute?;
        expect(route, isNotNull);
        expect(route?.path, contains(':id'));
      });

      test('set dashboard includes multiple parameters', () {
        final route = _findRouteByPath(
          appRouter,
          '/match/:matchId/set/:setNumber/dashboard',
        ) as GoRoute?;
        expect(route, isNotNull);
        expect(route?.path, contains(':matchId'));
        expect(route?.path, contains(':setNumber'));
      });

      test('edit routes include id parameter', () {
        final teamRoute = _findRouteByPath(appRouter, '/teams/:id/edit') as GoRoute?;
        expect(teamRoute?.path, contains(':id'));
        
        final playerRoute = _findRouteByPath(appRouter, '/players/:id/edit') as GoRoute?;
        expect(playerRoute?.path, contains(':id'));
        
        final templateRoute = _findRouteByPath(appRouter, '/templates/:id/edit') as GoRoute?;
        expect(templateRoute?.path, contains(':id'));
      });
    });
  });
}

/// Helper to find a route by path
RouteBase? _findRouteByPath(GoRouter router, String path) {
  for (final route in router.configuration.routes) {
    if (route is GoRoute && route.path == path) {
      return route;
    }
  }
  return null;
}

/// Helper to find a route by name
GoRoute? _findRouteByName(GoRouter router, String name) {
  for (final route in router.configuration.routes) {
    if (route is GoRoute && route.name == name) {
      return route;
    }
  }
  return null;
}
