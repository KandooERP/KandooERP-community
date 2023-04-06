--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: credit_card
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE credit_card ADD CONSTRAINT PRIMARY KEY (
cc_id
) CONSTRAINT pk_credit_card;
