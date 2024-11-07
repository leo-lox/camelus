import 'package:objectbox/objectbox.dart';

@Entity()
class DbKeyValue {
  @Id()
  int dbId = 0;

  @Unique()
  String key = '';

  @Property()
  String value = '';

  DbKeyValue({
    required this.key,
    required this.value,
  });
}
