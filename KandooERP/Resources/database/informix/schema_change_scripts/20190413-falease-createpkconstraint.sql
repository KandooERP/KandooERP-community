--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: falease
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE falease ADD CONSTRAINT PRIMARY KEY (
asset_code,
add_on_code,
cmpy_code
) CONSTRAINT pk_falease;
