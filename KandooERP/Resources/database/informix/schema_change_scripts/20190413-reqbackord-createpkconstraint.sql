--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: reqbackord
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE reqbackord ADD CONSTRAINT PRIMARY KEY (
part_code,
req_num,
line_num,
cmpy_code
) CONSTRAINT pk_reqbackord;
