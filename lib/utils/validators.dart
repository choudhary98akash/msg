class Validators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    if (phone.length > 15) {
      return 'Phone number must be less than 15 digits';
    }
    if (!RegExp(r'^[6-9]\d{9,14}$').hasMatch(phone)) {
      return 'Phone number must start with 6-9';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$').hasMatch(value.trim())) {
      return 'Invalid email format';
    }
    return null;
  }

  static String? validateDob(DateTime? value) {
    if (value == null) {
      return 'Date of birth is required';
    }
    final now = DateTime.now();
    final age = now.year - value.year;
    if (value.isAfter(now)) {
      return 'Date of birth cannot be in future';
    }
    if (age < 18) {
      return 'Age must be at least 18 years';
    }
    if (age > 100) {
      return 'Age must be less than 100 years';
    }
    return null;
  }

  static String? validateAadhar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final aadhar = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (aadhar.length != 12) {
      return 'Aadhar number must be 12 digits';
    }
    if (!RegExp(r'^\d{12}$').hasMatch(aadhar)) {
      return 'Aadhar number must contain only digits';
    }
    return null;
  }

  static String? validatePan(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final pan = value.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(pan)) {
      return 'Invalid PAN format (AAAAA0000A)';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    if (number > 999999999999999) {
      return '$fieldName is too large';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    return validatePositiveNumber(value, 'Amount');
  }

  static String? validateDownPaymentPercent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Down payment percentage is required';
    }
    final percent = double.tryParse(value);
    if (percent == null) {
      return 'Please enter a valid number';
    }
    if (percent < 0) {
      return 'Percentage cannot be negative';
    }
    if (percent > 100) {
      return 'Percentage cannot exceed 100%';
    }
    return null;
  }

  static String? validateEmiMonths(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'EMI months is required';
    }
    final months = int.tryParse(value);
    if (months == null) {
      return 'Please enter a valid number';
    }
    if (months < 1) {
      return 'EMI months must be at least 1';
    }
    if (months > 360) {
      return 'EMI months cannot exceed 360';
    }
    return null;
  }

  static String? validateEmiAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'EMI amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }
    if (amount < 100) {
      return 'Minimum EMI amount is ₹100';
    }
    return null;
  }

  static String? validatePlotNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Plot number is required';
    }
    if (value.trim().length > 20) {
      return 'Plot number is too long';
    }
    return null;
  }

  static String? validateDimension(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final dimension = double.tryParse(value);
    if (dimension == null) {
      return 'Please enter a valid number';
    }
    if (dimension <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  static String? validateRate(String? value) {
    return validatePositiveNumber(value, 'Rate per Gaj');
  }
}
