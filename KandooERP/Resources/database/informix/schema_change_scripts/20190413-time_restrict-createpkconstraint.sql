--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: time_restrict
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE time_restrict ADD CONSTRAINT PRIMARY KEY (
time_restrict_code
) CONSTRAINT pk_time_restrict;
