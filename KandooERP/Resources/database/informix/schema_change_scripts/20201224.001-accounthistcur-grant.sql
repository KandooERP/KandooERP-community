--# description: this script grants permissions to accounthistcurcur 
--# dependencies: 
--# tables list: accounthistcurcur 
--# author: eric
--# date: 2020-12-24
--# Ticket # : 
--# 

grant select on "informix".accounthistcur to "allmodules_admin" as "informix";
grant update on "informix".accounthistcur to "allmodules_admin" as "informix";
grant insert on "informix".accounthistcur to "allmodules_admin" as "informix";
grant delete on "informix".accounthistcur to "allmodules_admin" as "informix";
grant index on "informix".accounthistcur to "allmodules_admin" as "informix";
grant select on "informix".accounthistcur to "allmodules_user" as "informix";
grant update on "informix".accounthistcur to "allmodules_user" as "informix";
grant insert on "informix".accounthistcur to "allmodules_user" as "informix";
grant delete on "informix".accounthistcur to "allmodules_user" as "informix";
