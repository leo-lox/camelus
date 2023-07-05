class RelayAddressParser {
  static String parseAddress(String address) {
    // Check if input starts with "wss://"
    if (!address.startsWith("wss://")) {
      address = "wss://$address";
    }

    // Remove trailing slash if there is one
    if (address.endsWith("/")) {
      address = address.substring(0, address.length - 1);
    }

    // Check if input is in the correct format
    RegExp regexDomain =
        RegExp(r'^(?:wss?:\/\/)?(?:[a-z0-9-]+\.)+[a-z]{2,}(\/.*)?$');
    if (!regexDomain.hasMatch(address)) {
      throw Exception("Invalid address format $address");
    }
    if (address.endsWith("/")) {
      throw Exception("Invalid address format, tailing slash $address");
    }
    return address;
  }
}
