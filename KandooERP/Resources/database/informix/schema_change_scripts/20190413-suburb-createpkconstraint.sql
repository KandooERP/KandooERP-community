--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: suburb
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE suburb ADD CONSTRAINT PRIMARY KEY (
suburb_code
) CONSTRAINT pk_suburb;
