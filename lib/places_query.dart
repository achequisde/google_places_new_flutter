sealed class PlacesQuery {
  final String query;

  PlacesQuery({required this.query});
}

class IdQuery extends PlacesQuery {
  IdQuery({
    super.query = "places.id",
  });
}

class DisplayNameQuery extends PlacesQuery {
  DisplayNameQuery({
    super.query = "places.displayName",
  });
}

class FormattedAddressQuery extends PlacesQuery {
  FormattedAddressQuery({
    super.query = "places.formattedAddress",
  });
}

class AddressComponentsQuery extends PlacesQuery {
  AddressComponentsQuery({
    super.query = "places.addressComponents",
  });
}
