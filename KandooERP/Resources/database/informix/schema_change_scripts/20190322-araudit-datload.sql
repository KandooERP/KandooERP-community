--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list:  araudit
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/araudit.unl SELECT * FROM araudit;
drop table araudit;

create table "informix".araudit 
(
cmpy_code char(2),
tran_date date,
cust_code nvarchar(8),
seq_num integer,
tran_type_ind nchar(2),
source_num integer,
tran_text nvarchar(15),
tran_amt decimal(16,2),
entry_code nvarchar(8),
sales_code nvarchar(8),
year_num smallint,
period_num smallint,
bal_amt decimal(16,2),
currency_code nchar(3),
conv_qty float,
entry_date date
);

LOAD FROM unl20190322/araudit.unl INSERT INTO araudit;
