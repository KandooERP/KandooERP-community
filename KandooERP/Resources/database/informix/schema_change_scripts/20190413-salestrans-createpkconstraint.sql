--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: salestrans
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE salestrans ADD CONSTRAINT PRIMARY KEY (
serial_key
) CONSTRAINT pk_salestrans;
