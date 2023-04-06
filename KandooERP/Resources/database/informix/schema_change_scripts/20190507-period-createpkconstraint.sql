--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: period
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_period on period(year_num,period_num,cmpy_code);
ALTER TABLE period ADD CONSTRAINT PRIMARY KEY ( year_num,period_num,cmpy_code)
CONSTRAINT pk_period;
