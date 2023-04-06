--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: bankdraft
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE bankdraft ADD CONSTRAINT PRIMARY KEY (
cmpy_code,
log_cheq_code,
log_bank_acct_code
) CONSTRAINT pk_bankdraft;
