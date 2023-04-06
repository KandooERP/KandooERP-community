--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: glasset
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE glasset ADD CONSTRAINT PRIMARY KEY (
book_code,
facat_code,
location_code,
cmpy_code
) CONSTRAINT pk_glasset;
