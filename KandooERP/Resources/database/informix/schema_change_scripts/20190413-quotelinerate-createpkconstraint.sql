--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: quotelinerate
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE quotelinerate ADD CONSTRAINT PRIMARY KEY (
order_num,
line_num,
order_rate_type,
cmpy_code
) CONSTRAINT pk_quotelinerate;
