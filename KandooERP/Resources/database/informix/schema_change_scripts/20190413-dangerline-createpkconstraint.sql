--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: dangerline
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE dangerline ADD CONSTRAINT PRIMARY KEY (
carrier_code,
despatch_code,
dg_code,
cmpy_code
) CONSTRAINT pk_dangerline;
