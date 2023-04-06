--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: stattarget
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE stattarget ADD CONSTRAINT PRIMARY KEY (
year_num,
type_code,
int_num,
bdgt_type_ind,
bdgt_type_code,
bdgt_ind,
cmpy_code
) CONSTRAINT pk_stattarget;
