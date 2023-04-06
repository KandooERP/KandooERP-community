--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: menu2
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE menu2 ADD CONSTRAINT PRIMARY KEY (
menu1_code,
menu2_code
) CONSTRAINT pk_menu2;
