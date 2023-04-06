--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: absmodule
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE absmodule ADD CONSTRAINT PRIMARY KEY (
abs_mod_code
) CONSTRAINT pk_absmodule;
