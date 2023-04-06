--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: saleshistory
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE saleshistory ADD CONSTRAINT PRIMARY KEY (
sale_code,
year_num,
period_num
) CONSTRAINT pk_saleshistory;
