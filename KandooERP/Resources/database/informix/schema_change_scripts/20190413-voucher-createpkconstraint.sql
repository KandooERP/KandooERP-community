--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: voucher
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE voucher ADD CONSTRAINT PRIMARY KEY (
vend_code,
vouch_code,
cmpy_code
) CONSTRAINT pk_voucher;
