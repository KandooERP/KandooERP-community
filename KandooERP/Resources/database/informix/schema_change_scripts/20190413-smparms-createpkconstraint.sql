--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: smparms
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE smparms ADD CONSTRAINT PRIMARY KEY (
key_num,
cmpy_code
) CONSTRAINT pk_smparms;
