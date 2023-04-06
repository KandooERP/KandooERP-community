--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: shiphead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE shiphead ADD CONSTRAINT PRIMARY KEY (
ship_code,
cmpy_code
) CONSTRAINT pk_shiphead;
