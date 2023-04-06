--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: ordernote
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE ordernote ADD CONSTRAINT PRIMARY KEY (
cust_code,
order_num,
note_date,
note_num,
cmpy_code
) CONSTRAINT pk_ordernote;
