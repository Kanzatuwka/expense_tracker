import 'package:expense_tracker/features/categorization/categorization_service.dart';
import 'package:expense_tracker/features/categorization/rule_based_categorization_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categorizationServiceProvider = Provider<CategorizationService>(
  (_) => RuleBasedCategorizationService(),
);
