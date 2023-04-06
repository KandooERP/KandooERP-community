--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: contact_role
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE contact_role ADD CONSTRAINT PRIMARY KEY (
role_code,
contact_id,
valid_from,
valid_to
) CONSTRAINT pk_contact_role;
