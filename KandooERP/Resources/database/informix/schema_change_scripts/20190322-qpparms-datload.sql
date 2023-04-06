--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qpparms
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qpparms.unl SELECT * FROM qpparms;
drop table qpparms;

create table "informix".qpparms 
  (
    cmpy_code char(2),
    key_num nchar(1),
    min_margin_per decimal(6,3),
    max_margin_per decimal(6,3),
    security_ind nchar(1),
    days_validity_num smallint,
    days_retention_num smallint,
    freight_per decimal(6,3),
    insurance_per decimal(6,3),
    quote_std_text nvarchar(40),
    quote_user_text nvarchar(40),
    stockout_lead_text nvarchar(10),
    footer1_text nvarchar(60),
    footer2_text nvarchar(60),
    footer3_text nvarchar(60),
    quote_lead_text nvarchar(30),
    quote_lead_text2 nvarchar(30)
  );

LOAD FROM unl20190322/qpparms.unl INSERT INTO qpparms;
