--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: postdebithead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE postdebithead ADD CONSTRAINT PRIMARY KEY (
vend_code,
debit_num,
cmpy_code
) CONSTRAINT pk_postdebithead;
