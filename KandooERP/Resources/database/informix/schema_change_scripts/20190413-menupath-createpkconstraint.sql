--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: menupath
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE menupath ADD CONSTRAINT PRIMARY KEY (
menu_code
) CONSTRAINT pk_menupath;
