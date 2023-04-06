--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: script_trans
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE script_trans ADD CONSTRAINT PRIMARY KEY (
translate
) CONSTRAINT pk_script_trans;
