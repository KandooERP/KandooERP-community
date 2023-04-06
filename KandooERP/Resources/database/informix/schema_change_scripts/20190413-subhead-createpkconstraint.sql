--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: subhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE subhead ADD CONSTRAINT PRIMARY KEY (
sub_num,
cmpy_code
) CONSTRAINT pk_subhead;
