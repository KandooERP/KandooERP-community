--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: custdocket
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE custdocket ADD CONSTRAINT PRIMARY KEY (
sale_docket_num,
cmpy_code
) CONSTRAINT pk_custdocket;
