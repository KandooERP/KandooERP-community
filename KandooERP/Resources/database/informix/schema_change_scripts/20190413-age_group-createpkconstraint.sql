--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: age_group
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE age_group ADD CONSTRAINT PRIMARY KEY (
age_code
) CONSTRAINT pk_age_group;
