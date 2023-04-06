--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posterminal
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posterminal ADD CONSTRAINT PRIMARY KEY (
device_code
) CONSTRAINT pk_posterminal;
