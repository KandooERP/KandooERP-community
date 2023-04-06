--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: extline
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE extline ADD CONSTRAINT PRIMARY KEY (
rpt_id,
col_uid,
line_uid,
cmpy_code
) CONSTRAINT pk_extline;
