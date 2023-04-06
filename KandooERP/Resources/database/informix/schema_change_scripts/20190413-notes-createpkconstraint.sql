--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: notes
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE notes ADD CONSTRAINT PRIMARY KEY (
note_code,
note_num,
cmpy_code
) CONSTRAINT pk_notes;
