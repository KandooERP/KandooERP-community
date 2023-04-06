--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: rndcode
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE rndcode ADD CONSTRAINT PRIMARY KEY (
rnd_code
) CONSTRAINT pk_rndcode;
