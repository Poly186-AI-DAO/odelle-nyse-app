import '../database/app_database.dart';
import '../models/relationships/relationships.dart';
import '../utils/logger.dart';

/// Repository for Bonds pillar data: Contacts and Interactions.
class BondsRepository {
  static const String _tag = 'BondsRepository';
  final AppDatabase _db;

  BondsRepository(this._db);

  // ===================
  // Contacts
  // ===================

  Future<List<Contact>> getContacts({bool activeOnly = true}) async {
    return _db.getContacts(activeOnly: activeOnly);
  }

  Future<List<Contact>> getPriorityContacts({int minPriority = 4}) async {
    final contacts = await _db.getContacts();
    return contacts.where((c) => c.priority >= minPriority).toList();
  }

  Future<List<Contact>> getOverdueContacts() async {
    return _db.getOverdueContacts();
  }

  Future<List<Contact>> getContactsWithUpcomingBirthdays({int days = 14}) async {
    return _db.getContactsWithUpcomingBirthdays(days);
  }

  Future<Contact?> getContact(int id) async {
    return _db.getContact(id);
  }

  Future<int> createContact(Contact contact) async {
    Logger.info('Creating contact: ${contact.name}', tag: _tag);
    return _db.insertContact(contact);
  }

  Future<int> updateContact(Contact contact) async {
    Logger.info('Updating contact: ${contact.id}', tag: _tag);
    return _db.updateContact(contact);
  }

  Future<int> deleteContact(int id) async {
    Logger.info('Deleting contact: $id', tag: _tag);
    return _db.deleteContact(id);
  }

  // ===================
  // Interactions
  // ===================

  Future<List<Interaction>> getInteractions({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _db.getInteractions(
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<Interaction>> getRecentInteractions({int days = 7}) async {
    return _db.getRecentInteractions(days);
  }

  Future<List<Interaction>> getInteractionsForContact(int contactId) async {
    return _db.getInteractionsForContact(contactId);
  }

  Future<Interaction?> getInteraction(int id) async {
    return _db.getInteraction(id);
  }

  Future<int> logInteraction(Interaction interaction) async {
    Logger.info('Logging interaction for contact: ${interaction.contactId}', tag: _tag);
    return _db.insertInteraction(interaction);
  }

  Future<int> updateInteraction(Interaction interaction) async {
    Logger.info('Updating interaction: ${interaction.id}', tag: _tag);
    return _db.updateInteraction(interaction);
  }

  Future<int> deleteInteraction(int id) async {
    Logger.info('Deleting interaction: $id', tag: _tag);
    return _db.deleteInteraction(id);
  }

  // ===================
  // Aggregates
  // ===================

  Future<BondsSummary> getSummary() async {
    final allContacts = await _db.getContacts();
    final overdueContacts = await _db.getOverdueContacts();
    final recentInteractions = await _db.getRecentInteractions(7);
    final upcomingBirthdays = await _db.getContactsWithUpcomingBirthdays(14);

    return BondsSummary(
      totalContacts: allContacts.length,
      priorityContacts: allContacts.where((c) => c.priority >= 4).length,
      overdueCount: overdueContacts.length,
      interactionsThisWeek: recentInteractions.length,
      upcomingBirthdays: upcomingBirthdays.length,
    );
  }
}

/// Aggregate summary of bonds data.
class BondsSummary {
  final int totalContacts;
  final int priorityContacts;
  final int overdueCount;
  final int interactionsThisWeek;
  final int upcomingBirthdays;

  const BondsSummary({
    required this.totalContacts,
    required this.priorityContacts,
    required this.overdueCount,
    required this.interactionsThisWeek,
    required this.upcomingBirthdays,
  });
}
