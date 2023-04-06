--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: salestrct
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE salestrct ADD CONSTRAINT PRIMARY KEY (
sale_code,
type_ind,
type_code,
cmpy_code
) CONSTRAINT pk_salestrct;
