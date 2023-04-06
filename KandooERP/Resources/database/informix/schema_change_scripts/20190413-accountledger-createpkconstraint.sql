--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: accountledger
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE accountledger ADD CONSTRAINT PRIMARY KEY (
acct_code,
year_num,
period_num,
seq_num,
cmpy_code
) CONSTRAINT pk_accountledger;
