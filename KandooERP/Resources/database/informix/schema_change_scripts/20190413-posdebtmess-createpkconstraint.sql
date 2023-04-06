--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posdebtmess
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posdebtmess ADD CONSTRAINT PRIMARY KEY (
mess_code,
debtor_type,
cmpy_code
) CONSTRAINT pk_posdebtmess;
