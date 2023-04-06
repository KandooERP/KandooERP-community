--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: tentinvdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE tentinvdetl ADD CONSTRAINT PRIMARY KEY (
cust_code,
inv_num,
line_num,
cmpy_code
) CONSTRAINT pk_tentinvdetl;
