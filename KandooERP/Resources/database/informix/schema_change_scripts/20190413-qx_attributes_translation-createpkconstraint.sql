--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: qx_attributes_translation
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE qx_attributes_translation ADD CONSTRAINT PRIMARY KEY (
attribute_id,
attribute_language
) CONSTRAINT pk_qx_attributes_translation;
