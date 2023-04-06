--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: quotelabour
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE quotelabour ADD CONSTRAINT PRIMARY KEY (
order_num,
line_num,
cmpy_code
) CONSTRAINT pk_quotelabour;
