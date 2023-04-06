--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: category
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/category.unl SELECT * FROM category;
drop table category;




create table "informix".category 
(
cmpy_code char(2),
cat_code nchar(3),
desc_text nvarchar(30),
price1_per decimal(6,3),
price2_per decimal(6,3),
price3_per decimal(6,3),
price4_per decimal(6,3),
price5_per decimal(6,3),
price6_per decimal(6,3),
price7_per decimal(6,3),
price8_per decimal(6,3),
price9_per decimal(6,3),
std_cost_mrkup_per decimal(6,3),
oth_cost_fact_per decimal(6,3),
cost_list_ind nchar(1),
def_cost_ind nchar(1),
pur_acct_code nvarchar(18),
ret_acct_code nvarchar(18),
sale_acct_code nvarchar(18),
cred_acct_code nvarchar(18),
cogs_acct_code nvarchar(18),
stock_acct_code nvarchar(18),
adj_acct_code nvarchar(18),
price1_ind nchar(1),
price2_ind nchar(1),
price3_ind nchar(1),
price4_ind nchar(1),
price5_ind nchar(1),
price6_ind nchar(1),
price7_ind nchar(1),
price8_ind nchar(1),
price9_ind nchar(1),
rounding_factor decimal(16,4),
rounding_ind nchar(1),
int_rev_acct_code nvarchar(18),
int_cogs_acct_code nvarchar(18)
);
LOAD FROM unl20190322/category.unl INSERT INTO category;
