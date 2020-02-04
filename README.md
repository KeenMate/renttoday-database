# RentToday - Postgres example database

This is a rework of [Pagila database](https://github.com/ganeshan/pagila). It starts to be so different that it has no point to call it still Pagila. Main differences are these:
  
- there is a new schema called *helpers* for helper functions and objects:
  - aggregation function *group_concat* and it's *_group_concat* function help to group by concatenated string
  - functions *full_name* and *reversed_full_name* helps to format names in the same way from all places, DRY
- database contains new template table ***_template_timestamps*** that is inherited by most of the tables except table *payment* that is partitioned and cannot inherit another table so timestamp fields are now part of payment table
- *last_updated* function has been reworked to work properly with new timestamps
- *payment* and *rental* tables were denormalized to contain film title, customer's fullname and staff member's fullname and proper foreing keys were set to **set to null on delete** for respective ids to be able to delete films, customers and staff and does not affect accounting and reporting
  - the original architecture did not care about payments and rentals
- database search path was set to *helpers* and *public*
- Primary keys and foreign keys are now aligned to proper data types.  
Some primary keys were defined as integers but fkeyed as smallint and vice versa
- Partitioned *payment* tables are now created for year 2020
- Data are also created for year 2020
- We tried everything on Postgres 12 and are modifing it to be runnable in this version but the script should work in much older versions of Postgres
- Script was completely regenerated with Jetbrains DataGrip. Create scripts are now in more logical order. Tables first than views and functions.

## Usage
Script filenames are set in proper order:
- [00-renttoday-recreate-database.sql](./00-renttoday-recreate-database.sql) is used for complete removal and recreation of new empty database
- [01-renttoday-schema.sql](./01-renttoday-schema.sql) will create new database from scratch
- [02-renttoday-data.sql](./02-renttoday-data.sql) and [02-renttoday-insert-data.sql](./02-renttoday-insert-data.sql) will populated database with data. One file is used by [psql](https://www.postgresql.org/docs/current/app-psql.html)
- [03-renttoday-populate-denormalized-data.sql](./03-renttoday-populate-denormalized-data.sql) will populate denormalized data in *payment* and *rental* tables  

## Old Pagila texts (still valid to some degree)

FULLTEXT SEARCH
---------------

Fulltext functionality is built in PostgreSQL, so parts of the schema exist
in the main schema file. 

Example usage:

SELECT * FROM film WHERE fulltext @@ to_tsquery('fate&india');


PARTITIONED TABLES
------------------

The payment table is designed as a partitioned table with a 6 month timespan
for the date ranges. 
If you want to take full advantage of table partitioning, you need to make
sure constraint_exclusion is turned on in your database. You can do this by
setting "constraint_exclusion = on" in your postgresql.conf, or by issuing the
command "ALTER DATABASE pagila SET constraint_exclusion = on" (substitute
pagila for your database name if installing into a database with a different
name)
