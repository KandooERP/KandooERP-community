--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: menunames
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE menunames ADD CONSTRAINT PRIMARY KEY (
language_code,
source_ind,
menu_num
) CONSTRAINT pk_menunames;
