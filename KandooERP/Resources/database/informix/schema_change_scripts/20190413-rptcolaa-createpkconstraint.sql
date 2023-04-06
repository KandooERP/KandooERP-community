--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: rptcolaa
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE rptcolaa ADD CONSTRAINT PRIMARY KEY (
rpt_id,
col_uid,
start_num,
flex_clause,
cmpy_code
) CONSTRAINT pk_rptcolaa;
