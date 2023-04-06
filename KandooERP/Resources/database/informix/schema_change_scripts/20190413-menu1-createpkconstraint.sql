--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: menu1
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE menu1 ADD CONSTRAINT PRIMARY KEY (
menu1_code
) CONSTRAINT pk_menu1;
