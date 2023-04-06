--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: despatchdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE despatchdetl ADD CONSTRAINT PRIMARY KEY (
carrier_code,
despatch_code,
invoice_num,
cmpy_code
) CONSTRAINT pk_despatchdetl;
