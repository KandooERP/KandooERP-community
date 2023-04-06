--# description: this script create indexes on attributes_translation
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: attributes_translation
--# author: eric vercelletto
--# date: 2019-08-10
--# Ticket # :
--# more comments:
drop index if exists attributes_translation_02 ;
create index attributes_translation_02 on attributes_translation(language,translation);

