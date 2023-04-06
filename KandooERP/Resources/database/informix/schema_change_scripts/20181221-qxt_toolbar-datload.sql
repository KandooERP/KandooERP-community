--# description: this script resets the contents of the qxt_toolbar table
--# dependencies: 20181221-qxt_toolbar.unl
--# tables list: qxt_toolbar
--# author: huho
--# date: 2018-12-21
--# Ticket # :
--# more comments:
truncate table qxt_toolbar ;
load from 20181221-qxt_toolbar.unl
insert into qxt_toolbar
