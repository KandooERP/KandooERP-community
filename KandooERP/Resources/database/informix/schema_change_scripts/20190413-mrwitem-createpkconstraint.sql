--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: mrwitem
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE mrwitem ADD CONSTRAINT PRIMARY KEY (
item_id
) CONSTRAINT pk_mrwitem;
