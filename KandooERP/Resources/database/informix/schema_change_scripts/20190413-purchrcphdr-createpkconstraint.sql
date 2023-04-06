--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: purchrcphdr
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE purchrcphdr ADD CONSTRAINT PRIMARY KEY (
receipt_num
) CONSTRAINT pk_purchrcphdr;
