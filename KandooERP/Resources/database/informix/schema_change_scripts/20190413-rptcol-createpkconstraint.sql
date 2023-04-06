--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: rptcol
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE rptcol ADD CONSTRAINT PRIMARY KEY (
rpt_id,
col_id,
cmpy_code
) CONSTRAINT pk_rptcol;
