--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: drivernote
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE drivernote ADD CONSTRAINT PRIMARY KEY (
driver_code,
note_num,
cmpy_code
) CONSTRAINT pk_drivernote;
