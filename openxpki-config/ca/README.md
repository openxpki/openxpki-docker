### Private Key Directory

**This has moved**

The default configuration now expects the *DataVault token* to be a global token shared over all realms and placed in `/etc/openxpki/local/keys/[% ALIAS %].pem` where the alias is `vault-X`.

The CA Signer and SCEP tokens are loaded into the database so there is no need to keep them on the filesystem after import, in case you want/need to hold them on the filesystem the new default location has also changed to `/etc/openxpki/local/keys/` with the default pattern of `<realm-name>/ca-signer-<X>.pem` where `<X>` is again the generation number and `<realm-name>` is the name of the realm (same as the name of the realm directory below `config.d/realm`).

Please do **NOT** copy the tokens there by hand but use this command line to load the tokens into the right place:

```bash
openxpkiadm alias --realm <realm-name> --token certsign --file signer.crt --key signer.pem
```
