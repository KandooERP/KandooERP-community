--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: maingrp
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/maingrp.unl SELECT * FROM maingrp;
drop table maingrp;


create table "informix".maingrp 
(
cmpy_code char(2),
maingrp_code nchar(3),
desc_text nvarchar(30),
min_month_amt decimal(16,2),
min_quart_amt decimal(16,2),
min_year_amt decimal(16,2),
dept_code nchar(3)
);

LOAD FROM unl20190322/maingrp.unl INSERT INTO maingrp;
