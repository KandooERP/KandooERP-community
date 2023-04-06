--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: class
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/class.unl SELECT * FROM class;
drop table class;

create table "informix".class 
(
cmpy_code char(2),
class_code nvarchar(8),
desc_text nvarchar(30),
price_level_ind smallint,
ord_level_ind smallint,
stock_level_ind smallint,
desc_level_ind smallint
);


LOAD FROM unl20190322/class.unl INSERT INTO class;
