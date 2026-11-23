import 'package:flutter/foundation.dart';

/// Which bottom-navigation tab the customer shell shows.
final ValueNotifier<int> customerTab = ValueNotifier<int>(0);

/// Lets other screens (like the home hero) open the Menu on a given category.
final ValueNotifier<String?> menuCategoryRequest = ValueNotifier<String?>(null);
