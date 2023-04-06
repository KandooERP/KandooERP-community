begin work;
set constraints all deferred;
execute procedure pull_table_contents_from ("column_documentation","kandoo_dev@begooden_er","truncate");
execute procedure pull_table_contents_from ("table_documentation","kandoo_dev@begooden_er","truncate");
set constraints all immediate;
commit work;
