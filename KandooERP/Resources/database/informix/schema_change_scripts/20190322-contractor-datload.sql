--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: contractor
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/contractor.unl SELECT * FROM contractor;
drop table contractor;

create table "informix".contractor 
(
cmpy_code char(2),
vend_code nvarchar(8),
home_phone_text nvarchar(20),
pager_comp_text nvarchar(15),
pager_num_text nvarchar(10),
start_date date,
licence_text nvarchar(12),
expiry_date date,
tax_no_text nvarchar(10),
regist_num_text nvarchar(10),
tax_rate_qty decimal(4,2),
variation_text nvarchar(10),
var_exp_date date,
account_num_text nvarchar(10),
union_text nvarchar(20),
union_num_text nvarchar(10),
union_exp_date date,
comp_num_text nvarchar(10),
insurance_text nvarchar(20),
ins_exp_date date,
tax_code nchar(3),
var_start_date date
);

LOAD FROM unl20190322/contractor.unl INSERT INTO contractor;
