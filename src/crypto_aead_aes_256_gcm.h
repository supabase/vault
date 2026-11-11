#ifndef crypto_aead_aes_256_gcm_H
#define crypto_aead_aes_256_gcm_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>
#include <sodium.h>

int crypto_aead_aes_256_gcm_encrypt_detached(
    unsigned char *ciphertext,
    const unsigned char *message, size_t message_len, const unsigned char *additional_data, size_t additional_data_len,
  unsigned char nonce[crypto_aead_aes256gcm_NPUBBYTES],
    const unsigned char key[crypto_aead_aes256gcm_KEYBYTES]);

int crypto_aead_aes_256_gcm_decrypt_detached(
    unsigned char *message, const unsigned char *ciphertext, size_t ciphertext_len,
    const unsigned char *additional_data, size_t additional_data_len, unsigned char nonce[crypto_aead_aes256gcm_NPUBBYTES],
    const unsigned char key[crypto_aead_aes256gcm_KEYBYTES]);

int crypto_aead_aes_256_gcm_encrypt(
    unsigned char *ciphertext, const unsigned char *message, size_t message_len,
    const unsigned char *additional_data, size_t additional_data_len, unsigned char nonce[crypto_aead_aes256gcm_NPUBBYTES],
    const unsigned char key[crypto_aead_aes256gcm_KEYBYTES]);

int crypto_aead_aes_256_gcm_decrypt(
    unsigned char *message, const unsigned char *ciphertext, size_t ciphertext_len,
    const unsigned char *additional_data, size_t additional_data_len, unsigned char nonce[crypto_aead_aes256gcm_NPUBBYTES],
    const unsigned char key[crypto_aead_aes256gcm_KEYBYTES]);

void crypto_aead_aes_256_gcm_keygen(
    unsigned char key[crypto_aead_aes256gcm_KEYBYTES]);

#ifdef __cplusplus
}
#endif

#endif

