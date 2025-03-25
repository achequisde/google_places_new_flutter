import 'package:google_places_new_flutter/models/prediction.dart';

class PlacesApiResponse {
  List<Prediction>? predictions;

  PlacesApiResponse.fromJson(Map<String, dynamic> json) {
    if (json['places'] != null) {
      predictions = [];

      json['places'].forEach((v) {
        predictions!.add(Prediction.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (predictions != null) {
      data['predictions'] = predictions!.map((v) => v.toJson()).toList();
    }

    return data;
  }
}
