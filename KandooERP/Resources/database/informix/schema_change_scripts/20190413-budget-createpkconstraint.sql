--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: budget
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE budget ADD CONSTRAINT PRIMARY KEY (
account,
period
) CONSTRAINT pk_budget;
