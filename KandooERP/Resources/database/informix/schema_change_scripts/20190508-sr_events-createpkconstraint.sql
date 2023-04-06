--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: sr_events
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
unload to /tmp/sr_events.bck
select * from sr_events;
drop table sr_events;
create table "informix".sr_events
  (
    evnt_num bigserial not null constraint "informix".n103_14,
    sr_seed bigint,
    evnt_type char(10),
    sent_to_id varchar(64),
    sent_to_channel char(6),
    evnt_date datetime year to second,
    abstract char(80),
    evnt_status char(8),
    rcvd_from_id varchar(64),
    rcvd_from_channel char(6),
    next_step char(20),
    next_step_schedule datetime year to hour,
    long_desc lvarchar(32000)
  );


revoke all on sr_events from "public" as "informix";
load from /tmp/sr_events.bck
insert into sr_events;

create unique index u_sr_events on sr_events(evnt_num);
alter table sr_events add constraint primary key (evnt_num) constraint pk_sr_events;

alter table "informix".sr_events add constraint (foreign key (sent_to_id,sent_to_channel) references "informix".contact_channel
     constraint "informix".fk_sr_events_01);
alter table "informix".sr_events add constraint (foreign key (rcvd_from_id,rcvd_from_channel) references "informix".contact_channel
     constraint "informix".fk_sr_events_02);


create trigger "informix".tr_case_h insert on "informix".sr_events
    referencing new as newv
    for each row
        (
        update "informix".service_request set "informix".service_request.sr_status
    = newv.evnt_type  where (sr_seed = newv.sr_seed ) );


