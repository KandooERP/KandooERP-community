--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: version
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE version ADD CONSTRAINT PRIMARY KEY (
vers_code
) CONSTRAINT pk_version;
