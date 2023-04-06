--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: shipnote
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE shipnote ADD CONSTRAINT PRIMARY KEY (
ship_code,
note_date,
note_num,
cmpy_code
) CONSTRAINT pk_shipnote;
