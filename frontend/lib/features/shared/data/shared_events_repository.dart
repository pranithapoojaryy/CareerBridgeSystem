import 'package:supabase_flutter/supabase_flutter.dart';

class SharedEventsRepository {
  final SupabaseClient _supabase;

  SharedEventsRepository(this._supabase);

  // Fetch events for students (Published events)
  Future<List<Map<String, dynamic>>> getPublishedEvents({
    String? search,
    String? type,
    bool isOnline = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    var query = _supabase.from('events').select('*');
    // .eq('is_published', true);

    if (type != null && type != 'All') {
      query = query.eq('event_type', type.toLowerCase());
    }

    var result = await query.order('created_at', ascending: false).limit(50);

    // Client-side search if needed
    if (search != null && search.isNotEmpty) {
      result = result.where((event) {
        final title = event['title'].toString().toLowerCase();
        final desc = event['description'].toString().toLowerCase();
        return title.contains(search.toLowerCase()) ||
            desc.contains(search.toLowerCase());
      }).toList();
    }

    final events = List<Map<String, dynamic>>.from(result);

    if (userId != null) {
      // Fetch registrations for these events
      final eventIds = events.map((e) => e['id']).toList();
      if (eventIds.isNotEmpty) {
        final registrations = await _supabase
            .from('event_registrations')
            .select('event_id')
            .eq('student_id', userId)
            .filter('event_id', 'in', eventIds);

        final registeredEventIds = registrations
            .map((r) => r['event_id'])
            .toSet();

        for (var event in events) {
          event['is_registered'] = registeredEventIds.contains(event['id']);
        }
      }
    }

    return events;
  }

  // Get events a student has registered for (Upcoming)
  Future<List<Map<String, dynamic>>> getStudentRegisteredEvents(
    String studentId,
  ) async {
    final response = await _supabase
        .from('event_registrations')
        .select('event_id, events(*)')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    // Flatten structure
    return response.map((r) {
      final event = r['events'] as Map<String, dynamic>;
      event['is_registered'] = true;
      return event;
    }).toList();
  }

  // Get participants for an event (for Organizers)
  Future<List<Map<String, dynamic>>> getEventParticipants(
    String eventId,
  ) async {
    // 1. Fetch registrations
    final response = await _supabase
        .from('event_registrations')
        .select('student_id, created_at')
        .eq('event_id', eventId); // Removed faulty relation join

    final registrations = List<Map<String, dynamic>>.from(response);
    if (registrations.isEmpty) return [];

    // 2. Extract student IDs
    final studentIds = registrations.map((r) => r['student_id']).toList();

    // 3. Fetch Profiles manually
    final profilesResponse = await _supabase
        .from('profiles')
        .select(
          'id, full_name, email, avatar_url',
        ) // Select specific fields safely
        .filter('id', 'in', studentIds);

    final profiles = List<Map<String, dynamic>>.from(profilesResponse);
    final profilesMap = {for (var p in profiles) p['id']: p};

    // 4. Merge data
    return registrations.map((r) {
      final studentId = r['student_id'];
      final profile =
          profilesMap[studentId] ??
          {'full_name': 'Unknown Student', 'email': 'No Email'};

      return {...r, 'student': profile};
    }).toList();
  }

  // Fetch events for Organizers (Recruiters/Colleges)
  Future<List<Map<String, dynamic>>> getOrganizerEvents(String orgId) async {
    final result = await _supabase
        .from('events')
        .select('*, event_registrations(count)')
        .eq(
          'college_id',
          orgId,
        ) // Assuming college_id is used for Organization ID
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }

  // Register for an event
  Future<void> registerForEvent(String eventId, String studentId) async {
    // Check if already registered
    final existing = await _supabase
        .from('event_registrations')
        .select()
        .eq('event_id', eventId)
        .eq('student_id', studentId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Already registered for this event');
    }

    await _supabase.from('event_registrations').insert({
      'event_id': eventId,
      'student_id': studentId,
      'status': 'registered',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Check registration status
  Future<bool> isRegistered(String eventId, String studentId) async {
    final result = await _supabase
        .from('event_registrations')
        .select()
        .eq('event_id', eventId)
        .eq('student_id', studentId)
        .maybeSingle();
    return result != null;
  }

  // Create Event (shared)
  Future<void> createEvent(Map<String, dynamic> eventData) async {
    await _supabase.from('events').insert(eventData);
  }

  // Update Event (shared)
  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    await _supabase.from('events').update(updates).eq('id', eventId);
  }

  // Delete Event (shared)
  Future<void> deleteEvent(String eventId) async {
    await _supabase.from('events').delete().eq('id', eventId);
  }
}
