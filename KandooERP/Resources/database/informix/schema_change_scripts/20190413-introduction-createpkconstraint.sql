--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: introduction
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE introduction ADD CONSTRAINT PRIMARY KEY (
intro_code
) CONSTRAINT pk_introduction;
