--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posdocoffers
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posdocoffers ADD CONSTRAINT PRIMARY KEY (
tran_num,
offer_code,
cmpy_code
) CONSTRAINT pk_posdocoffers;
