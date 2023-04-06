--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: vendornote
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE vendornote ADD CONSTRAINT PRIMARY KEY (
vend_code,
note_date,
note_num,
cmpy_code
) CONSTRAINT pk_vendornote;
