--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: bin_code
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE bin_code ADD CONSTRAINT PRIMARY KEY (
part_code
) CONSTRAINT pk_bin_code;
