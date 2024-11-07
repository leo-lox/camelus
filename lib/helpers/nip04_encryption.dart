import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'dart:convert' as convert;
import 'package:kepler/kepler.dart';

/// from https://github.com/aniketambore/nostr_tools credits to him
class Nip04Encryption {
  /// Decrypts a cipher text message encrypted using AES-256-CBC encryption with a
  /// randomly generated initialization vector (IV).
  ///
  /// Parameters:
  /// - privKey: The private key to use for decryption.
  /// - pubKey: The public key to use for decryption.
  /// - cipherText: The cipher text message to decrypt, in the format
  ///   "{cipherText}?iv={iv}", where {cipherText} is the Base64-encoded encrypted
  ///   message and {iv} is the Base64-encoded IV used for encryption.
  ///
  /// Returns:
  /// - The decrypted plain text message.
  String decrypt(String privKey, String pubKey, String cipherText) {
    // Split the cipher text into the encrypted message and the IV.
    final parts = cipherText.split("?iv=");
    if (parts.length != 2) {
      throw ArgumentError("[!] Invalid cipher text format");
    }

    // Decode the encrypted message and the IV from Base64.
    final encodedText = base64.decode(parts[0]);
    final iv = base64.decode(parts[1]);

    // Generate the shared secret and use the first 32 bytes as the encryption key.
    final secretIV = Kepler.byteSecret(privKey, '02$pubKey');
    final key = Uint8List.fromList(secretIV[0]);

    // Define the decryption parameters using the key and IV.
    final params = PaddedBlockCipherParameters(
      ParametersWithIV(KeyParameter(key), iv),
      null,
    );

    // Initialize the AES-256-CBC cipher with PKCS7 padding.
    final cipherImpl =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));

    // Initialize the cipher with the decryption parameters.
    cipherImpl.init(false, params);

    // Allocate space for the decrypted output buffer.
    final outputDecodedText = Uint8List.view(
      Uint8List(encodedText.length).buffer,
      0,
      encodedText.length,
    );

    // Decrypt the encrypted message in blocks and write the decrypted bytes to
    // the output buffer.
    var offset = 0;
    while (offset < encodedText.length) {
      offset += cipherImpl.processBlock(
        encodedText,
        offset,
        outputDecodedText,
        offset,
      );
    }

    // Determine the amount of padding added to the decrypted message.
    final padCount = outputDecodedText[outputDecodedText.length - 1];

    // Strip the padding from the decrypted bytes and convert them to a string.
    final unpaddedDecodedText = utf8.decode(
      outputDecodedText.sublist(0, outputDecodedText.length - padCount),
    );

    // Return the decrypted plain text message.
    return unpaddedDecodedText;
  }

  /// Encrypts a plain text message using AES-256-CBC encryption with a randomly
  /// generated initialization vector (IV).
  ///
  /// Parameters:
  /// - privKey: The private key to use for encryption. (hex)
  /// - pubKey: The public key to use for encryption. (hex)
  /// - text: The plain text message to encrypt.
  ///
  /// Returns:
  /// - The encrypted message in the format "{cipherText}?iv={iv}", where
  ///   {cipherText} is the Base64-encoded encrypted message and {iv} is the
  ///   Base64-encoded IV used for encryption.

  String encrypt(String privKey, String pubKey, String text) {
    Uint8List uintInputText = const convert.Utf8Encoder().convert(text);

    // Generate the shared secret and use the first 32 bytes as the encryption key.
    final secretIV = Kepler.byteSecret(privKey, '02$pubKey');
    final key = Uint8List.fromList(secretIV[0]);

    // generate iv  https://stackoverflow.com/questions/63630661/aes-engine-not-initialised-with-pointycastle-securerandom
    // Generate a random 16-byte initialization vector (IV) using the Fortuna
    // random number generator.
    FortunaRandom fr = FortunaRandom();
    final sGen = Random.secure();
    fr.seed(KeyParameter(
        Uint8List.fromList(List.generate(32, (_) => sGen.nextInt(255)))));
    final iv = fr.nextBytes(16);

    // Define the encryption parameters using the key and IV.
    CipherParameters params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv), null);

    // Initialize the AES-256-CBC cipher with PKCS7 padding.
    PaddedBlockCipherImpl cipherImpl =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));

    // Initialize the cipher with the encryption parameters.
    cipherImpl.init(
      true, // means to encrypt
      params
          as PaddedBlockCipherParameters<CipherParameters?, CipherParameters?>,
    );

    // Allocate space for the encrypted output buffer.
    final outputEncodedText = Uint8List.view(
      Uint8List(uintInputText.length + 16).buffer,
      0,
      uintInputText.length + 16,
    );

    // Encrypt the plain text message in blocks and write the encrypted bytes to
    // the output buffer.
    var offset = 0;
    while (offset < uintInputText.length - 16) {
      offset += cipherImpl.processBlock(
        uintInputText,
        offset,
        outputEncodedText,
        offset,
      );
    }

    // Add padding and write the remaining encrypted bytes to the output buffer.
    offset +=
        cipherImpl.doFinal(uintInputText, offset, outputEncodedText, offset);

    // Extract the encrypted bytes from the output buffer and create a new
    // Uint8List containing only the encrypted bytes.
    final Uint8List finalEncodedText = outputEncodedText.sublist(0, offset);

    // Encode the IV as a Base64 string.
    String stringIv = convert.base64.encode(iv);

    // Encode the encrypted bytes as a Base64 string and append the IV to the end
    final cipherText =
        "${convert.base64.encode(finalEncodedText)}?iv=$stringIv";

    // Return the encrypted message.
    return cipherText;
  }
}
