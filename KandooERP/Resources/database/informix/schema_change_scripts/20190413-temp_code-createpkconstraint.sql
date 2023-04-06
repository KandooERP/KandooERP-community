--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: temp_code
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE temp_code ADD CONSTRAINT PRIMARY KEY (
cont_code
) CONSTRAINT pk_temp_code;
