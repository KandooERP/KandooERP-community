--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: huho
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/huho.unl SELECT * FROM huho;
drop table huho;

create table "informix".huho 
(
acct_code nvarchar(18),
desc_text nvarchar(40),
type_ind nchar(1),
group_code nchar(7), /* no idea why this is now char(7) - needs checking */
analy_req_flag char(1),
analy_prompt_text nvarchar(20),
qty_flag char(1),
uom_code nchar(4),
tax_code nchar(3)
);

LOAD FROM unl20190322/huho.unl INSERT INTO huho;
