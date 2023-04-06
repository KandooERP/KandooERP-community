--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: disposition
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE disposition ADD CONSTRAINT PRIMARY KEY (
disp_code
) CONSTRAINT pk_disposition;
