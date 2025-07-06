class OtsoHelpers {
  static String findLongestGValue(List<List<String>> data) {
    String longest = '';

    for (var item in data) {
      if (item.length == 2 && item[0] == 'g') {
        String value = item[1];
        if (value.length > longest.length) {
          longest = value;
        }
      }
    }

    return longest;
  }
}
