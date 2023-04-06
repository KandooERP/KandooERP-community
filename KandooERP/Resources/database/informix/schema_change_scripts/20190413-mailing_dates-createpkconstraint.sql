--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: mailing_dates
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE mailing_dates ADD CONSTRAINT PRIMARY KEY (
mailing_role_code,
mail_date
) CONSTRAINT pk_mailing_dates;
