--# description: this script insert data from Germany
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: state
--# author: albo
--# date: 2019-09-14
--# Ticket # :
--# more comments: this table can hold states/provinces/regions/lander etc, anything that is between the country and smaller divisions

load from unl/20190914-state.unl insert into state ;
