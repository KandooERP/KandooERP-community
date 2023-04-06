--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: service_request
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
unload to /tmp/service_request.bck
select * from service_request;
drop table service_request;
create table "informix".service_request
  (
    sr_seed bigserial not null ,
    cmpy_code char(2),
    sr_number varchar(16),
    sr_parent varchar(16),
    sr_duplicate varchar(16),
    open_date datetime year to minute,
    deadline datetime year to minute,
    abstract char(80),
    prd_code char(13),
    prd_module char(15),
    prd_version char(20),
    os_code char(10),
    os_version char(20),
    cust_references varchar(64,20),
    serial_number char(20),
    sr_type char(8),
    severity smallint,
    environment char(20),
    description lvarchar(32000),
    sr_status char(12),
    reported_by varchar(64),
    rb_channel char(6),
    answer_to varchar(64),
    at_channel char(6),
    sr_owner varchar(64),
    so_channel char(6),
    close_date datetime year to second
  );

revoke all on "informix".service_request from "public" as "informix";

load from /tmp/service_request.bck
insert into service_request;

create unique index "informix".pk_service_request on "informix"
    .service_request (sr_seed) using btree ;
create unique index "informix".u_service_request_01 on "informix"
    .service_request (sr_number,cmpy_code) using btree ;
alter table "informix".service_request add constraint primary
    key (sr_seed) constraint pk_service_request ;

alter table "informix".service_request add constraint (foreign
    key (reported_by,rb_channel) references "informix".contact_channel
     constraint "informix".fk_service_request_contact_ch);
alter table "informix".service_request add constraint (foreign
    key (prd_code,cmpy_code) references "informix".supported_products
     constraint "informix".fk_service_request_products);
alter table "informix".service_request add constraint (foreign
    key (os_code) references "informix".operating_systems  constraint
    "informix".fk_service_request_operating_systems);
