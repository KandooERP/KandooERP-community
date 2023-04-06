--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: tentbankdetl
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/tentbankdetl.unl SELECT * FROM tentbankdetl;
drop table tentbankdetl;

create table "informix".tentbankdetl 
(
cmpy_code char(2),
bank_dep_num integer,
seq_num integer,
cash_num integer,
tran_amt decimal(16,2),
currency_code nchar(3),
conv_qty float,
tran_type_ind nchar(1),
cash_type_ind nchar(1),
drawer_text nvarchar(20),
bank_text nvarchar(15),
branch_text nvarchar(20),
cheque_text nvarchar(10),
station_code nvarchar(8),
locn_code nvarchar(8),
pos_pay_type nchar(2),
pos_doc_num integer,
cust_code nvarchar(8),
cash_date date
);


LOAD FROM unl20190322/tentbankdetl.unl INSERT INTO tentbankdetl;
