import 'package:camelus/helpers/nevent_helper.dart';
import 'package:test/test.dart';

void main() {
  group('NeventHelper', () {
    test('mapToBech32 without pubkey', () {
      final neventHelper = NeventHelper();
      final input = {
        "eventId":
            "ea284eb12bf1168de572fe81e5de21701f037a2bca9b09833630d3e798f2ff33",
        "relays": ["wss://relay1.tld", "wss://relay2.tld"]
      };
      const expectedResult =
          "nevent1qqsw52zwky4lz95du4e0aq09mcshq8cr0g4u4xcfsvmrp5l8nre07vcpzpmhxue69uhhyetvv9unztn5d3jqzyrhwden5te0wfjkcctexgh8gmry7ekfxp";

      expect(neventHelper.mapToBech32(input), expectedResult);
    });
    test('mapToBech32 with pubkey', () {
      final neventHelper = NeventHelper();
      final input = {
        "eventId":
            "c614f08003e151720d7b98214f1d31d610689efb834c9d0c156ec5f2ef7ce355",
        "authorPubkey":
            "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
        "relays": ["wss://relay1.tld", "wss://relay2.tld"]
      };
      const expectedResult =
          "nevent1qqsvv98ssqp7z5tjp4aesg20r5cavyrgnmacxnyaps2ka30jaa7wx4gpzpmhxue69uhhyetvv9unztn5d3jqzyrhwden5te0wfjkcctexgh8gmryqgs8n0nx0muaewav2ksx99wwsu9swq5mlndjmn3gm9vl9q2mzmup0xqnr45ek";

      expect(neventHelper.mapToBech32(input), expectedResult);
    });
  });
}
