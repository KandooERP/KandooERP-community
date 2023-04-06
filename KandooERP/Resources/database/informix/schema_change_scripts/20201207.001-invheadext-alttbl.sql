--# description: this script extends the map location size
--# dependencies: 
--# tables list:  invheadext, creditheadext
--# author: Alexander Chubar
--# date: 2020-12-09
--# Ticket: 
--# more comments:
alter table invheadext modify (map_ref_text char(20));
rename column invheadext.map_ref_text to map_gps_coordinates;
alter table creditheadext modify (map_ref_text char(20));
rename column creditheadext.map_ref_text to map_gps_coordinates;
alter table delivhead modify (map_ref_text char(20));
rename column delivhead.map_ref_text to map_gps_coordinates;
