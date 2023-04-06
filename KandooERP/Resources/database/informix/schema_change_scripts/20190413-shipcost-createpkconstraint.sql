--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: shipcost
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE shipcost ADD CONSTRAINT PRIMARY KEY (
ship_code,
cost_type_code,
cmpy_code
) CONSTRAINT pk_shipcost;
