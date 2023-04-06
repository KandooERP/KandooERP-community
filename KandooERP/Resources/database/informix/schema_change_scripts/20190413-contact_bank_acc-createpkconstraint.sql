--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: contact_bank_acc
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE contact_bank_acc ADD CONSTRAINT PRIMARY KEY (
contact_id,
role_code,
acc_id,
valid_from,
valid_to
) CONSTRAINT pk_contact_bank_acc;
