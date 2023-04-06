--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: phone
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE phone ADD CONSTRAINT PRIMARY KEY (
phone_id
) CONSTRAINT pk_phone;
