--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: glline
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE glline ADD CONSTRAINT PRIMARY KEY (
rpt_id,
line_uid,
cmpy_code
) CONSTRAINT pk_glline;
