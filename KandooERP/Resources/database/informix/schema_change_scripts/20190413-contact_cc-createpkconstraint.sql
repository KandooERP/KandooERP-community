--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: contact_cc
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE contact_cc ADD CONSTRAINT PRIMARY KEY (
contact_id,
cc_id,
role_code,
valid_from,
valid_to
) CONSTRAINT pk_contact_cc;
