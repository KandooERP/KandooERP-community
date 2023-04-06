--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: coa
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/coa.unl SELECT * FROM coa;
drop table coa;

create table "informix".coa 
(
cmpy_code char(2),
acct_code nchar(18),
desc_text nvarchar(40),
start_year_num smallint,
start_period_num smallint,
end_year_num smallint,
end_period_num smallint,
group_code nchar(7),
analy_req_flag char(1),
analy_prompt_text nvarchar(20),
qty_flag char(1),
uom_code nchar(4),
type_ind nchar(1),
tax_code nchar(3)
);


LOAD FROM unl20190322/coa.unl INSERT INTO coa;
