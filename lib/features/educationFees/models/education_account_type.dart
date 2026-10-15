enum EducationAccountType {
  none,
  upiId,
  bankDetails,
}

extension EducationAccountTypeLabel on EducationAccountType {
  String get label {
    switch (this) {
      case EducationAccountType.upiId:
        return 'UPI ID';
      case EducationAccountType.bankDetails:
        return 'Bank Details';
      case EducationAccountType.none:
        return 'Select Account Type';
    }
  }
}
