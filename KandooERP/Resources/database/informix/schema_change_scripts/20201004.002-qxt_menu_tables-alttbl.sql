--# description: this script updates the new mb_level colum in current data
--# dependencies: 20201004.001-qxt_menu_tables-alttbl
--# tables list:  qxt_menu_item
--# author: Eric Vercelletto
--# date: 2020-10-04
--# Ticket: KD-2393
--# more comments: First step of modifs allowing to use one-short recursive Queries for the menu, giving more flexibility and speed
--# this allows in theory ten levels of menu group ( 0 to 9 )

-- set mb_level = 0 to the lowest level of menu groups(just above root )
update qxt_menu_item
set mb_level = 0
WHERE mb_type = 0
and mb_parent_id = 0;

-- set mb_level = 1 to upper level of menu groups (just above 0 level )
update qxt_menu_item
set mb_level = 1
WHERE mb_type = 0
and mb_parent_id > 0;

-- set mb_level = 10  to items running a command (i.e not a menu group) . T
update qxt_menu_item
set mb_level = 10
WHERE mb_type > 0
and mb_parent_id > 0 ;