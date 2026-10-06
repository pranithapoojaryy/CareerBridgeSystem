import 'dart:typed_data';
import 'resume_model.dart';

abstract class ResumeTemplate {
  String get id;
  String get name;
  String get description;
  String get thumbnailAsset;

  Future<Uint8List> generatePdf(ResumeProject project);
}
