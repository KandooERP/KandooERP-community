--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: contact_address
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE contact_address ADD CONSTRAINT PRIMARY KEY (
contact_seed,
address_id,
role_code,
valid_from,
valid_to
) CONSTRAINT pk_contact_address;
