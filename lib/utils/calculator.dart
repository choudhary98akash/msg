import 'dart:math';

class Calculator {
  static double calculateArea(double length, double breadth) {
    return (length * breadth) / 9;
  }

  static double calculateTotalPrice(double area, double ratePerGaj) {
    return area * ratePerGaj;
  }

  static double calculateDownPaymentAmount(double totalPrice, double downPaymentPercent) {
    return totalPrice * (downPaymentPercent / 100);
  }

  static double calculateEmiAmount(double totalPrice, double downPaymentAmount, int emiMonths) {
    if (emiMonths <= 0) return 0;
    final principalAfterDownPayment = totalPrice - downPaymentAmount;
    if (principalAfterDownPayment <= 0) return 0;
    final monthlyRate = 0.01;
    final emi = principalAfterDownPayment * monthlyRate * pow(1 + monthlyRate, emiMonths) /
        (pow(1 + monthlyRate, emiMonths) - 1);
    return emi;
  }

  static Map<String, double> calculateBooking({
    required double length,
    required double breadth,
    required double ratePerGaj,
    required double downPaymentPercent,
    required int emiMonths,
  }) {
    final area = calculateArea(length, breadth);
    final totalPrice = calculateTotalPrice(area, ratePerGaj);
    final downPaymentAmount = calculateDownPaymentAmount(totalPrice, downPaymentPercent);
    final emiAmount = calculateEmiAmount(totalPrice, downPaymentAmount, emiMonths);
    
    return {
      'area': area,
      'totalPrice': totalPrice,
      'downPaymentAmount': downPaymentAmount,
      'emiAmount': emiAmount > 0 ? emiAmount : 100,
    };
  }

  static List<Map<String, dynamic>> generateEmiSchedule({
    required double emiAmount,
    required int emiMonths,
    required DateTime startDate,
  }) {
    final schedule = <Map<String, dynamic>>[];
    var currentDate = startDate;
    
    for (var i = 1; i <= emiMonths; i++) {
      if (currentDate.day > 28) {
        final lastDayOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;
        currentDate = DateTime(
          currentDate.year,
          currentDate.month,
          min(currentDate.day, lastDayOfMonth),
        );
      }
      
      schedule.add({
        'emiNumber': i,
        'dueDate': currentDate,
        'amount': emiAmount,
      });
      
      currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
    }
    
    return schedule;
  }

  static double calculateRemainingAmount({
    required double totalPrice,
    required List<double> payments,
  }) {
    final totalPaid = payments.fold<double>(0, (sum, payment) => sum + payment);
    return max(0, totalPrice - totalPaid);
  }

  static int calculateEmiProgress({
    required int totalEmis,
    required DateTime bookingDate,
    required List<DateTime> paymentDates,
  }) {
    if (totalEmis <= 0) return 0;
    final now = DateTime.now();
    final monthsElapsed = (now.year - bookingDate.year) * 12 + 
        (now.month - bookingDate.month);
    return min(monthsElapsed, totalEmis);
  }

  static double calculateInterestAmount({
    required double principal,
    required double rate,
    required int months,
  }) {
    return principal * (rate / 100) * (months / 12);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static bool isTokenExpired(DateTime? tokenDate, int validityDays) {
    if (tokenDate == null) return false;
    return DateTime.now().isAfter(tokenDate.add(Duration(days: validityDays)));
  }
}
