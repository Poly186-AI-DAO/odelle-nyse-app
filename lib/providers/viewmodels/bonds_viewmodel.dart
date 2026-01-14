import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/relationships/relationships.dart';
import '../../repositories/bonds_repository.dart';
import '../../utils/logger.dart';
import '../repository_providers.dart';

/// State for the Bonds pillar.
class BondsState {
  final List<Contact> contacts;
  final List<Contact> priorityContacts;
  final List<Contact> overdueContacts;
  final List<Interaction> recentInteractions;
  final int totalContacts;
  final int interactionsThisWeek;
  final bool isLoading;
  final String? error;

  const BondsState({
    this.contacts = const [],
    this.priorityContacts = const [],
    this.overdueContacts = const [],
    this.recentInteractions = const [],
    this.totalContacts = 0,
    this.interactionsThisWeek = 0,
    this.isLoading = false,
    this.error,
  });

  BondsState copyWith({
    List<Contact>? contacts,
    List<Contact>? priorityContacts,
    List<Contact>? overdueContacts,
    List<Interaction>? recentInteractions,
    int? totalContacts,
    int? interactionsThisWeek,
    bool? isLoading,
    String? error,
  }) {
    return BondsState(
      contacts: contacts ?? this.contacts,
      priorityContacts: priorityContacts ?? this.priorityContacts,
      overdueContacts: overdueContacts ?? this.overdueContacts,
      recentInteractions: recentInteractions ?? this.recentInteractions,
      totalContacts: totalContacts ?? this.totalContacts,
      interactionsThisWeek: interactionsThisWeek ?? this.interactionsThisWeek,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ViewModel for the Bonds pillar.
class BondsViewModel extends Notifier<BondsState> {
  static const String _tag = 'BondsViewModel';

  @override
  BondsState build() {
    return const BondsState();
  }

  BondsRepository get _repository => ref.read(bondsRepositoryProvider);

  /// Load all bonds data.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final contacts = await _repository.getContacts();
      final priorityContacts = await _repository.getPriorityContacts();
      final overdueContacts = await _repository.getOverdueContacts();
      final recentInteractions = await _repository.getRecentInteractions();
      final summary = await _repository.getSummary();

      state = state.copyWith(
        contacts: contacts,
        priorityContacts: priorityContacts,
        overdueContacts: overdueContacts,
        recentInteractions: recentInteractions,
        totalContacts: summary.totalContacts,
        interactionsThisWeek: summary.interactionsThisWeek,
        isLoading: false,
      );
      Logger.info('Loaded bonds data: ${contacts.length} contacts, '
          '${overdueContacts.length} overdue, ${recentInteractions.length} interactions', 
          tag: _tag);
    } catch (e, stackTrace) {
      Logger.error('Failed to load bonds data',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ===================
  // Contacts
  // ===================

  Future<void> addContact(Contact contact) async {
    try {
      await _repository.createContact(contact);
      await load(); // Refresh all data
    } catch (e, stackTrace) {
      Logger.error('Failed to add contact',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateContact(Contact contact) async {
    try {
      await _repository.updateContact(contact);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to update contact',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteContact(int id) async {
    try {
      await _repository.deleteContact(id);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to delete contact',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  // ===================
  // Interactions
  // ===================

  Future<void> logInteraction(Interaction interaction) async {
    try {
      await _repository.logInteraction(interaction);
      await load(); // Refresh to update last contact dates
    } catch (e, stackTrace) {
      Logger.error('Failed to log interaction',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteInteraction(int id) async {
    try {
      await _repository.deleteInteraction(id);
      await load();
    } catch (e, stackTrace) {
      Logger.error('Failed to delete interaction',
          tag: _tag, error: e, stackTrace: stackTrace);
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for BondsViewModel.
final bondsViewModelProvider =
    NotifierProvider<BondsViewModel, BondsState>(BondsViewModel.new);
