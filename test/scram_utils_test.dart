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

import 'package:crowleys_cloud/shared/utils/scram_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScramUtils', () {
    test(
      'matches OpenSSL test vector for Argon2id key derivation and keys',
      () async {
        const password = 'pencil';
        const saltHex = '0102030405060708090a0b0c0d0e0f10';
        const memCostKb = 19456;
        const timeCost = 2;
        const lanes = 1;

        final saltedPassword = await ScramUtils.deriveArgon2id(
          password.codeUnits,
          ScramUtils.hexToBytes(saltHex),
          memCostKb: memCostKb,
          timeCost: timeCost,
          lanes: lanes,
        );

        expect(
          ScramUtils.bytesToHex(saltedPassword),
          '802b124da21836ed1c1ac795287da053047c99e90854e2f189e622efadb020db',
        );

        final keys = await ScramUtils.generateArgon2idRegistrationKeys(
          password,
          memCostKb: memCostKb,
          timeCost: timeCost,
          lanes: lanes,
          saltHex: saltHex,
        );

        expect(keys.storedKeyHex.length, 64);
        expect(keys.serverKeyHex.length, 64);
        expect(keys.kdf, 'argon2id');
      },
    );

    test('computes valid Argon2id client proof and server signature', () async {
      const username = 'admin';
      const password = 'pencil';
      const nonce = 'r12345';
      const saltHex = '0102030405060708090a0b0c0d0e0f10';
      const memCostKb = 19456;
      const timeCost = 2;
      const lanes = 1;

      final authMessage = ScramUtils.scramArgon2idAuthMessage(
        username,
        nonce,
        saltHex,
        memCostKb,
        timeCost,
        lanes,
      );
      expect(
        authMessage,
        'n=admin,r=r12345,s=0102030405060708090a0b0c0d0e0f10,k=argon2id,m=19456,t=2,p=1',
      );

      final proofResult = await ScramUtils.computeArgon2idProof(
        password: password,
        saltHex: saltHex,
        memCostKb: memCostKb,
        timeCost: timeCost,
        lanes: lanes,
        authMessage: authMessage,
      );

      expect(proofResult.clientProofHex.length, 64);
      expect(proofResult.expectedServerSignatureHex.length, 64);
    });

    test('matches OpenSSL / RFC test vectors for PBKDF2 and SCRAM keys', () {
      const password = 'pencil';
      const saltHex = '0102030405060708090a0b0c0d0e0f10';
      const iterations = 4096;

      final keys = ScramUtils.generateRegistrationKeys(
        password,
        iterations: iterations,
        saltHex: saltHex,
      );

      expect(
        keys.storedKeyHex,
        '07d31bf134a40ecbe975d4c3d010e6483a49028d3cfa0bcaf33712086463099c',
      );
      expect(
        keys.serverKeyHex,
        'd33e248e09dd4722509c0f771ed604dfbe85d6f303239f503359c370fcaef11c',
      );
    });

    test('computes valid client proof and server signature', () {
      const username = 'admin';
      const password = 'pencil';
      const nonce = 'r12345';
      const saltHex = '0102030405060708090a0b0c0d0e0f10';
      const iterations = 4096;

      final authMessage = ScramUtils.scramAuthMessage(
        username,
        nonce,
        saltHex,
        iterations,
      );
      expect(
        authMessage,
        'n=admin,r=r12345,s=0102030405060708090a0b0c0d0e0f10,i=4096',
      );

      final proofResult = ScramUtils.computeProof(
        password: password,
        saltHex: saltHex,
        iterations: iterations,
        authMessage: authMessage,
      );

      expect(proofResult.clientProofHex.length, 64);
      expect(proofResult.expectedServerSignatureHex.length, 64);
    });

    test('hex encode and decode roundtrip', () {
      final randomHex = ScramUtils.generateRandomHex(16);
      expect(randomHex.length, 32);

      final bytes = ScramUtils.hexToBytes(randomHex);
      expect(bytes.length, 16);
      expect(ScramUtils.bytesToHex(bytes), randomHex);
    });
  });
}
