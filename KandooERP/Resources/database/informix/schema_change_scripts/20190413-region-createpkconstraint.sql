--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: region
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE region ADD CONSTRAINT PRIMARY KEY (
regn_code
) CONSTRAINT pk_region;
