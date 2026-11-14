// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography_plus/cryptography_plus.dart'
    show Argon2id, SecretKey;

/// Utilities for SCRAM client authentication using Argon2id or PBKDF2.
class ScramRegistrationKeys {
  const ScramRegistrationKeys({
    required this.saltHex,
    required this.storedKeyHex,
    required this.serverKeyHex,
    this.kdf = 'argon2id',
    this.iterations = 4096,
    this.memCostKb = 19456,
    this.timeCost = 2,
    this.lanes = 1,
  });

  final String saltHex;
  final String storedKeyHex;
  final String serverKeyHex;
  final String kdf;
  final int iterations;
  final int memCostKb;
  final int timeCost;
  final int lanes;
}

class ScramClientProofResult {
  const ScramClientProofResult({
    required this.clientProofHex,
    required this.expectedServerSignatureHex,
  });

  final String clientProofHex;
  final String expectedServerSignatureHex;
}

class ScramUtils {
  static const int defaultIterations = 4096;
  static const int defaultArgon2MemCostKb = 19456;
  static const int defaultArgon2TimeCost = 2;
  static const int defaultArgon2Lanes = 1;

  /// Generates a cryptographically secure hex string of the given byte length.
  static String generateRandomHex([int byteCount = 16]) {
    final random = Random.secure();
    final bytes = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytesToHex(bytes);
  }

  /// Converts a hexadecimal string to raw bytes.
  static Uint8List hexToBytes(String hex) {
    final cleanHex = hex.trim();
    final len = cleanHex.length;
    if (len % 2 != 0) {
      throw ArgumentError('Invalid hex string length');
    }
    final result = Uint8List(len ~/ 2);
    for (var i = 0; i < len; i += 2) {
      result[i ~/ 2] = int.parse(cleanHex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  /// Converts bytes to a lowercase hexadecimal string.
  static String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Derives a 32-byte key using PBKDF2-HMAC-SHA256.
  static Uint8List pbkdf2Sha256(
    List<int> passwordBytes,
    List<int> saltBytes,
    int iterations, [
    int keyLen = 32,
  ]) {
    final hmac = Hmac(sha256, passwordBytes);
    final initialBlock = Uint8List(saltBytes.length + 4);
    initialBlock.setRange(0, saltBytes.length, saltBytes);
    // Block index 1 in big-endian
    initialBlock[saltBytes.length + 3] = 1;

    var u = Uint8List.fromList(hmac.convert(initialBlock).bytes);
    final result = Uint8List.fromList(u);

    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var k = 0; k < 32; k++) {
        result[k] ^= u[k];
      }
    }
    return result;
  }

  /// Derives a 32-byte key using Argon2id.
  static Future<Uint8List> deriveArgon2id(
    List<int> passwordBytes,
    List<int> saltBytes, {
    int memCostKb = defaultArgon2MemCostKb,
    int timeCost = defaultArgon2TimeCost,
    int lanes = defaultArgon2Lanes,
    int hashLength = 32,
  }) async {
    final argon2 = Argon2id(
      memory: memCostKb,
      iterations: timeCost,
      parallelism: lanes,
      hashLength: hashLength,
    );
    final secretKey = await argon2.deriveKey(
      secretKey: SecretKey(passwordBytes),
      nonce: saltBytes,
    );
    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Constructs the standard SCRAM-SHA-256 authentication message.
  static String scramAuthMessage(
    String username,
    String nonce,
    String saltHex,
    int iterations,
  ) {
    return 'n=$username,r=$nonce,s=$saltHex,i=$iterations';
  }

  /// Constructs the SCRAM-Argon2id authentication message.
  static String scramArgon2idAuthMessage(
    String username,
    String nonce,
    String saltHex,
    int memCostKb,
    int timeCost,
    int lanes,
  ) {
    return 'n=$username,r=$nonce,s=$saltHex,k=argon2id,m=$memCostKb,t=$timeCost,p=$lanes';
  }

  /// Generates SCRAM registration keys using Argon2id.
  static Future<ScramRegistrationKeys> generateArgon2idRegistrationKeys(
    String password, {
    int memCostKb = defaultArgon2MemCostKb,
    int timeCost = defaultArgon2TimeCost,
    int lanes = defaultArgon2Lanes,
    String? saltHex,
  }) async {
    final salt = saltHex ?? generateRandomHex(16);
    final saltBytes = hexToBytes(salt);
    final saltedPassword = await deriveArgon2id(
      utf8.encode(password),
      saltBytes,
      memCostKb: memCostKb,
      timeCost: timeCost,
      lanes: lanes,
    );

    final clientHmac = Hmac(sha256, saltedPassword);
    final clientKey = Uint8List.fromList(
      clientHmac.convert(utf8.encode('Client Key')).bytes,
    );

    final storedKey = Uint8List.fromList(sha256.convert(clientKey).bytes);

    final serverHmac = Hmac(sha256, saltedPassword);
    final serverKey = Uint8List.fromList(
      serverHmac.convert(utf8.encode('Server Key')).bytes,
    );

    return ScramRegistrationKeys(
      saltHex: salt,
      kdf: 'argon2id',
      memCostKb: memCostKb,
      timeCost: timeCost,
      lanes: lanes,
      storedKeyHex: bytesToHex(storedKey),
      serverKeyHex: bytesToHex(serverKey),
    );
  }

  /// Generates legacy SCRAM registration keys using PBKDF2.
  static ScramRegistrationKeys generateRegistrationKeys(
    String password, {
    int iterations = defaultIterations,
    String? saltHex,
  }) {
    final salt = saltHex ?? generateRandomHex(16);
    final saltBytes = hexToBytes(salt);
    final saltedPassword = pbkdf2Sha256(
      utf8.encode(password),
      saltBytes,
      iterations,
      32,
    );

    final clientHmac = Hmac(sha256, saltedPassword);
    final clientKey = Uint8List.fromList(
      clientHmac.convert(utf8.encode('Client Key')).bytes,
    );

    final storedKey = Uint8List.fromList(sha256.convert(clientKey).bytes);

    final serverHmac = Hmac(sha256, saltedPassword);
    final serverKey = Uint8List.fromList(
      serverHmac.convert(utf8.encode('Server Key')).bytes,
    );

    return ScramRegistrationKeys(
      saltHex: salt,
      kdf: 'sha-256',
      iterations: iterations,
      storedKeyHex: bytesToHex(storedKey),
      serverKeyHex: bytesToHex(serverKey),
    );
  }

  /// Computes the SCRAM client proof and expected server signature using Argon2id.
  static Future<ScramClientProofResult> computeArgon2idProof({
    required String password,
    required String saltHex,
    required int memCostKb,
    required int timeCost,
    required int lanes,
    required String authMessage,
  }) async {
    final saltBytes = hexToBytes(saltHex);
    final saltedPassword = await deriveArgon2id(
      utf8.encode(password),
      saltBytes,
      memCostKb: memCostKb,
      timeCost: timeCost,
      lanes: lanes,
    );

    final clientHmac = Hmac(sha256, saltedPassword);
    final clientKey = Uint8List.fromList(
      clientHmac.convert(utf8.encode('Client Key')).bytes,
    );

    final storedKey = Uint8List.fromList(sha256.convert(clientKey).bytes);

    final storedHmac = Hmac(sha256, storedKey);
    final clientSignature = Uint8List.fromList(
      storedHmac.convert(utf8.encode(authMessage)).bytes,
    );

    final clientProof = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      clientProof[i] = clientKey[i] ^ clientSignature[i];
    }

    final serverHmac = Hmac(sha256, saltedPassword);
    final serverKey = Uint8List.fromList(
      serverHmac.convert(utf8.encode('Server Key')).bytes,
    );

    final sigHmac = Hmac(sha256, serverKey);
    final serverSignature = Uint8List.fromList(
      sigHmac.convert(utf8.encode(authMessage)).bytes,
    );

    return ScramClientProofResult(
      clientProofHex: bytesToHex(clientProof),
      expectedServerSignatureHex: bytesToHex(serverSignature),
    );
  }

  /// Computes the legacy SCRAM client proof and expected server signature using PBKDF2.
  static ScramClientProofResult computeProof({
    required String password,
    required String saltHex,
    required int iterations,
    required String authMessage,
  }) {
    final saltBytes = hexToBytes(saltHex);
    final saltedPassword = pbkdf2Sha256(
      utf8.encode(password),
      saltBytes,
      iterations,
      32,
    );

    final clientHmac = Hmac(sha256, saltedPassword);
    final clientKey = Uint8List.fromList(
      clientHmac.convert(utf8.encode('Client Key')).bytes,
    );

    final storedKey = Uint8List.fromList(sha256.convert(clientKey).bytes);

    final storedHmac = Hmac(sha256, storedKey);
    final clientSignature = Uint8List.fromList(
      storedHmac.convert(utf8.encode(authMessage)).bytes,
    );

    final clientProof = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      clientProof[i] = clientKey[i] ^ clientSignature[i];
    }

    final serverHmac = Hmac(sha256, saltedPassword);
    final serverKey = Uint8List.fromList(
      serverHmac.convert(utf8.encode('Server Key')).bytes,
    );

    final sigHmac = Hmac(sha256, serverKey);
    final serverSignature = Uint8List.fromList(
      sigHmac.convert(utf8.encode(authMessage)).bytes,
    );

    return ScramClientProofResult(
      clientProofHex: bytesToHex(clientProof),
      expectedServerSignatureHex: bytesToHex(serverSignature),
    );
  }
}
