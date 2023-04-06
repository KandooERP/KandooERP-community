--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: subcustomer
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
drop index if exists subcust2_key ;
drop index if exists u_subcustomer ;
create unique index u_subcustomer on subcustomer(cust_code,part_code,ship_code,comm_date,sub_type_code,end_date,cmpy_code);
alter table subcustomer add constraint primary key (cust_code,part_code,ship_code,comm_date,sub_type_code,end_date,cmpy_code) constraint pk_subcustomer;
