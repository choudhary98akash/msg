class AppConstants {
  static const String appName = 'M.S. Group Properties';
  static const String companyName = 'M.S. Group Properties';
  static const String companyAddress = '';
  static const String companyPhone = '';
  static const String companyEmail = '';

  static const List<String> paymentModes = [
    'Cash',
    'Bank Transfer',
    'Cheque',
    'UPI',
    'DD',
    'RTGS',
    'NEFT',
  ];

  static const List<String> paymentTypes = [
    'Token',
    'Down Payment',
    'EMI',
    'Final Payment',
    'Other',
  ];

  static const List<String> idProofTypes = [
    'Aadhar Card',
    'PAN Card',
    'Voter ID',
    'Driving License',
    'Passport',
    'Ration Card',
  ];

  static const List<String> relationTypes = [
    'Father',
    'Mother',
    'Spouse',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Other',
  ];

  static const double minEmiAmount = 100.0;
  static const int maxEmiMonths = 360;
  static const int defaultQuotationValidityDays = 30;

  static const Map<String, String> statusLabels = {
    'active': 'Active',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
    'pending': 'Pending',
    'accepted': 'Accepted',
    'expired': 'Expired',
    'rejected': 'Rejected',
  };
}
