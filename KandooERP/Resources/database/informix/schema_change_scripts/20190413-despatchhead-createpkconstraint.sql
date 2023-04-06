--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: despatchhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE despatchhead ADD CONSTRAINT PRIMARY KEY (
carrier_code,
manifest_num,
cmpy_code
) CONSTRAINT pk_despatchhead;
