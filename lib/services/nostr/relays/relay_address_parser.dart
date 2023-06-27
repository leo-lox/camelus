class RelayAddressParser {
  static parseAddress(String address) {
    // Check if input starts with "wss://"
    if (!address.startsWith("wss://")) {
      address = "wss://$address";
    }

    // Remove trailing slash if there is one
    if (address.endsWith("/")) {
      address = address.substring(0, address.length - 1);
    }

    // Check if input is in the correct format
    RegExp regex =
        RegExp(r'^wss:\/\/[a-z0-9]+(\.[a-z0-9]+)*$', caseSensitive: false);
    if (!regex.hasMatch(address)) {
      throw Exception("Invalid address format");
    }
    return address;
  }
}
