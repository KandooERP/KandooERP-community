--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: poscdraw
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE poscdraw ADD CONSTRAINT PRIMARY KEY (
station_code,
cmpy_code
) CONSTRAINT pk_poscdraw;
