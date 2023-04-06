--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: contractdate
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE contractdate ADD CONSTRAINT PRIMARY KEY (
contract_code,
inv_num,
invoice_date,
cmpy_code
) CONSTRAINT pk_contractdate;
