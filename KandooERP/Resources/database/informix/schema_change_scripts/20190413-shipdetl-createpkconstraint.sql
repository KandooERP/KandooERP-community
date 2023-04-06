--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: shipdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE shipdetl ADD CONSTRAINT PRIMARY KEY (
ship_code,
line_num,
cmpy_code
) CONSTRAINT pk_shipdetl;
