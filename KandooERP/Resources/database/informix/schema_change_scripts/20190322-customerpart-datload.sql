--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: customerpart
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/customerpart.unl SELECT * FROM customerpart;
drop table customerpart;

create table "informix".customerpart 
(
cmpy_code char(2),
cust_code nvarchar(8),
part_code nvarchar(15),
custpart_code nvarchar(20)
);


LOAD FROM unl20190322/customerpart.unl INSERT INTO customerpart;
