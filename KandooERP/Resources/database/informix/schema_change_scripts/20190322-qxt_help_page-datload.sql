--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_help_page
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qxt_help_page.unl SELECT * FROM qxt_help_page;
drop table qxt_help_page;

create table "informix".qxt_help_page 
(
hlp_pageid nvarchar(4),
hlp_basefolderid1 nvarchar(20),
hlp_basefolderid2 nvarchar(20),
hlp_pagepath nvarchar(200),
primary key (hlp_pageid) 
);

LOAD FROM unl20190322/qxt_help_page.unl INSERT INTO qxt_help_page;
