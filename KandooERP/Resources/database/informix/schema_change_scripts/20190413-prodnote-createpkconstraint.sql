--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: prodnote
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE prodnote ADD CONSTRAINT PRIMARY KEY (
part_code,
note_date,
note_seq,
cmpy_code
) CONSTRAINT pk_prodnote;
