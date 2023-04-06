--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: subdates
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE subdates ADD CONSTRAINT PRIMARY KEY (
part_code,
year_num,
issue_num,
cmpy_code
) CONSTRAINT pk_subdates;
