--# description: this script adds a mb_level column in qxt_menu_item, which contains the level or the menu item in the hierarchy.
--# dependencies: 
--# tables list:  qxt_menu_item
--# author: Eric Vercelletto
--# date: 2020-10-04
--# Ticket: KD-2393
--# more comments: First step of modifs allowing to use one-short recursive Queries for the menu, giving more flexibility and speed
--# this allows in theory ten levels of menu group ( 0 to 9 )
alter table qxt_menu_item add (mb_level integer);