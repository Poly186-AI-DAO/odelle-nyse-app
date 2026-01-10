import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the office/business simulation
class OfficeState {
  final List<String> products;
  final List<String> services;
  final List<String> departments;

  const OfficeState({
    this.products = const ['Core Platform'],
    this.services = const ['Consulting'],
    this.departments = const ['Engineering', 'Sales'],
  });

  /// Derived state - total worker count
  int get workerCount => products.length + services.length + departments.length;

  OfficeState copyWith({
    List<String>? products,
    List<String>? services,
    List<String>? departments,
  }) {
    return OfficeState(
      products: products ?? this.products,
      services: services ?? this.services,
      departments: departments ?? this.departments,
    );
  }
}

/// Office notifier - manages business simulation state
class OfficeNotifier extends Notifier<OfficeState> {
  @override
  OfficeState build() {
    // Initial state with defaults
    return const OfficeState();
  }

  /// Add a new product
  void addProduct(String product) {
    state = state.copyWith(
      products: [...state.products, product],
    );
  }

  /// Add a new service
  void addService(String service) {
    state = state.copyWith(
      services: [...state.services, service],
    );
  }

  /// Add a new department
  void addDepartment(String department) {
    state = state.copyWith(
      departments: [...state.departments, department],
    );
  }
}

/// Provider for office state
final officeProvider = NotifierProvider<OfficeNotifier, OfficeState>(
  OfficeNotifier.new,
);
