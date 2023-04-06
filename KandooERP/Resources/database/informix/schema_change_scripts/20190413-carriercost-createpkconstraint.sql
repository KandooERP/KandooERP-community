--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: carriercost
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE carriercost ADD CONSTRAINT PRIMARY KEY (
carrier_code,
state_code,
country_code,
freight_ind,
cmpy_code
) CONSTRAINT pk_carriercost;
