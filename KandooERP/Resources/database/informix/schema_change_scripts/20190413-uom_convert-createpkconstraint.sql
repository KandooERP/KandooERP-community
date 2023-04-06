--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: uom_convert
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE uom_convert ADD CONSTRAINT PRIMARY KEY (
from_uom_code,
to_uom_code
) CONSTRAINT pk_uom_convert;
