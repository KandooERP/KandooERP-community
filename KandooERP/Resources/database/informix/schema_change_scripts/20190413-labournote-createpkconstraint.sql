--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: labournote
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE labournote ADD CONSTRAINT PRIMARY KEY (
labour_code,
note_num,
cmpy_code
) CONSTRAINT pk_labournote;
