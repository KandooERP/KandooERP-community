--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: exthead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE exthead ADD CONSTRAINT PRIMARY KEY (
cmpy_code,
line_code,
line_uid
) CONSTRAINT pk_exthead;
