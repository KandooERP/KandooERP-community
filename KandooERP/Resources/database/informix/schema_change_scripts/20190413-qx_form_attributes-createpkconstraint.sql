--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: qx_form_attributes
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE qx_form_attributes ADD CONSTRAINT PRIMARY KEY (
attribute_id
) CONSTRAINT pk_qx_form_attributes;
