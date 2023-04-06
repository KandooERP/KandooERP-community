--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: bankstatement
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE bankstatement ADD CONSTRAINT PRIMARY KEY (
bank_code,
sheet_num,
seq_num,
cmpy_code
) CONSTRAINT pk_bankstatement;
