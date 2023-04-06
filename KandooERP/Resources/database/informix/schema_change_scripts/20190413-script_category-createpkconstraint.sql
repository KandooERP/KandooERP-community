--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: script_category
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE script_category ADD CONSTRAINT PRIMARY KEY (
category
) CONSTRAINT pk_script_category;
