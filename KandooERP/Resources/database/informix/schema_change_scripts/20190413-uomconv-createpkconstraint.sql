--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: uomconv
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE uomconv ADD CONSTRAINT PRIMARY KEY (
uom_code,
uom_type,
part_code,
prodgrp_code,
maingrp_code,
cmpy_code
) CONSTRAINT pk_uomconv;
