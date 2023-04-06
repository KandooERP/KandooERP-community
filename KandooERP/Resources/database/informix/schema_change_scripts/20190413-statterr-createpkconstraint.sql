--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: statterr
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE statterr ADD CONSTRAINT PRIMARY KEY (
area_code,
terr_code,
year_num,
type_code,
int_num,
cmpy_code
) CONSTRAINT pk_statterr;
