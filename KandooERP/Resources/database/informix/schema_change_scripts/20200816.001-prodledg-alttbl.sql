--# description: this script adds explicit adj_type_code to prodledg
--# tables list: prodledg
--# dependencies: 
--# author: ericv
--# date: 2020-08-16
--# Ticket #  	
--# Comments: instead of using a multipurpose column source_id which is free text ... 
--# is_max_level: this code is at the bottom of the hierarchy (is a nominal code) 
alter table prodledg add (adj_type_code nchar(8));