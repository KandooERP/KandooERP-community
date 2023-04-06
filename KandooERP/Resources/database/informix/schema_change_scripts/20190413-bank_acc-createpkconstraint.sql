--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: bank_acc
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE bank_acc ADD CONSTRAINT PRIMARY KEY (
acc_id
) CONSTRAINT pk_bank_acc;
