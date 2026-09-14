#pragma once
#if defined(_WIN32)
  #include <windows.h>
  #include <wincrypt.h>
  // Undefine conflicting Windows CryptoAPI macros that clash with OpenSSL structs/typedefs
  #ifdef X509_NAME
    #undef X509_NAME
  #endif
  #ifdef X509_CERT_PAIR
    #undef X509_CERT_PAIR
  #endif
  #ifdef X509_EXTENSIONS
    #undef X509_EXTENSIONS
  #endif
  #ifdef PKCS7_ISSUER_AND_SERIAL
    #undef PKCS7_ISSUER_AND_SERIAL
  #endif
  #ifdef OCSP_REQUEST
    #undef OCSP_REQUEST
  #endif
  #ifdef OCSP_RESPONSE
    #undef OCSP_RESPONSE
  #endif
#endif
