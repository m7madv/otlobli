package com.otlobli.shamcashlistener;

import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;

import java.nio.charset.StandardCharsets;
import java.security.KeyStore;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

final class SecretStore {
    private static final String ANDROID_KEYSTORE = "AndroidKeyStore";
    private static final String KEY_ALIAS = "otlobli_shamcash_config_wrap_v1";
    private static final String TRANSFORMATION = "AES/GCM/NoPadding";
    private static final String FORMAT_PREFIX = "v1.";
    private static final byte[] ASSOCIATED_DATA =
        "com.otlobli.shamcashlistener:webhook-secret:v1".getBytes(StandardCharsets.UTF_8);

    private SecretStore() {}

    static synchronized String encrypt(String plaintext) throws Exception {
        SecretKey key = getOrCreateKey();
        Cipher cipher = Cipher.getInstance(TRANSFORMATION);
        cipher.init(Cipher.ENCRYPT_MODE, key);
        cipher.updateAAD(ASSOCIATED_DATA);
        byte[] ciphertext = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
        return FORMAT_PREFIX
            + Base64.encodeToString(cipher.getIV(), Base64.NO_WRAP) + "."
            + Base64.encodeToString(ciphertext, Base64.NO_WRAP);
    }

    static synchronized String decrypt(String encoded) throws Exception {
        if (encoded == null || !encoded.startsWith(FORMAT_PREFIX)) {
            throw new IllegalArgumentException("unsupported secret format");
        }
        String[] parts = encoded.split("\\.", 3);
        if (parts.length != 3) throw new IllegalArgumentException("invalid secret envelope");

        byte[] iv = Base64.decode(parts[1], Base64.NO_WRAP);
        byte[] ciphertext = Base64.decode(parts[2], Base64.NO_WRAP);
        Cipher cipher = Cipher.getInstance(TRANSFORMATION);
        cipher.init(Cipher.DECRYPT_MODE, getExistingKey(), new GCMParameterSpec(128, iv));
        cipher.updateAAD(ASSOCIATED_DATA);
        return new String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8);
    }

    private static SecretKey getOrCreateKey() throws Exception {
        KeyStore keyStore = loadKeyStore();
        if (keyStore.containsAlias(KEY_ALIAS)) {
            return (SecretKey) keyStore.getKey(KEY_ALIAS, null);
        }

        try {
            return generateKey(256);
        } catch (Exception firstFailure) {
            // Some older vendor keystores reject 256-bit AES even when the API is present.
            keyStore.deleteEntry(KEY_ALIAS);
            return generateKey(128);
        }
    }

    private static SecretKey getExistingKey() throws Exception {
        KeyStore keyStore = loadKeyStore();
        if (!keyStore.containsAlias(KEY_ALIAS)) {
            throw new IllegalStateException("secret wrapping key is missing");
        }
        return (SecretKey) keyStore.getKey(KEY_ALIAS, null);
    }

    private static SecretKey generateKey(int keySize) throws Exception {
        KeyGenerator generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE);
        generator.init(new KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(keySize)
            .setUserAuthenticationRequired(false)
            .build());
        return generator.generateKey();
    }

    private static KeyStore loadKeyStore() throws Exception {
        KeyStore keyStore = KeyStore.getInstance(ANDROID_KEYSTORE);
        keyStore.load(null);
        return keyStore;
    }
}
