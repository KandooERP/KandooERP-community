--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: rate
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE rate ADD CONSTRAINT PRIMARY KEY (
cmpy_code,
rate_type,
expiry_date,
person_code,
cust_code,
job_code,
var_code,
activity_code
) CONSTRAINT pk_rate;
