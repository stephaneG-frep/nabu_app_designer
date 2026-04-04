import 'package:intl/intl.dart';

class Formatters {
  static final DateFormat _projectDate = DateFormat('dd/MM/yyyy HH:mm');

  static String formatProjectDate(DateTime date) => _projectDate.format(date);
}
