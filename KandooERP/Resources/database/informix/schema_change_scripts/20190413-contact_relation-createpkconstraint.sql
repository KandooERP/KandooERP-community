--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: contact_relation
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE contact_relation ADD CONSTRAINT PRIMARY KEY (
contact_id_pri,
contact_id_sec,
role_code,
valid_from,
valid_to
) CONSTRAINT pk_contact_relation;
