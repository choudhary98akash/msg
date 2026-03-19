import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _currencyFormatWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,##,###', 'en_IN');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  static String formatCurrency(double amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _currencyFormatWithDecimals.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String formatNumber(num number) {
    return _numberFormat.format(number);
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  static String formatPhone(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    if (phone.length == 12 && phone.startsWith('91')) {
      return '+91 ${phone.substring(2, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  static String formatArea(double area, {String unit = 'Gaj'}) {
    return '${formatNumber(area)} $unit';
  }

  static String formatPercent(double percent) {
    return '${percent.toStringAsFixed(1)}%';
  }

  static String formatPaymentType(String type) {
    switch (type.toLowerCase()) {
      case 'token':
        return 'Token Amount';
      case 'down payment':
        return 'Down Payment';
      case 'emi':
        return 'EMI';
      case 'final payment':
        return 'Final Payment';
      default:
        return type;
    }
  }

  static String formatPaymentMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'bank transfer':
        return 'Bank Transfer';
      case 'cheque':
        return 'Cheque';
      case 'upi':
        return 'UPI';
      case 'dd':
        return 'Demand Draft';
      case 'rtgs':
        return 'RTGS';
      case 'neft':
        return 'NEFT';
      default:
        return mode;
    }
  }

  static String formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'expired':
        return 'Expired';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
