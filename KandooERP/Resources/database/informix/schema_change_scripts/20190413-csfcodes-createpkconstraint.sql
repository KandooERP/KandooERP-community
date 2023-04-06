--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: csfcodes
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE csfcodes ADD CONSTRAINT PRIMARY KEY (
csf_code,
cmpy_code
) CONSTRAINT pk_csfcodes;
