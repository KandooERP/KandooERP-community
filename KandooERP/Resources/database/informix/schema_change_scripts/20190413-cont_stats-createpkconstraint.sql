--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cont_stats
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cont_stats ADD CONSTRAINT PRIMARY KEY (
cmpy_code,
cont_code,
cont_year,
cont_month
) CONSTRAINT pk_cont_stats;
