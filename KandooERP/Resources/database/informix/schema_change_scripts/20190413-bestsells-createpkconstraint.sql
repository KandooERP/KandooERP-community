--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: bestsells
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE bestsells ADD CONSTRAINT PRIMARY KEY (
part_code
) CONSTRAINT pk_bestsells;
