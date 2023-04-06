--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: sr_documents
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
unload to /tmp/sr_documents.bck
select * from sr_documents;
drop table sr_documents;
create table "informix".sr_documents
  (
    doc_num bigserial not null constraint "informix".n104_21,
    sr_seed bigint,
    doc_type char(4),
    sent_to_id varchar(64),
    sent_to_channel char(6),
    sent_date datetime year to minute,
    rcvd_from_id varchar(64),
    rcvd_from_channel char(6),
    rcvd_date datetime year to minute,
    file_name varchar(128),
    text_contents lvarchar(32000)
  );

revoke all on "informix".sr_documents from "public" as "informix";

load from /tmp/sr_documents.bck
insert into sr_documents;

create unique index u_sr_documents on sr_documents(doc_num);
alter table sr_documents add constraint primary key (doc_num) constraint pk_sr_documents;

alter table "informix".sr_documents add constraint (foreign key (sent_to_id,sent_to_channel) references "informix".contact_channel
     constraint "informix".fk_sr_documents_contact_channel_02);
