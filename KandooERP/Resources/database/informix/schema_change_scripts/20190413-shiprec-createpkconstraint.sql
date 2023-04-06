--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: shiprec
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE shiprec ADD CONSTRAINT PRIMARY KEY (
goods_receipt_text,
ship_code,
line_num,
cmpy_code
) CONSTRAINT pk_shiprec;
