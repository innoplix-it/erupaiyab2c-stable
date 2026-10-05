class SslPinningConfig {
  SslPinningConfig._();

  static const bool enableInProductionOnly = true;

  static const List<String> allowedHosts = <String>[
    'test.erupaiya.com',
  ];

  static const List<String> sha256Fingerprints = <String>[
    'CD:8B:6D:9B:C9:33:D1:DD:E1:4C:32:A8:9A:B5:30:33:16:F7:0F:B2:EE:E9:AE:56:B9:D2:33:77:28:EF:B6:60',
  ];
}
