import '../../core/models/user_model.dart';

class ReportModel {
  final String id;
  final UserModel reporter;
  final double latitude;
  final double longitude;
  final String type;
  final String imageUrl;
  final String status;

  ReportModel({
    required this.id,
    required this.reporter,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.imageUrl,
    required this.status,
  });
}
