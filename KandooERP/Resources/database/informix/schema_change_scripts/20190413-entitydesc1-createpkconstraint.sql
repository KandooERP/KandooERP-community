--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: entitydesc1
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE entitydesc1 ADD CONSTRAINT PRIMARY KEY (
entity_num
) CONSTRAINT pk_entitydesc1;
