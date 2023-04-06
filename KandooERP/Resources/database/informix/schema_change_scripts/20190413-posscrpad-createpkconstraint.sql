--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posscrpad
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posscrpad ADD CONSTRAINT PRIMARY KEY (
tran_num,
inv_num,
cred_num,
line_num,
seq_num,
cmpy_code
) CONSTRAINT pk_posscrpad;
