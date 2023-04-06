--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: ordohstat
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE ordohstat ADD CONSTRAINT PRIMARY KEY (
group1_code,
group2_code,
group3_code,
ware_code,
terr_code,
type_code,
const_type_code,
year_num,
period_num,
ord_ind,
cmpy_code
) CONSTRAINT pk_ordohstat;
