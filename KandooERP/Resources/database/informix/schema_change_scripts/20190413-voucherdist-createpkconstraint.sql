--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: voucherdist
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE voucherdist ADD CONSTRAINT PRIMARY KEY (
vouch_code,
line_num,
cmpy_code
) CONSTRAINT pk_voucherdist;
