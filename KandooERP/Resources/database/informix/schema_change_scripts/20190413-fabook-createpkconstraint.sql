--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: fabook
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE fabook ADD CONSTRAINT PRIMARY KEY (
book_code,
cmpy_code
) CONSTRAINT pk_fabook;
