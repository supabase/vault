#include <string.h>

#include "crypto_aead_aes_256_gcm.h"

// TOOD generate new aes256gcm key
int crypto_aead_aes_256_gcm_encrypt_detached(
    unsigned char *ciphertext,
    const unsigned char *message, size_t message_len, const unsigned char *additional_data, size_t additional_data_len,
  unsigned char nonce[crypto_aead_aes256gcm_NPUBBYTES],
    const unsigned char key[crypto_aead_aes256gcm_KEYBYTES]) {

  unsigned long long ciphertext_len;

  if (crypto_aead_aes256gcm_is_available() == 0) {
      return 1; /* Not available on this CPU */
  }

  if (crypto_aead_aes256gcm_encrypt(ciphertext, &ciphertext_len,
                              message, message_len,
                              additional_data, additional_data_len,
                              NULL, nonce, key)){
	  return 1;
}
  return 0;
}

int crypto_aead_aes_256_gcm_decrypt_detached(
    unsigned char *message, const unsigned char *ciphertext, size_t ciphertext_len,
    const unsigned char *additional_data, size_t additional_data_len, unsigned char nonce[crypto_aead_aes256gcm_NPUBBYTES],
    const unsigned char key[crypto_aead_aes256gcm_KEYBYTES]) {

  unsigned long long message_len = ciphertext_len;

  if (crypto_aead_aes256gcm_decrypt(message, &message_len,
                              NULL,
                              ciphertext, ciphertext_len,
                              additional_data,
                              additional_data_len,
                              nonce, key) != 0) {

      return -1;
      /* message forged! */
}
return 0;

}

int crypto_aead_aes_256_gcm_encrypt(
    unsigned char *ciphertext, const unsigned char *message, size_t message_len,
    const unsigned char *additional_data, size_t additional_data_len, unsigned char nonce[crypto_aead_aes256gcm_NPUBBYTES],
    const unsigned char key[crypto_aead_aes256gcm_KEYBYTES]) {
  return crypto_aead_aes_256_gcm_encrypt_detached(ciphertext, message, message_len, additional_data,
                                                    additional_data_len, nonce, key);
}

int crypto_aead_aes_256_gcm_decrypt(
    unsigned char *message, const unsigned char *ciphertext, size_t ciphertext_len,
    const unsigned char *additional_data, size_t additional_data_len, unsigned char nonce[crypto_aead_aes256gcm_NPUBBYTES],
    const unsigned char key[crypto_aead_aes256gcm_KEYBYTES]) {

  if (ciphertext_len < crypto_aead_aes256gcm_ABYTES) {
    return -1;
  }
  return crypto_aead_aes_256_gcm_decrypt_detached(message, ciphertext, ciphertext_len, additional_data,
                                                    additional_data_len, nonce, key);
}

void crypto_aead_aes_256_gcm_keygen(
    unsigned char k[crypto_aead_aes256gcm_KEYBYTES]) {
  randombytes_buf(k, crypto_aead_aes256gcm_KEYBYTES);
}

