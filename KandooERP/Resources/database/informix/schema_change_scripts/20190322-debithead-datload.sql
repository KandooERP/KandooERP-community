--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: debithead
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/debithead.unl SELECT * FROM debithead;
drop table debithead;

create table "informix".debithead 
(
cmpy_code char(2),
vend_code nvarchar(8),
debit_num integer,
debit_text nvarchar(20),
rma_num integer,
debit_date date,
entry_code nvarchar(8),
entry_date date,
contact_text nvarchar(10),
tax_code nchar(3),
goods_amt decimal(16,2),
tax_amt decimal(16,2),
total_amt decimal(16,2),
dist_qty float,
dist_amt decimal(16,2),
apply_amt decimal(16,2),
disc_amt decimal(16,2),
hist_flag char(1),
jour_num integer,
post_flag char(1),
year_num smallint,
period_num smallint,
appl_seq_num smallint,
com1_text nvarchar(30),
com2_text nvarchar(30),
currency_code nchar(3),
conv_qty float,
post_date date,
batch_num integer
);

LOAD FROM unl20190322/debithead.unl INSERT INTO debithead;
