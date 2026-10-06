import '../../../../core/utils/logger_service.dart';

void main() {
  // Placements Mock from Job Applications
  final placements = [
    {
      'student_id': '89051951-15e6-47e4-b56b-c0962d5cd435',
      'status': 'selected',
      'jobs': {
        'organization_id': 'a8ab05df-8a33-4950-924f-3b5375c45a88', // Heartware
        'title': 'Software Engineer',
      },
    },
    {
      'student_id': '89051951-15e6-47e4-b56b-c0962d5cd435',
      'status': 'selected',
      'jobs': {
        'organization_id': 'a8ab05df-8a33-4950-924f-3b5375c45a88', // Heartware
        'title': 'Another Role',
      },
    },
  ];

  // Logic from App
  Map<String, int> orgHires = {};

  for (var p in placements) {
    // Mimic dynamic map access
    final jobs = p['jobs'] as Map<String, dynamic>?;
    final jobOrgId = jobs?['organization_id'];

    if (jobOrgId != null) {
      orgHires[jobOrgId] = (orgHires[jobOrgId] ?? 0) + 1;
    }
  }

  LoggerService.debug('Org Hires: $orgHires');

  // Network Mock
  final network = [
    {
      'id': '431df906-7ee9-4183-b254-e874380150b9', // Jeery
      'full_name': 'Jeery',
      'organizations': {
        'id': 'a8ab05df-8a33-4950-924f-3b5375c45a88', // Heartware
        'name': 'Heartware',
      },
    },
  ];

  for (var recruiter in network) {
    final organizations = recruiter['organizations'] as Map<String, dynamic>?;
    final recOrgId = organizations?['id'];

    final hires = orgHires[recOrgId] ?? 0;
    LoggerService.debug('Recruiter ${recruiter['full_name']} Hires: $hires');
  }
}
