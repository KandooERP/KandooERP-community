--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: glsummary
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE glsummary ADD CONSTRAINT PRIMARY KEY (
summary_code,
cmpy_code
) CONSTRAINT pk_glsummary;
