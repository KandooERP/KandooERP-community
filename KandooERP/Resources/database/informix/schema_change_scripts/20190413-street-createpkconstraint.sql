--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: street
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE street ADD CONSTRAINT PRIMARY KEY (
street_text,
st_type_text,
suburb_code,
map_number,
ref_text,
source_ind,
cmpy_code
) CONSTRAINT pk_street;
