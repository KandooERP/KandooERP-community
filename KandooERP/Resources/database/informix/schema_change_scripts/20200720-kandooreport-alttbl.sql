--# description: this script modifies table kandooreport for Kandoo Report Framework, add PK and index
--# dependencies:
--# tables list:  kandooreport
--# author: a.chubar
--# date: 2020-07-22
--# Ticket:

DELETE FROM kandooreport WHERE 1 = 1;
ALTER TABLE kandooreport DROP CONSTRAINT pk_kandooreport;
DROP INDEX IF EXISTS pk_kandooreport;

ALTER TABLE
	kandooreport
ADD
	(
		cmpy_code NCHAR(2) BEFORE report_code,
		country_code NCHAR(3) BEFORE report_engine
	);

CREATE UNIQUE INDEX pk_kandooreport ON kandooreport (report_code, language_code, country_code, cmpy_code) USING btree;
ALTER TABLE kandooreport ADD CONSTRAINT PRIMARY KEY (report_code, language_code, country_code, cmpy_code) CONSTRAINT pk_kandooreport;