--# description: this script alters the type of poststatus to RAW because it needs to be maintained out of transactions
--# dependencies: 
--# tables list:  poststatus
--# author: Eric Vercelletto
--# date: 2021-01-02
--# Ticket: 
--# more comments:

alter table poststatus add error_msg lvarchar(512) ;       # contains the full 4GL error message ( 512 should be enough)
alter table poststatus drop constraint pk_poststatus ;     # no necessary
alter table poststatus TYPE (RAW);                           # contents will not disappear if rollback
