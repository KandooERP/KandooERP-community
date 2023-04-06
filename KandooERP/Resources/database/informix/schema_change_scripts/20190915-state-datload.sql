--# description: this script insert istate data from spain
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: state
--# author: erve
--# date: 2019-09-15
--# Ticket # :
--# more comments: this table can hold states/provinces/regions/lander etc, anything that is between the country and smaller divisions

load from unl/20190915-state.unl insert into state ;
