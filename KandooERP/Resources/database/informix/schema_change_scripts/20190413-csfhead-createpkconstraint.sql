--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: csfhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE csfhead ADD CONSTRAINT PRIMARY KEY (
complaint_code,
cmpy_code
) CONSTRAINT pk_csfhead;
