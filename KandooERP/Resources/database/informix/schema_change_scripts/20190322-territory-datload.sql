--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: territory
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/territory.unl SELECT * FROM territory;
drop table territory;

create table "informix".territory 
(
cmpy_code char(2),
terr_code nvarchar(5),
desc_text nvarchar(30),
terr_type_ind nchar(1),
area_code nvarchar(5),
sale_code nvarchar(8)
);

LOAD FROM unl20190322/territory.unl INSERT INTO territory;
