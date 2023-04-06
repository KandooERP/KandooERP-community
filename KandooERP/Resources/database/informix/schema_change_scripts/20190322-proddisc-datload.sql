--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: proddisc
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/proddisc.unl SELECT * FROM proddisc;
drop table proddisc;


create table "informix".proddisc 
(
cmpy_code char(2),
type_ind nchar(1),
key_num nchar(3),
maingrp_code nchar(3),
prodgrp_code nchar(3),
part_code nvarchar(15),
reqd_amt decimal(16,2),
reqd_qty float,
disc_per decimal(6,3),
unit_sale_amt decimal(16,2),
per_amt_ind nchar(1)
);

LOAD FROM unl20190322/proddisc.unl INSERT INTO proddisc;
