--# description: this script add foreign keys on category 
--# dependencies:
--# tables list: category,coa
--# author: eric
--# date: 2020-12-08
--# Ticket # : 
--# 

alter table category add constraint foreign key (pur_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_category_coa_pur;
alter table category add constraint foreign key (ret_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_category_coa_ret;
alter table category add constraint foreign key (sale_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_category_coa_sale;
alter table category add constraint foreign key (cred_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_category_coa_cred;
alter table category add constraint foreign key (cogs_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_category_coa_cog;
alter table category add constraint foreign key (stock_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_category_coa_stock;
alter table category add constraint foreign key (adj_acct_code,cmpy_code) references coa (acct_code,cmpy_code)  constraint fk_category_coa_adj;