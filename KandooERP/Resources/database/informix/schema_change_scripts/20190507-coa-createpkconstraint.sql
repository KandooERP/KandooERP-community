--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: coa
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_coa on coa(acct_code,cmpy_code);
ALTER TABLE coa ADD CONSTRAINT PRIMARY KEY ( acct_code,cmpy_code)
CONSTRAINT pk_coa;
