SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

CREATE SEQUENCE IF NOT EXISTS seq_application_log         START WITH 0 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS seq_audittrail              START WITH 0 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS seq_certificate             START WITH 0 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS seq_certificate_attributes  START WITH 0 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS seq_crl                     START WITH 0 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS seq_csr                     START WITH 0 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS seq_csr_attributes          START WITH 0 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS seq_secret                  START WITH 0 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS seq_workflow                START WITH 0 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS seq_workflow_history        START WITH 0 INCREMENT BY 1 MINVALUE 0 NO MAXVALUE CACHE 1;

CREATE TABLE IF NOT EXISTS `aliases` (
  `identifier` varchar(64) DEFAULT NULL,
  `pki_realm` varchar(255) NOT NULL,
  `alias` varchar(255) NOT NULL,
  `group_id` varchar(255) DEFAULT NULL,
  `generation` smallint(6) DEFAULT NULL,
  `notafter` int(10) unsigned DEFAULT NULL,
  `notbefore` int(10) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `application_log` (
  `application_log_id` bigint(20) unsigned NOT NULL,
  `logtimestamp` decimal(20,5) unsigned DEFAULT NULL,
  `workflow_id` decimal(49,0) NOT NULL,
  `priority` int(11) DEFAULT '0',
  `category` varchar(255) NOT NULL,
  `message` longtext
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `audittrail` (
  `audittrail_key` bigint(20) unsigned DEFAULT (next value for seq_audittrail),
  `logtimestamp` decimal(20,5) unsigned DEFAULT NULL,
  `category` varchar(255) DEFAULT NULL,
  `loglevel` varchar(255) DEFAULT NULL,
  `message` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `certificate` (
  `pki_realm` varchar(255) DEFAULT NULL,
  `issuer_dn` varchar(1000) DEFAULT NULL,
  `cert_key` decimal(49,0) NOT NULL,
  `issuer_identifier` varchar(64) NOT NULL,
  `identifier` varchar(64) DEFAULT NULL,
  `subject` varchar(1000) DEFAULT NULL,
  `status` enum('ISSUED','HOLD','CRL_ISSUANCE_PENDING','REVOKED','UNKNOWN') DEFAULT 'UNKNOWN',
  `subject_key_identifier` varchar(255) DEFAULT NULL,
  `authority_key_identifier` varchar(255) DEFAULT NULL,
  `notbefore` int(10) unsigned DEFAULT NULL,
  `notafter` int(10) unsigned DEFAULT NULL,
  `revocation_time` int(10) unsigned DEFAULT NULL,
  `invalidity_time` int(10) unsigned DEFAULT NULL,
  `reason_code` varchar(50) DEFAULT NULL,
  `hold_instruction_code` varchar(50) DEFAULT NULL,
  `revocation_id` INT NULL DEFAULT NULL,
  `req_key` bigint(20) unsigned DEFAULT NULL,
  `data` longtext
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `certificate_attributes` (
  `identifier` varchar(64) NOT NULL,
  `attribute_key` bigint(20) unsigned NOT NULL,
  `attribute_contentkey` varchar(255) DEFAULT NULL,
  `attribute_value` varchar(4000) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `crl` (
  `pki_realm` varchar(255) NOT NULL,
  `issuer_identifier` varchar(64) NOT NULL,
  `profile` varchar(64) DEFAULT NULL,
  `crl_key` decimal(49,0) NOT NULL,
  `crl_number` decimal(49,0) DEFAULT NULL,
  `items` int(10) DEFAULT 0,
  `max_revocation_id` INT NULL DEFAULT NULL,
  `data` longtext,
  `last_update` int(10) unsigned DEFAULT NULL,
  `next_update` int(10) unsigned DEFAULT NULL,
  `publication_date` int(10) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `csr` (
  `req_key` bigint(20) unsigned NOT NULL,
  `pki_realm` varchar(255) NOT NULL,
  `format` varchar(25) DEFAULT NULL,
  `profile` varchar(255) DEFAULT NULL,
  `subject` varchar(1000) DEFAULT NULL,
  `data` longtext
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `csr_attributes` (
  `attribute_key` bigint(20) unsigned NOT NULL,
  `pki_realm` varchar(255) NOT NULL,
  `req_key` decimal(49,0) NOT NULL,
  `attribute_contentkey` varchar(255) DEFAULT NULL,
  `attribute_value` longtext,
  `attribute_source` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `datapool` (
  `pki_realm` varchar(255) NOT NULL,
  `namespace` varchar(255) NOT NULL,
  `datapool_key` varchar(255) NOT NULL,
  `datapool_value` longtext,
  `encryption_key` varchar(255) DEFAULT NULL,
  `access_key` VARCHAR(255) NULL DEFAULT NULL,
  `notafter` int(10) unsigned DEFAULT NULL,
  `last_update` int(10) unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `report` (
  `report_name` varchar(63) NOT NULL,
  `pki_realm` varchar(255) NOT NULL,
  `created` int(11) NOT NULL,
  `mime_type` varchar(63) NOT NULL,
  `description` varchar(255) NOT NULL,
  `report_value` longblob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `secret` (
  `pki_realm` varchar(255) NOT NULL,
  `group_id` varchar(255) NOT NULL,
  `data` longtext
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `backend_session` (
  `session_id` varchar(255) NOT NULL,
  `data` longtext,
  `created` int(10) unsigned NOT NULL,
  `modified` int(10) unsigned NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `frontend_session` (
  `session_id` varchar(255) NOT NULL,
  `data` longtext,
  `created` int(10) unsigned NOT NULL,
  `modified` int(10) unsigned NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `workflow` (
  `workflow_id` bigint(20) unsigned NOT NULL,
  `pki_realm` varchar(255) DEFAULT NULL,
  `workflow_type` varchar(255) DEFAULT NULL,
  `workflow_state` varchar(255) DEFAULT NULL,
  `workflow_last_update` timestamp NOT NULL,
  `workflow_proc_state` enum('init','running','manual','pause','finished','archived','failed','wakeup','resume','exception','retry_exceeded') DEFAULT 'init',
  `workflow_wakeup_at` int(10) unsigned DEFAULT NULL,
  `workflow_count_try` int(10) unsigned DEFAULT NULL,
  `workflow_reap_at` int(10) unsigned DEFAULT NULL,
  `workflow_archive_at` int(10) unsigned DEFAULT NULL,
  `workflow_session` longtext,
  `watchdog_key` varchar(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `workflow_attributes` (
  `workflow_id` bigint(20) unsigned NOT NULL,
  `attribute_contentkey` varchar(255) NOT NULL,
  `attribute_value` varchar(4000) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `workflow_context` (
  `workflow_id` bigint(20) unsigned NOT NULL,
  `workflow_context_key` varchar(255) NOT NULL,
  `workflow_context_value` longtext
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `workflow_history` (
  `workflow_hist_id` bigint(20) unsigned NOT NULL,
  `workflow_id` bigint(20) unsigned DEFAULT NULL,
  `workflow_action` varchar(255) DEFAULT NULL,
  `workflow_description` longtext,
  `workflow_state` varchar(255) DEFAULT NULL,
  `workflow_user` varchar(255) DEFAULT NULL,
  `workflow_node` varchar(64) DEFAULT NULL,
  `workflow_history_date` timestamp NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `ocsp_responses` (
  `identifier` varchar(64),
  `serial_number` varbinary(128) NOT NULL,
  `authority_key_identifier` varbinary(128) NOT NULL,
  `body` varbinary(4096) NOT NULL,
  `expiry` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `users` (
  `username` varchar(255) NOT NULL,
  `password` varchar(255) DEFAULT NULL,
  `pki_realm` varchar(255) DEFAULT NULL,
  `mail` varchar(255) NOT NULL,
  `realname` varchar(255) DEFAULT NULL,
  `role` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `aliases`
 ADD PRIMARY KEY (`pki_realm`,`alias`),
 ADD KEY `realm_group` (`pki_realm`,`group_id`);

ALTER TABLE `application_log`
 ADD PRIMARY KEY (`application_log_id`),
 ADD KEY `workflow_id` (`workflow_id`),
 ADD KEY `workflow_id_2` (`workflow_id`,`category`,`priority`);

ALTER TABLE `audittrail`
 ADD PRIMARY KEY (`audittrail_key`);

ALTER TABLE `certificate`
 ADD PRIMARY KEY (`issuer_identifier`,`cert_key`),
 ADD KEY `pki_realm` (`pki_realm`),
 ADD UNIQUE `identifier` (`identifier`),
 ADD KEY `issuer_identifier` (`issuer_identifier`),
 ADD KEY `subject` (`subject`(255)),
 ADD KEY `status` (`status`),
 ADD KEY `pki_realm_req_key` (`pki_realm`,`req_key`),
 ADD KEY `req_key` (`req_key`),
 ADD KEY `notbefore` (`notbefore`),
 ADD KEY `notafter` (`notafter`),
 ADD KEY `revocation_time` (`revocation_time`),
 ADD KEY `invalidity_time` (`invalidity_time`),
 ADD KEY `reason_code` (`reason_code`),
 ADD KEY `hold_instruction_code` (`hold_instruction_code`),
 ADD UNIQUE `revocation_id` (`revocation_id`);

ALTER TABLE `certificate_attributes`
 ADD PRIMARY KEY (`attribute_key`,`identifier`),
 ADD KEY `attribute_contentkey` (`attribute_contentkey`),
 ADD KEY `attribute_value` (`attribute_value`(255)),
 ADD KEY `identifier` (`identifier`),
 ADD KEY `identifier_2` (`identifier`,`attribute_contentkey`),
 ADD KEY `attribute_contentkey_2` (`attribute_contentkey`,`attribute_value`(255));

ALTER TABLE `crl`
 ADD PRIMARY KEY (`issuer_identifier`,`crl_key`),
 ADD KEY `issuer_identifier` (`issuer_identifier`),
 ADD KEY `profile` (`profile`),
 ADD KEY `revocation_id` (`max_revocation_id`),
 ADD KEY `pki_realm` (`pki_realm`),
 ADD KEY `issuer_identifier_2` (`issuer_identifier`,`last_update`),
 ADD KEY `crl_number` (`issuer_identifier`,`crl_number`);

ALTER TABLE `csr`
 ADD PRIMARY KEY (`pki_realm`,`req_key`),
 ADD KEY `pki_realm` (`pki_realm`),
 ADD KEY `profile` (`pki_realm`,`profile`),
 ADD KEY `subject` (`subject`(255));

ALTER TABLE `csr_attributes`
 ADD PRIMARY KEY (`attribute_key`,`pki_realm`,`req_key`),
 ADD KEY `req_key` (`req_key`),
 ADD KEY `pki_realm_req_key` (`pki_realm`,`req_key`);

ALTER TABLE `datapool`
 ADD PRIMARY KEY (`pki_realm`,`namespace`,`datapool_key`),
 ADD KEY `pki_realm` (`pki_realm`,`namespace`),
 ADD KEY `notafter` (`notafter`);

ALTER TABLE `report`
 ADD PRIMARY KEY (`report_name`,`pki_realm`);

ALTER TABLE `secret`
 ADD PRIMARY KEY (`pki_realm`,`group_id`);

ALTER TABLE `backend_session`
 ADD PRIMARY KEY (`session_id`),
 ADD INDEX(`modified`);

ALTER TABLE `frontend_session`
 ADD PRIMARY KEY (`session_id`),
 ADD INDEX(`modified`);

ALTER TABLE `workflow`
 ADD PRIMARY KEY (`workflow_id`),
 ADD KEY `pki_realm` (`pki_realm`),
 ADD KEY `pki_realm_type` (`pki_realm`,`workflow_type`),
 ADD KEY `pki_realm_state` (`pki_realm`, `workflow_state`),
 ADD KEY `workflow_proc_state` (`pki_realm`, `workflow_proc_state`),
 ADD KEY `watchdog_wakeup` (`workflow_wakeup_at`, `watchdog_key`, `workflow_proc_state`),
 ADD KEY `watchdog_reap` (`workflow_reap_at`, `watchdog_key`, `workflow_proc_state`),
 ADD KEY `watchdog_archive_at` (`workflow_archive_at`, `watchdog_key`, `workflow_proc_state`);

ALTER TABLE `workflow_attributes`
 ADD PRIMARY KEY (`workflow_id`,`attribute_contentkey`),
 ADD KEY `workflow_id` (`workflow_id`),
 ADD KEY `attribute_contentkey` (`attribute_contentkey`),
 ADD KEY `attribute_value` (`attribute_value`(255)),
 ADD KEY `attribute_contentkey_2` (`attribute_contentkey`,`attribute_value`(255));

ALTER TABLE `workflow_context`
 ADD PRIMARY KEY (`workflow_id`,`workflow_context_key`);

ALTER TABLE `workflow_history`
 ADD PRIMARY KEY (`workflow_hist_id`),
 ADD KEY `workflow_id` (`workflow_id`);

ALTER TABLE `ocsp_responses`
 ADD PRIMARY KEY (`serial_number`,`authority_key_identifier`),
 ADD KEY `identifier` (`identifier`);
