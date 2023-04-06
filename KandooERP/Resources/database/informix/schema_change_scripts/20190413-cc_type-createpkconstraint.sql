--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cc_type
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cc_type ADD CONSTRAINT PRIMARY KEY (
cc_type_code
) CONSTRAINT pk_cc_type;
