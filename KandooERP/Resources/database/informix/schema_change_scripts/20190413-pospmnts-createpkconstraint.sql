--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: pospmnts
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE pospmnts ADD CONSTRAINT PRIMARY KEY (
doc_num
) CONSTRAINT pk_pospmnts;
