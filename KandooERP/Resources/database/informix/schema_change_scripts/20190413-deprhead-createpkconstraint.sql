--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: deprhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE deprhead ADD CONSTRAINT PRIMARY KEY (
depr_code,
cmpy_code
) CONSTRAINT pk_deprhead;
