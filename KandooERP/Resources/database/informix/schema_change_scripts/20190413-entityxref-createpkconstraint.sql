--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: entityxref
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE entityxref ADD CONSTRAINT PRIMARY KEY (
entity1_num,
xref_ind,
entity2_num
) CONSTRAINT pk_entityxref;
