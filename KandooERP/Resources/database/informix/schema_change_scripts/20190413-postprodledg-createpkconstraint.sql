--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: postprodledg
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE postprodledg ADD CONSTRAINT PRIMARY KEY (
part_code,
ware_code,
tran_date,
seq_num,
cmpy_code
) CONSTRAINT pk_postprodledg;
