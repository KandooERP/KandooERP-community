--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: statoffer
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE statoffer ADD CONSTRAINT PRIMARY KEY (
offer_code,
sale_code,
cust_code,
year_num,
type_code,
int_num,
cmpy_code
) CONSTRAINT pk_statoffer;
