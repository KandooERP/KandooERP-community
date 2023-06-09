--# description: this script adds columns to coa
--# tables list: coa
--# dependencies: 
--# author: ericv
--# date: 2020-08-13
--# Ticket #  KD-2239
--# Comments: is_nominalcode: is this coa a nominal code (or a class)
--# parentid: code of the class to which this account belongs 
--# analy_class: will contain JSON classification for analytics
--alter table coa add (is_nominalcode boolean,parentid nchar(18),analy_class bson);
alter table coa add (is_nominalcode boolean,parentid nchar(18));