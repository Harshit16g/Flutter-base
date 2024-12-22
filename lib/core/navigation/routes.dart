// lib/core/navigation/routes.dart
//USAGE
//
//// Basic route usage
// Navigator.pushNamed(context, Routes.profile);
//
// // Route with parameters
// final productRoute = Routes.replaceParams(
//   Routes.productDetails,
//   {'id': '123'},
// ); // Results in '/products/123'
//
// // Route with query parameters
// final searchRoute = Routes.withQuery(
//   Routes.search,
//   {'query': 'phones', 'category': 'electronics'},
// ); // Results in '/search?query=phones&category=electronics'
//
// // Check if route requires authentication
// if (Routes.isProtectedRoute('/profile')) {
//   // Handle authentication check
// }
//
// // Parse route parameters
// final params = Routes.parseParams(
//   Routes.productDetails, // '/products/:id'
//   '/products/123',
// ); // Results in {'id': '123'}
//
// // Get routes for a specific feature group
// final profileRoutes = Routes.routeGroups['profile'];
//
// // Check if route is accessible offline
// if (Routes.isOfflineAccessible(Routes.profile)) {
//   // Handle offline access
// }
//
// // Deep linking
// final deepLinkRoute = Routes.deepLinkRoutes['product']; // Gets product details route


abstract class Routes {
  // Private constructor to prevent instantiation
  const Routes._();

  // Authentication Flow Routes
  static const String splash = '/';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String phoneVerification = '/auth/phone-verification';

  // Main App Routes
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';

  // Feature Specific Routes
  static const String products = '/products';
  static const String productDetails = '/products/:id';
  static const String categories = '/categories';
  static const String categoryDetails = '/categories/:id';
  static const String search = '/search';
  static const String searchResults = '/search/results';

  // User Related Routes
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';
  static const String messages = '/messages';
  static const String chat = '/messages/:id';

  // Modal Routes
  static const String imageViewer = '/modals/image-viewer';
  static const String filterModal = '/modals/filter';
  static const String sortModal = '/modals/sort';
  static const String shareModal = '/modals/share';

  // Error Routes
  static const String error404 = '/404';
  static const String error500 = '/500';
  static const String maintenance = '/maintenance';



  /// Helper method to replace route parameters
  static String replaceParams(String route, Map<String, String> params) {
    String finalRoute = route;
    params.forEach((key, value) {
      finalRoute = finalRoute.replaceAll(':$key', value);
    });
    return finalRoute;
  }

  /// Get route name without parameters
  static String getBaseRoute(String route) {
    return route.split('?').first;
  }

  /// Routes that don't require authentication
  static final Set<String> publicRoutes = {
    splash,
    login,
    register,
    forgotPassword,
    resetPassword,
    maintenance,
    error404,
    error500,
  };

  /// Routes that require authentication
  static final Set<String> protectedRoutes = {
    home,
    dashboard,
    profile,
    editProfile,
    settings,
    notifications,
    messages,
    chat,
  };

  /// Routes that can be accessed in offline mode
  static final Set<String> offlineAccessibleRoutes = {
    home,
    settings,
    profile,
    error404,
  };

  /// Deep linking routes mapping
  static final Map<String, String> deepLinkRoutes = {
    'product': productDetails,
    'category': categoryDetails,
    'profile': profile,
    'notification': notifications,
    'message': chat,
  };

  /// Route groups for feature management
  static final Map<String, Set<String>> routeGroups = {
    'auth': {
      login,
      register,
      forgotPassword,
      resetPassword,
      verifyEmail,
      phoneVerification,
    },
    'profile': {
      profile,
      editProfile,
      settings,
    },
    'products': {
      products,
      productDetails,
      categories,
      categoryDetails,
    },
    'messaging': {
      messages,
      chat,
      notifications,
    },
  };

  /// Helper methods for route validation and manipulation
  static bool isPublicRoute(String route) => publicRoutes.contains(getBaseRoute(route));
  static bool isProtectedRoute(String route) => protectedRoutes.contains(getBaseRoute(route));
  static bool isOfflineAccessible(String route) => offlineAccessibleRoutes.contains(getBaseRoute(route));

  /// Generate route with query parameters
  static String withQuery(String route, Map<String, String> queryParams) {
    if (queryParams.isEmpty) return route;
    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$route?$queryString';
  }

  /// Parse route parameters
  static Map<String, String> parseParams(String template, String actual) {
    final templateParts = template.split('/');
    final actualParts = actual.split('/');
    final params = <String, String>{};

    if (templateParts.length != actualParts.length) return params;

    for (var i = 0; i < templateParts.length; i++) {
      if (templateParts[i].startsWith(':')) {
        final paramName = templateParts[i].substring(1);
        params[paramName] = actualParts[i];
      }
    }

    return params;
  }
}

//TODO:Route transitions mapping:
//static final Map<String, RouteTransition> routeTransitions = {
//   login: RouteTransition.fade,
//   register: RouteTransition.slideRight,
//   profile: RouteTransition.slideUp,
// };

//TODO::Route metadata:
//static final Map<String, RouteMetadata> routeMetadata = {
//   home: RouteMetadata(
//     title: 'Home',
//     icon: Icons.home,
//     showInNavigation: true,
//   ),
//   profile: RouteMetadata(
//     title: 'Profile',
//     icon: Icons.person,
//     showInNavigation: true,
//   ),
// };