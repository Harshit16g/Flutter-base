import 'package:intl/intl.dart';

class Helpers {
  static String formatDate(DateTime date, {String format = 'yyyy-MM-dd'}) {
    return DateFormat(format).format(date);
  }

  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return NumberFormat.currency(symbol: symbol).format(amount);
  }

  static String getFileExtension(String fileName) {
    return fileName.split('.').last;
  }

  static bool isImageFile(String fileName) {
    final extensions = ['jpg', 'jpeg', 'png', 'gif'];
    return extensions.contains(getFileExtension(fileName).toLowerCase());
  }
}
