--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: loadhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE loadhead ADD CONSTRAINT PRIMARY KEY (
load_num,
cmpy_code
) CONSTRAINT pk_loadhead;
