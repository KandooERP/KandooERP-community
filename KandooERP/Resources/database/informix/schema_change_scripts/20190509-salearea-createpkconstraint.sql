--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: salearea
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_salearea on salearea(area_code,cmpy_code);
alter table salearea add constraint primary key (area_code,cmpy_code) constraint pk_salearea;
