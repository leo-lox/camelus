import 'dart:math';

List<String> generateSuggestions(String name) {
  var suggestions = <String>[];
  var random = Random();

  // Common prefixes and suffixes for usernames
  final prefixes = ['The', 'Cool', 'Super', 'Pro', 'Epic', 'Awesome'];
  final suffixes = ['Fan', 'Star', 'Master', 'Expert', 'Guru', 'Hero'];

  // Add year-based suggestions (current year and birth years)
  final currentYear = DateTime.now().year;
  suggestions.add('$name$currentYear');
  suggestions.add('$name${currentYear % 100}'); // Last two digits of year

  // Add common number patterns
  suggestions.add('$name${random.nextInt(90) + 10}'); // Two-digit number
  suggestions.add('$name${random.nextInt(900) + 100}'); // Three-digit number

  // Add prefix variations
  suggestions.add('${prefixes[random.nextInt(prefixes.length)]}$name');

  // Add suffix variations
  suggestions.add('$name${suffixes[random.nextInt(suffixes.length)]}');

  // Add underscore variations
  suggestions.add('${name}_${random.nextInt(99) + 1}');

  // Add character substitutions (leetspeak)
  String leetName = name
      .replaceAll('a', '4')
      .replaceAll('e', '3')
      .replaceAll('i', '1')
      .replaceAll('o', '0')
      .replaceAll('s', '5');
  suggestions.add(leetName);

  // Add a mix of prefix and suffix
  suggestions.add(
      '${prefixes[random.nextInt(prefixes.length)]}$name${random.nextInt(99)}');

  // Add a shortened version with a random number if name is long enough
  if (name.length > 3) {
    suggestions.add('${name.substring(0, 3)}${random.nextInt(999)}');
  }

  // Shuffle and return unique suggestions
  suggestions.shuffle();
  return suggestions.toSet().toList(); // Remove any duplicates
}
