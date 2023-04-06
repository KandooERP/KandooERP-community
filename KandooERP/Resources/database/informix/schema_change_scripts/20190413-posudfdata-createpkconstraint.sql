--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posudfdata
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posudfdata ADD CONSTRAINT PRIMARY KEY (
tran_num,
cred_num,
inv_num,
cmpy_code
) CONSTRAINT pk_posudfdata;
