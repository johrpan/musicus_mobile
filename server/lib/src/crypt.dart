import 'dart:convert';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:steel_crypt/steel_crypt.dart';

/// Result of [hashPassword].
class HashPasswordResult {
  /// The computed hash.
  final String hash;

  /// A randomly generated string.
  final String salt;

  HashPasswordResult({
    @required this.hash,
    @required this.salt,
  });
}

/// Parameters for [checkPassword].
class CheckPasswordRequest {
  /// The password to check.
  final String password;

  /// The salt that was used for computing the hash.
  final String salt;

  /// The hash value to check against.
  final String hash;

  CheckPasswordRequest({
    @required this.password,
    @required this.salt,
    @required this.hash,
  });
}

/// Methods for handling passwords.
class Crypt {
  static final _crypt = PassCrypt('SHA-512/HMAC/PBKDF2');
  static final _rand = Random.secure();

  /// Compute a hash for a password.
  ///
  /// The result will contain the hash and a randomly generated salt.
  static HashPasswordResult hashPassword(String password) {
    final bytes = List.generate(32, (i) => _rand.nextInt(256));
    final salt = base64UrlEncode(bytes);
    final hash = _crypt.hashPass(salt, password);

    return HashPasswordResult(
      hash: hash,
      salt: salt,
    );
  }

  /// Check whether a password matches a hash value.
  static bool checkPassword(CheckPasswordRequest request) {
    return _crypt.checkPassKey(request.salt, request.password, request.hash);
  }
}
