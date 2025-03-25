class Prediction {
  String? id;
  String? displayName;
  String? formattedAddress;
  List<AddressComponents>? addressComponents;

  Prediction({
    this.id,
    this.displayName,
    this.formattedAddress,
    this.addressComponents,
  });

  Prediction.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    displayName = json['displayName']?['text'];

    formattedAddress = json['formattedAddress'];

    if (json['addressComponents'] != null) {
      addressComponents = [];
      json['addressComponents'].forEach((v) {
        addressComponents!.add(AddressComponents.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['id'] = id;
    data['displayName'] = displayName;
    data['formattedAddress'] = formattedAddress;
    data['addressComponents'] =
        addressComponents!.map((v) => v.toJson()).toList();

    return data;
  }
}

class AddressComponents {
  String? longText;
  String? shortText;
  List<String>? types;

  AddressComponents({this.longText, this.shortText, this.types});

  AddressComponents.fromJson(Map<String, dynamic> json) {
    longText = json['longText'];
    shortText = json['shortText'];
    types = json['types'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    data['longText'] = longText;
    data['shortText'] = shortText;
    data['types'] = types;

    return data;
  }
}
