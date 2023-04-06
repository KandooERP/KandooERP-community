--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: rptpos
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE rptpos ADD CONSTRAINT PRIMARY KEY (
rptpos_id
) CONSTRAINT pk_rptpos;
