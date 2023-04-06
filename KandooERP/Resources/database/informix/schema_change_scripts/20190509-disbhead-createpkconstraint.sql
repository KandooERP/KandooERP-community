--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: disbhead
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
drop index if exists i_disbhd_1;
create unique index u_disbhead on disbhead(disb_code,cmpy_code);
alter table disbhead add constraint primary key (disb_code,cmpy_code) constraint pk_disbhead;
