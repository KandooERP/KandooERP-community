--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: txttype
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE txttype ADD CONSTRAINT PRIMARY KEY (
txttype_id
) CONSTRAINT pk_txttype;
