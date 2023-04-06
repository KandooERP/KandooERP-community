--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: invoicepay
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/invoicepay.unl SELECT * FROM invoicepay;
drop table invoicepay;

create table "informix".invoicepay 
(
cmpy_code char(2),
cust_code nvarchar(8),
inv_num integer,
appl_num serial not null ,
pay_date date,
pay_type_ind nchar(2),
ref_num integer,
apply_num integer,
pay_text nvarchar(10),
pay_amt decimal(16,2),
disc_amt decimal(16,2),
rev_flag char(1),
stat_date date,
on_state_flag char(1),
batch_no smallint,
batch_posted nchar(1)
);

LOAD FROM unl20190322/invoicepay.unl INSERT INTO invoicepay;
