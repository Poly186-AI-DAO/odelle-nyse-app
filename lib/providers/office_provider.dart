import 'package:flutter/material.dart';

class OfficeProvider extends ChangeNotifier {
  // Game State
  final List<String> _products = ['Core Platform'];
  final List<String> _services = ['Consulting'];
  final List<String> _departments = ['Engineering', 'Sales'];

  // Getters
  List<String> get products => _products;
  List<String> get services => _services;
  List<String> get departments => _departments;

  // Derived state
  int get workerCount =>
      _products.length + _services.length + _departments.length;

  // Actions
  void addProduct(String product) {
    _products.add(product);
    notifyListeners();
  }

  void addService(String service) {
    _services.add(service);
    notifyListeners();
  }

  void addDepartment(String department) {
    _departments.add(department);
    notifyListeners();
  }
}
