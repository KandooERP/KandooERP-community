--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posmesstext
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posmesstext ADD CONSTRAINT PRIMARY KEY (
mess_code,
line_num,
cmpy_code
) CONSTRAINT pk_posmesstext;
