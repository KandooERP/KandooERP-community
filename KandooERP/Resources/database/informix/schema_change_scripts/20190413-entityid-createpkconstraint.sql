--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: entityid
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE entityid ADD CONSTRAINT PRIMARY KEY (
entity_num,
entity_code,
type_ind,
language_code
) CONSTRAINT pk_entityid;
