--# description: this script extends the size of the widget_id column
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: form_attributes
--# author: eric vercelletto
--# date: 2019-08-10
--# Ticket # :
--# more comments:
alter table form_attributes modify widget_id nchar(32);
rename column form_attributes.tablename to table_name;

