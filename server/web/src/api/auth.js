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

import { apiGet, apiPost, ApiError } from './client.js';
import {
  generateRandomHex,
  scramAuthMessage,
  scramArgon2idAuthMessage,
  scramArgon2idGenerateKeys,
  scramArgon2idComputeProof,
  scramGenerateKeys,
  scramComputeProof
} from '../utils/scram.js';

export const authApi = {
  async login({ username, password }) {
    const clientNonce = generateRandomHex(16);
    let challenge = null;
    try {
      challenge = await apiGet(`/api/auth/challenge?username=${encodeURIComponent(username)}&nonce=${clientNonce}`);
    } catch (e) {
      // Challenge endpoint failed or unreachable, will fallback to legacy below
    }

    if (challenge) {
      if (challenge.auth_mode === 'scram-argon2id') {
        const { salt, m, t, p, nonce, challenge_token } = challenge;
        const authMessage = scramArgon2idAuthMessage(username, nonce, salt, m, t, p);
        const proof = await scramArgon2idComputeProof(password, salt, m, t, p, authMessage);

        const res = await apiPost('/api/login', {
          username,
          nonce,
          client_proof: proof.clientProofHex,
          challenge_token
        });

        if (res && res.server_signature && res.server_signature !== proof.expectedServerSignatureHex) {
          throw new ApiError(401, 'Server signature verification failed');
        }

        return res;
      } else if (challenge.auth_mode === 'scram') {
        const { salt, iterations, nonce, challenge_token } = challenge;
        const authMessage = scramAuthMessage(username, nonce, salt, iterations);
        const proof = await scramComputeProof(password, salt, iterations, authMessage);

        const res = await apiPost('/api/login', {
          username,
          nonce,
          client_proof: proof.clientProofHex,
          challenge_token
        });

        if (res && res.server_signature && res.server_signature !== proof.expectedServerSignatureHex) {
          throw new ApiError(401, 'Server signature verification failed');
        }

        return res;
      }
    }

    // Fallback: legacy password login
    return apiPost('/api/login', { username, password });
  },

  async register({ username, password }) {
    const saltHex = generateRandomHex(16);
    const memCostKb = 19456;
    const timeCost = 2;
    const lanes = 1;
    const { storedKeyHex, serverKeyHex } = await scramArgon2idGenerateKeys(
      password,
      saltHex,
      memCostKb,
      timeCost,
      lanes
    );

    try {
      return await apiPost('/api/register', {
        username,
        kdf: 'argon2id',
        salt: saltHex,
        m: memCostKb,
        t: timeCost,
        p: lanes,
        stored_key: storedKeyHex,
        server_key: serverKeyHex
      });
    } catch (e) {
      if (e?.message && e.message.toLowerCase().includes('password are required')) {
        return apiPost('/api/register', { username, password });
      }
      throw e;
    }
  },

  async refresh(refreshToken) {
    return apiPost('/api/refresh', { refresh_token: refreshToken });
  },

  async logout(refreshToken) {
    return apiPost('/api/logout', { refresh_token: refreshToken });
  },

  async requestResetPassword(username) {
    return apiPost('/api/auth/reset-password/request', { username });
  },

  async resetPassword({ username, code, newPassword }) {
    const saltHex = generateRandomHex(16);
    const memCostKb = 19456;
    const timeCost = 2;
    const lanes = 1;
    const { storedKeyHex, serverKeyHex } = await scramArgon2idGenerateKeys(
      newPassword,
      saltHex,
      memCostKb,
      timeCost,
      lanes
    );

    return apiPost('/api/auth/reset-password/verify', {
      username,
      code,
      kdf: 'argon2id',
      salt: saltHex,
      m: memCostKb,
      t: timeCost,
      p: lanes,
      stored_key: storedKeyHex,
      server_key: serverKeyHex
    });
  },

  async changePassword(currentPasswordOrOpts, maybeNewPassword, maybeUsername) {
    let currentPassword, newPassword, username;
    if (typeof currentPasswordOrOpts === 'object' && currentPasswordOrOpts !== null) {
      currentPassword = currentPasswordOrOpts.currentPassword;
      newPassword = currentPasswordOrOpts.newPassword;
      username = currentPasswordOrOpts.username;
    } else {
      currentPassword = currentPasswordOrOpts;
      newPassword = maybeNewPassword;
      username = maybeUsername;
    }

    const clientNonce = generateRandomHex(16);
    let challenge = null;
    try {
      challenge = await apiGet(`/api/account/reauth/challenge?nonce=${clientNonce}`);
    } catch (e) {
      if (username) {
        try {
          challenge = await apiGet(`/api/auth/challenge?username=${encodeURIComponent(username)}&nonce=${clientNonce}`);
        } catch (_) {}
      }
    }

    const newSaltHex = generateRandomHex(16);
    const memCostKb = 19456;
    const timeCost = 2;
    const lanes = 1;
    const { storedKeyHex, serverKeyHex } = await scramArgon2idGenerateKeys(
      newPassword,
      newSaltHex,
      memCostKb,
      timeCost,
      lanes
    );

    const payload = {
      kdf: 'argon2id',
      salt: newSaltHex,
      m: memCostKb,
      t: timeCost,
      p: lanes,
      stored_key: storedKeyHex,
      server_key: serverKeyHex
    };

    if (challenge) {
      const challengeUsername = challenge.username || username;
      if (challenge.auth_mode === 'scram-argon2id') {
        const { salt, m, t, p, nonce, challenge_token } = challenge;
        const authMessage = scramArgon2idAuthMessage(challengeUsername, nonce, salt, m, t, p);
        const proof = await scramArgon2idComputeProof(currentPassword, salt, m, t, p, authMessage);

        payload.current_nonce = nonce;
        payload.current_client_proof = proof.clientProofHex;
        payload.current_challenge_token = challenge_token;

        const res = await apiPost('/api/account/password', payload);
        if (res && res.server_signature && res.server_signature !== proof.expectedServerSignatureHex) {
          throw new ApiError(401, 'Server signature verification failed');
        }
        return res;
      } else if (challenge.auth_mode === 'scram') {
        const { salt, iterations, nonce, challenge_token } = challenge;
        const authMessage = scramAuthMessage(challengeUsername, nonce, salt, iterations);
        const proof = await scramComputeProof(currentPassword, salt, iterations, authMessage);

        payload.current_nonce = nonce;
        payload.current_client_proof = proof.clientProofHex;
        payload.current_challenge_token = challenge_token;

        const res = await apiPost('/api/account/password', payload);
        if (res && res.server_signature && res.server_signature !== proof.expectedServerSignatureHex) {
          throw new ApiError(401, 'Server signature verification failed');
        }
        return res;
      }
    }

    // Fallback: legacy
    payload.current_password = currentPassword;
    return apiPost('/api/account/password', payload);
  }
};
