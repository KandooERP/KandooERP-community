--# description: this script extends the map location size
--# dependencies: 
--# tables list:  warehouse
--# author: Eric Vercelletto
--# date: 2020-11-07
--# Ticket: 
--# more comments:
alter table warehouse modify (map_ref_text char(20));
rename column warehouse.map_ref_text to map_gps_coordinates;
