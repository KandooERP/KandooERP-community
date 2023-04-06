--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: deprdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE deprdetl ADD CONSTRAINT PRIMARY KEY (
depr_code,
year_num,
cmpy_code
) CONSTRAINT pk_deprdetl;
