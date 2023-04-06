--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: orderaccounts
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE orderaccounts ADD CONSTRAINT PRIMARY KEY (
table_name,
column_name,
ref_code,
ord_ind,
cmpy_code
) CONSTRAINT pk_orderaccounts;
