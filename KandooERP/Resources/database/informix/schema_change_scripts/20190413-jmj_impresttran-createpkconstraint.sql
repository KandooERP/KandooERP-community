--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: jmj_impresttran
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE jmj_impresttran ADD CONSTRAINT PRIMARY KEY (
cust_code,
inv_num,
cmpy_code
) CONSTRAINT pk_jmj_impresttran;
