--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_help_fragment
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qxt_help_fragment.unl SELECT * FROM qxt_help_fragment;
drop table qxt_help_fragment;

create table "informix".qxt_help_fragment 
(
hlp_page_id nvarchar(4),
hlp_fragment_id nvarchar(10),
hlp_fragment_text nvarchar(200),
primary key (hlp_page_id,hlp_fragment_id) 
);


LOAD FROM unl20190322/qxt_help_fragment.unl INSERT INTO qxt_help_fragment;
