// ============================================================================
// Structura Nexus — WebAuthn Passkeys & Biometric Security Interop
// FIDO2 / W3C Web Authentication API for Face ID, Touch ID, & Windows Hello
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

(function () {
  const PASSKEY_STORAGE_KEY = 'structura_nexus_passkeys';

  function bufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return window.btoa(binary);
  }

  function base64ToBuffer(base64) {
    const binary = window.atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
  }

  function getStoredPasskeys() {
    try {
      const raw = localStorage.getItem(PASSKEY_STORAGE_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch (e) {
      return [];
    }
  }

  function saveStoredPasskeys(list) {
    try {
      localStorage.setItem(PASSKEY_STORAGE_KEY, JSON.stringify(list));
    } catch (e) {}
  }

  window.StructuraPasskey = {
    /**
     * Check if WebAuthn and Platform Authenticators (Touch ID, Face ID, Windows Hello) are available.
     */
    isSupported: async function () {
      if (typeof window === 'undefined' || !window.PublicKeyCredential) {
        return false;
      }
      try {
        if (typeof PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable === 'function') {
          return await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
        }
        return true;
      } catch (e) {
        return false;
      }
    },

    /**
     * Get any previously registered passkeys for display or autofill.
     */
    getSavedAccounts: function () {
      const keys = getStoredPasskeys();
      return JSON.stringify(keys.map(k => ({ email: k.email, displayName: k.displayName, id: k.id })));
    },

    /**
     * Register a new Passkey credential with Touch ID / Face ID / Windows Hello.
     */
    registerPasskey: async function (email, displayName) {
      if (!window.PublicKeyCredential) {
        return JSON.stringify({ success: false, error: 'WebAuthn is not supported in this browser.' });
      }

      try {
        const challenge = new Uint8Array(32);
        window.crypto.getRandomValues(challenge);

        const encoder = new TextEncoder();
        const effectiveEmail = email || 'engineer@structuranexus.io';
        const userId = encoder.encode(effectiveEmail);

        const createOptions = {
          publicKey: {
            rp: {
              name: 'Structura Nexus Workstation',
              id: (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
                ? window.location.hostname
                : window.location.hostname,
            },
            user: {
              id: userId,
              name: effectiveEmail,
              displayName: displayName || effectiveEmail,
            },
            challenge: challenge,
            pubKeyCredParams: [
              { type: 'public-key', alg: -7 },  // ES256
              { type: 'public-key', alg: -257 }, // RS256
            ],
            authenticatorSelection: {
              authenticatorAttachment: 'platform',
              userVerification: 'preferred',
              residentKey: 'preferred',
            },
            timeout: 60000,
            attestation: 'none',
          },
        };

        const credential = await navigator.credentials.create(createOptions);
        if (!credential) {
          return JSON.stringify({ success: false, error: 'Passkey creation was not completed.' });
        }

        const credId = credential.id;
        const passkeys = getStoredPasskeys();
        passkeys.push({
          id: credId,
          email: effectiveEmail,
          displayName: displayName || effectiveEmail,
          createdAt: new Date().toISOString(),
        });
        saveStoredPasskeys(passkeys);

        return JSON.stringify({
          success: true,
          credentialId: credId,
          email: effectiveEmail,
          displayName: displayName || effectiveEmail,
        });
      } catch (err) {
        console.warn('Passkey registration error:', err);
        return JSON.stringify({
          success: false,
          error: err.name === 'NotAllowedError'
            ? 'Passkey registration cancelled by user or biometric timed out.'
            : (err.message || 'Passkey creation failed.'),
        });
      }
    },

    /**
     * Authenticate using an existing Passkey via platform biometric prompt.
     */
    authenticatePasskey: async function () {
      if (!window.PublicKeyCredential) {
        return JSON.stringify({ success: false, error: 'WebAuthn is not supported in this browser.' });
      }

      try {
        const challenge = new Uint8Array(32);
        window.crypto.getRandomValues(challenge);

        const stored = getStoredPasskeys();
        const allowCredentials = stored.map(k => ({
          type: 'public-key',
          id: base64ToBuffer(k.id.replace(/-/g, '+').replace(/_/g, '/')),
        })).filter(c => c.id && c.id.byteLength > 0);

        const getOptions = {
          publicKey: {
            challenge: challenge,
            rpId: (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
              ? window.location.hostname
              : window.location.hostname,
            userVerification: 'preferred',
            timeout: 60000,
          },
        };

        if (allowCredentials.length > 0) {
          getOptions.publicKey.allowCredentials = allowCredentials;
        }

        const assertion = await navigator.credentials.get(getOptions);
        if (!assertion) {
          return JSON.stringify({ success: false, error: 'Passkey verification was not completed.' });
        }

        const matched = stored.find(k => k.id === assertion.id) || stored[stored.length - 1] || {
          email: 'passkey.engineer@structuranexus.io',
          displayName: 'Passkey Verified Engineer',
        };

        return JSON.stringify({
          success: true,
          credentialId: assertion.id,
          email: matched.email,
          displayName: matched.displayName,
        });
      } catch (err) {
        console.warn('Passkey authentication error:', err);
        return JSON.stringify({
          success: false,
          error: err.name === 'NotAllowedError'
            ? 'Biometric verification or passkey login was cancelled.'
            : (err.message || 'Passkey authentication failed.'),
        });
      }
    },
  };
})();

