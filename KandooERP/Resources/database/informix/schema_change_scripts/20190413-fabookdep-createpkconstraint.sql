--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: fabookdep
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE fabookdep ADD CONSTRAINT PRIMARY KEY (
book_code,
asset_code,
depn_code,
cmpy_code
) CONSTRAINT pk_fabookdep;
