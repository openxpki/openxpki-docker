## System

### Session Handler

The internal session handler `openxpki` is no longer supported. We recommend to use `driver:openxpki` which is an improved version of CGI:Session::DBI. On debian, the driver is available as an extra package `openxpki-cgi-session-driver`

### Authentication

The syntax for the Authentication::ClientX509 handler has changed. The
keywords `realm` and `cacert` to set the trust anchors are now keys below
to the new node `trust_anchor`:

```yaml
trust_anchor:
    realm: user-ca
    cacert: zJovVgaxAFthT4TXDRP9VyhFrBY
```

### SCEP

The old SCEP tools dont work with OpenSSL 1.1, so if you are upgrading to
Buster you must install the libscep packages and change the config to use
the new SCEP layer. Affected files are `config.d/system/server.yaml`,
`config.d/system/crypto.yaml`, `config.d/<realm/crypto.yaml` and the SCEP
wrapper configs in `scep/`.

### ACL

The per command ACL feature is now active by default on the socket interface.
Create a node `api.acl.disabled: 1` in each realm config to keep the old
behaviour or deploy your own ACLs, see OpenXPKI::Server::API2.

## Workflow

### Enrollment (certificate_enroll)

#### Changed Class Names

Class ...SCEPv2::CalculateRequestHMAC was renamed to ...Tools::CalculateRequestHMAC

#### Workflow Parameters

For OnBehalf enrollments the `request_mode` is now set to *onbehalf* instead of *initial*. This also requires a seperate section *onbehalf* in the eligibilty section of the servers configuration::

```yaml
eligible:
    initial:
       value: 0

    renewal:
       value: 1

    onbehalf:
       value: 1
```

### Message of the Day (set_motd)

Legacy parameters used the set_motd action have been removed and need to be updated.


## Database
### Column Changes

| Column                        | Change  | DDL                                                                                                     |
| ----------------------------- | --------| -------------------------------------------------------------------------------------------------------:|
| application_log.logtimestamp  | altered | ``ALTER TABLE application_log MODIFY COLUMN `logtimestamp` decimal(20,5);``                                |
| crl.profile                   | added   | ``ALTER TABLE crl ADD COLUMN IF NOT EXISTS (`profile` varchar(64) DEFAULT NULL);``                      |
| datapool.access_key           | added   | ``ALTER TABLE datapool ADD COLUMN IF NOT EXISTS (`access_key` VARCHAR(255) NULL DEFAULT NULL);``        |
| workflow.archive_at           | added   | ``ALTER TABLE workflow ADD COLUMN IF NOT EXISTS (`workflow_archive_at` int(10) unsigned DEFAULT NULL);``|
| crl.max_revocation_id         | added   | ``ALTER TABLE crl ADD COLUMN IF NOT EXISTS (`max_revocation_id` INT NULL DEFAULT NULL);``               |
| certificate.revocation_id     | added   | ``ALTER TABLE certificate ADD COLUMN IF NOT EXISTS (`revocation_id` INT NULL DEFAULT NULL);``           |

### New Tables
- `backend_session`
- `frontend_session`

(See [see schema-mariadb.sql](https://github.com/openxpki/openxpki-config/blob/community/contrib/sql/schema-mariadb.sql) for DDLs.)

### Driver changes
Starting with the v3.8 release OpenXPKI comes with a MariaDB driver. This driver uses MariaDB internal sequences instead of emulated sequences based on tables with an autoincrement column.

To switch to MariaDB driver in `system/database.yaml`, these tables need to be migrated to native sequences.

On a standard MariaDB installation using database `openxpki` the following shell snippet should provide the necessary DDLs.
```bash
sudo mysql openxpki -sNe "show tables" |grep "^seq_" |\
  sudo xargs -n1 -I{} mysql openxpki -sNe \
  'select concat("DROP TABLE {}; CREATE SEQUENCE {} START WITH ", ifnull(max(seq_number),0)+1, " INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;") from {}'
```

_Example_ output:
```sql
DROP TABLE seq_application_log; CREATE SEQUENCE seq_application_log START WITH 11269 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
DROP TABLE seq_audittrail; CREATE SEQUENCE seq_audittrail START WITH 821 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
(..)
```
