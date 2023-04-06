--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: bic
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
unload to /tmp/bic.bck
select * from bic;
drop table bic;
create table bic
  (
    bic_code char(11),
    desc_text nvarchar(30),
    post_code nvarchar(10),
    bank_ref nvarchar(8)
  );

revoke all on bic from "public" as "informix";
load from /tmp/bic.bck
insert into bic;

create unique index u_bic on bic(bic_code);
alter table bic add constraint primary key (bic_code) constraint pk_bic;
