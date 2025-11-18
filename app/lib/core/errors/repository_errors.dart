/// Exception thrown when Supabase is not connected
class SupabaseNotConnectedException implements Exception {
  const SupabaseNotConnectedException();

  @override
  String toString() => 'Supabase is not connected. Please configure SUPABASE_API_URL and SUPABASE_ANON_KEY.';
}

/// Exception thrown when user is not authenticated
class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'User must be authenticated to perform this operation.';
}

/// Exception thrown when attempting to create entities offline
class OfflineEntityCreationException implements Exception {
  const OfflineEntityCreationException(this.entityType);

  final String entityType;

  @override
  String toString() => 'Cannot create $entityType while offline. Please connect to Supabase.';
}

