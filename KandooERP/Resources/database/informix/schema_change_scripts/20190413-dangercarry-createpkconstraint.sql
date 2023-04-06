--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: dangercarry
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE dangercarry ADD CONSTRAINT PRIMARY KEY (
class1_code,
class2_code
) CONSTRAINT pk_dangercarry;
