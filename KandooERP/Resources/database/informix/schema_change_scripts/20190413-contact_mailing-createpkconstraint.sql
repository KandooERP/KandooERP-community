--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: contact_mailing
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE contact_mailing ADD CONSTRAINT PRIMARY KEY (
mailing_id
) CONSTRAINT pk_contact_mailing;
