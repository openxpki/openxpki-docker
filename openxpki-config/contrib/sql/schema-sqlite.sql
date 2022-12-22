--
-- Created by SQL::Translator::Producer::SQLite
-- Created on Wed Nov  9 02:25:41 2016
--

BEGIN TRANSACTION;

--
-- Table: aliases
--
DROP TABLE IF EXISTS aliases;

CREATE TABLE aliases (
  identifier varchar(64),
  pki_realm varchar(255) NOT NULL,
  alias varchar(255) NOT NULL,
  group_id varchar(255),
  generation smallint,
  notafter integer,
  notbefore integer,
  PRIMARY KEY (pki_realm, alias)
);

--
-- Table: application_log
--
DROP TABLE IF EXISTS application_log;

CREATE TABLE application_log (
  application_log_id INTEGER PRIMARY KEY NOT NULL,
  logtimestamp decimal(20,5),
  workflow_id decimal(49,0) NOT NULL,
  priority integer DEFAULT 0,
  category varchar(255) NOT NULL,
  message longtext
);

--
-- Table: audittrail
--
DROP TABLE IF EXISTS audittrail;

CREATE TABLE audittrail (
  audittrail_key INTEGER PRIMARY KEY NOT NULL,
  logtimestamp  decimal(20,5),
  category varchar(255),
  loglevel varchar(255),
  message text
);

--
-- Table: certificate
--
DROP TABLE IF EXISTS certificate;

CREATE TABLE certificate (
  pki_realm varchar(255),
  issuer_dn varchar(1000),
  cert_key decimal(49,0) NOT NULL,
  issuer_identifier varchar(64) NOT NULL,
  identifier varchar(64),
  subject varchar(1000),
  status varchar(255),
  subject_key_identifier varchar(255),
  authority_key_identifier varchar(255),
  notbefore integer,
  notafter integer,
  revocation_time decimal(49,0),
  invalidity_time decimal(49,0),
  reason_code varchar(50),
  hold_instruction_code varchar(50),
  req_key bigint,
  data longtext,
  PRIMARY KEY (issuer_identifier, cert_key)
);

--
-- Table: certificate_attributes
--
DROP TABLE IF EXISTS certificate_attributes;

CREATE TABLE certificate_attributes (
  identifier varchar(64) NOT NULL,
  attribute_key bigint NOT NULL,
  attribute_contentkey varchar(255),
  attribute_value varchar(4000),
  PRIMARY KEY (attribute_key, identifier)
);

--
-- Table: crl
--
DROP TABLE IF EXISTS crl;

CREATE TABLE crl (
  pki_realm varchar(255) NOT NULL,
  issuer_identifier varchar(64) NOT NULL,
  profile varchar(64),
  crl_key decimal(49,0) NOT NULL,
  crl_number decimal(49,0),
  items integer,
  data longtext,
  last_update integer,
  next_update integer,
  publication_date integer,
  PRIMARY KEY (issuer_identifier, crl_key)
);

--
-- Table: csr
--
DROP TABLE IF EXISTS csr;

CREATE TABLE csr (
  req_key bigint NOT NULL,
  pki_realm varchar(255) NOT NULL,
  format varchar(25),
  profile varchar(255),
  subject varchar(1000),
  data longtext,
  PRIMARY KEY (pki_realm, req_key)
);

--
-- Table: csr_attributes
--
DROP TABLE IF EXISTS csr_attributes;

CREATE TABLE csr_attributes (
  attribute_key bigint NOT NULL,
  pki_realm varchar(255) NOT NULL,
  req_key decimal(49,0) NOT NULL,
  attribute_contentkey varchar(255),
  attribute_value longtext,
  attribute_source text,
  PRIMARY KEY (attribute_key, pki_realm, req_key)
);

--
-- Table: datapool
--
DROP TABLE IF EXISTS datapool;

CREATE TABLE datapool (
  pki_realm varchar(255) NOT NULL,
  namespace varchar(255) NOT NULL,
  datapool_key varchar(255) NOT NULL,
  datapool_value longtext,
  encryption_key varchar(255),
  access_key varchar(255),
  notafter integer,
  last_update integer,
  PRIMARY KEY (pki_realm, namespace, datapool_key)
);

--
-- Table: secret
--
DROP TABLE IF EXISTS secret;

CREATE TABLE secret (
  pki_realm varchar(255) NOT NULL,
  group_id varchar(255) NOT NULL,
  data longtext,
  PRIMARY KEY (pki_realm, group_id)
);

--
-- Table: backend_session
--
DROP TABLE IF EXISTS backend_session;

CREATE TABLE backend_session (
  session_id varchar(255) NOT NULL,
  data longtext,
  created decimal(49,0) NOT NULL,
  modified decimal(49,0) NOT NULL,
  ip_address varchar(45),
  PRIMARY KEY (session_id)
);

--
-- Table: frontend_session
--
DROP TABLE IF EXISTS frontend_session;

CREATE TABLE frontend_session (
  session_id varchar(255) NOT NULL,
  data longtext,
  created decimal(49,0) NOT NULL,
  modified decimal(49,0) NOT NULL,
  ip_address varchar(45),
  PRIMARY KEY (session_id)
);

--
-- Table: seq_application_log
--
DROP TABLE IF EXISTS seq_application_log;

CREATE TABLE seq_application_log (
  seq_number INTEGER PRIMARY KEY NOT NULL,
  dummy integer
);

--
-- Table: seq_audittrail
--
DROP TABLE IF EXISTS seq_audittrail;

CREATE TABLE seq_audittrail (
  seq_number INTEGER PRIMARY KEY NOT NULL,
  dummy integer
);

--
-- Table: seq_certificate
--
DROP TABLE IF EXISTS seq_certificate;

CREATE TABLE seq_certificate (
  seq_number INTEGER PRIMARY KEY NOT NULL,
  dummy integer
);

--
-- Table: seq_certificate_attributes
--
DROP TABLE IF EXISTS seq_certificate_attributes;

CREATE TABLE seq_certificate_attributes (
  seq_number INTEGER PRIMARY KEY NOT NULL,
  dummy integer
);

--
-- Table: seq_crl
--
DROP TABLE IF EXISTS seq_crl;

CREATE TABLE seq_crl (
  seq_number INTEGER PRIMARY KEY NOT NULL,
  dummy integer
);

--
-- Table: seq_csr
--
DROP TABLE IF EXISTS seq_csr;

CREATE TABLE seq_csr (
  seq_number INTEGER PRIMARY KEY NOT NULL,
  dummy integer
);

--
-- Table: seq_csr_attributes
--
DROP TABLE IF EXISTS seq_csr_attributes;

CREATE TABLE seq_csr_attributes (
  seq_number INTEGER PRIMARY KEY NOT NULL,
  dummy integer
);

--
-- Table: seq_secret
--
DROP TABLE IF EXISTS seq_secret;

CREATE TABLE seq_secret (
  seq_number INTEGER PRIMARY KEY NOT NULL,
  dummy integer
);

--
-- Table: seq_workflow
--
DROP TABLE IF EXISTS seq_workflow;

CREATE TABLE seq_workflow (
  seq_number INTEGER PRIMARY KEY NOT NULL,
  dummy integer
);

--
-- Table: seq_workflow_history
--
DROP TABLE IF EXISTS seq_workflow_history;

CREATE TABLE seq_workflow_history (
  seq_number INTEGER PRIMARY KEY NOT NULL,
  dummy integer
);

--
-- Table: workflow
--
DROP TABLE IF EXISTS workflow;

CREATE TABLE workflow (
  workflow_id INTEGER PRIMARY KEY NOT NULL,
  pki_realm varchar(255),
  workflow_type varchar(255),
  workflow_state varchar(255),
  workflow_last_update timestamp NOT NULL,
  workflow_proc_state varchar(32),
  workflow_wakeup_at integer,
  workflow_count_try integer,
  workflow_reap_at integer,
  workflow_archive_at integer,
  workflow_session longtext,
  watchdog_key varchar(64)
);

--
-- Table: workflow_attributes
--
DROP TABLE IF EXISTS workflow_attributes;

CREATE TABLE workflow_attributes (
  workflow_id bigint NOT NULL,
  attribute_contentkey varchar(255) NOT NULL,
  attribute_value varchar(4000),
  PRIMARY KEY (workflow_id, attribute_contentkey)
);

--
-- Table: workflow_context
--
DROP TABLE IF EXISTS workflow_context;

CREATE TABLE workflow_context (
  workflow_id bigint NOT NULL,
  workflow_context_key varchar(255) NOT NULL,
  workflow_context_value longtext,
  PRIMARY KEY (workflow_id, workflow_context_key)
);

--
-- Table: workflow_history
--
DROP TABLE IF EXISTS workflow_history;

CREATE TABLE workflow_history (
  workflow_hist_id INTEGER PRIMARY KEY NOT NULL,
  workflow_id bigint,
  workflow_action varchar(255),
  workflow_description longtext,
  workflow_state varchar(255),
  workflow_user varchar(255),
  workflow_node varchar(64),
  workflow_history_date timestamp NOT NULL
);

CREATE TABLE ocsp_responses (
  identifier               varchar(64),
  serial_number            blob NOT NULL,
  authority_key_identifier blob NOT NULL,
  body                     blob NOT NULL,
  expiry                   timestamp,
  PRIMARY KEY(serial_number, authority_key_identifier)
);

COMMIT;
