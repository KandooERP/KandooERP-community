--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: shop_orddetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE shop_orddetl ADD CONSTRAINT PRIMARY KEY (
shop_order_code,
parent_item_code,
sequence_code,
order_num,
cmpy_code
) CONSTRAINT pk_shop_orddetl;
