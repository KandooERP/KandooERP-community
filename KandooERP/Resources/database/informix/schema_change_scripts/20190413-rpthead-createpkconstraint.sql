--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: rpthead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE rpthead ADD CONSTRAINT PRIMARY KEY (
rpt_id,
cmpy_code
) CONSTRAINT pk_rpthead;
