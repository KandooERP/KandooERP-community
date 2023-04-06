--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: warehouse
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
unload to /tmp/warehouse.bck
select * from warehouse;
drop table warehouse;
create table "informix".warehouse
  (
    cmpy_code nchar(2),
    ware_code nchar(3),
    desc_text nvarchar(30),
    addr1_text nvarchar(40),
    addr2_text nvarchar(40),
    city_text nvarchar(40),
    state_code nvarchar(6),
    post_code nvarchar(10),
    country_code nvarchar(40),
    contact_text nvarchar(40),
    tele_text nchar(20),
    auto_run_num smallint,
    back_order_ind nchar(1),
    confirm_flag nchar(1),
    pick_flag nchar(1),
    pick_print_code nvarchar(20),
    connote_flag nchar(1),
    connote_print_code nvarchar(20),
    ship_label_flag nchar(1),
    ship_print_code nvarchar(20),
    inv_flag nchar(1),
    inv_print_code nvarchar(20),
    acct_mask_code nchar(18),
    next_pick_num integer,
    pick_reten_num integer,
    next_sched_date datetime year to minute,
    cart_area_code nchar(3),
    map_ref_text nvarchar(10),
    waregrp_code nvarchar(8)
  );

revoke all on "informix".warehouse from "public" as "informix";
load from /tmp/warehouse.bck
insert into warehouse;

create unique index u_warehouse on warehouse(ware_code,cmpy_code);
alter table warehouse add constraint primary key (ware_code,cmpy_code) constraint pk_warehouse;
