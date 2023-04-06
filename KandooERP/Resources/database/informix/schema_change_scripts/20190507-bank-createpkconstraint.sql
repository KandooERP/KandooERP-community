--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: bank
--# author: ericv
--# date: 2019-05-06
--# Ticket # : 4
--# 

create unique index u_bank on bank(bank_code,cmpy_code);
ALTER TABLE bank ADD CONSTRAINT PRIMARY KEY ( bank_code,cmpy_code)
CONSTRAINT pk_bank;
