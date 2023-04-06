--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: prodledg
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/prodledg.unl SELECT * FROM prodledg;
drop table prodledg;


create table "informix".prodledg 
(
cmpy_code char(2),
part_code nvarchar(15),
ware_code nchar(3),
tran_date date,
seq_num integer,
trantype_ind nchar(1),
year_num smallint,
period_num smallint,
source_text nchar(8),
source_num integer,
tran_qty float,
cost_amt decimal(16,4),
sales_amt decimal(16,4),
hist_flag char(1),
post_flag char(1),
jour_num integer,
desc_text nvarchar(25),
acct_code nvarchar(18),
bal_amt float,
entry_code nvarchar(8),
entry_date date,
ref_num integer
);



LOAD FROM unl20190322/prodledg.unl INSERT INTO prodledg;
