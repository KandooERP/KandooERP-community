--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: acctxlate
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE acctxlate ADD CONSTRAINT PRIMARY KEY (
ext_acct_code,
type_ind,
cmpy_code
) CONSTRAINT pk_acctxlate;
