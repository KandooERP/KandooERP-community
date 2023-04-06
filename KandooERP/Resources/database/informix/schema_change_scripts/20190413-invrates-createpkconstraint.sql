--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: invrates
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE invrates ADD CONSTRAINT PRIMARY KEY (
inv_num,
line_num,
rate_type,
cmpy_code
) CONSTRAINT pk_invrates;
