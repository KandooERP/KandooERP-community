--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: entitydesc
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE entitydesc ADD CONSTRAINT PRIMARY KEY (
entity_num,
desc_ind,
line_num
) CONSTRAINT pk_entitydesc;
