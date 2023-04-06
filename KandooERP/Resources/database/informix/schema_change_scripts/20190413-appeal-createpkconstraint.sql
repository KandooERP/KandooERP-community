--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: appeal
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE appeal ADD CONSTRAINT PRIMARY KEY (
appeal_year,
source_code,
disp_code
) CONSTRAINT pk_appeal;
