--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: rptlinegrp
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE rptlinegrp ADD CONSTRAINT PRIMARY KEY (
cmpy_code,
line_code
) CONSTRAINT pk_rptlinegrp;
