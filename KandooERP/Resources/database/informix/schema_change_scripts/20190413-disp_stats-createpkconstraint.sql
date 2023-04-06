--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: disp_stats
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE disp_stats ADD CONSTRAINT PRIMARY KEY (
stat_date,
source_code,
disp_code
) CONSTRAINT pk_disp_stats;
