--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: fadepmethod
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE fadepmethod ADD CONSTRAINT PRIMARY KEY (
depn_code,
cmpy_code
) CONSTRAINT pk_fadepmethod;
