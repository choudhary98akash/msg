class AmountToWords {
  static const List<String> units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const List<String> tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String convert(double amount) {
    if (amount == 0) return 'Zero';

    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();

    String result = _convertRupees(rupees);
    
    if (paise > 0) {
      result += ' and ${_convertRupees(paise)} Paise';
    }
    
    return result.trim();
  }

  static String _convertRupees(int number) {
    if (number == 0) return 'Zero';
    
    if (number < 0) return 'Minus ${_convertRupees(number.abs())}';

    String words = '';

    if (number >= 10000000) {
      words += '${_convertRupees(number ~/ 10000000)} Crore ';
      number %= 10000000;
    }

    if (number >= 100000) {
      words += '${_convertRupees(number ~/ 100000)} Lakh ';
      number %= 100000;
    }

    if (number >= 1000) {
      words += '${_convertRupees(number ~/ 1000)} Thousand ';
      number %= 1000;
    }

    if (number >= 100) {
      words += '${_convertRupees(number ~/ 100)} Hundred ';
      number %= 100;
    }

    if (number >= 20) {
      words += '${tens[number ~/ 10]}';
      if (number % 10 != 0) {
        words += ' ${units[number % 10]}';
      }
    } else if (number > 0) {
      words += units[number];
    }

    return words.trim();
  }

  static String convertWithCurrency(double amount) {
    return '${convert(amount)} Only';
  }
}
