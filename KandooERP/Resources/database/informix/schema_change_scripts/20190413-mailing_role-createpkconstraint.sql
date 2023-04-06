--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: mailing_role
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE mailing_role ADD CONSTRAINT PRIMARY KEY (
mailing_role_code
) CONSTRAINT pk_mailing_role;
