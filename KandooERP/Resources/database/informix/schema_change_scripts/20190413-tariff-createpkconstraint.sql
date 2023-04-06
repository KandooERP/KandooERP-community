--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: tariff
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE tariff ADD CONSTRAINT PRIMARY KEY (
tariff_code,
cmpy_code
) CONSTRAINT pk_tariff;
