create sequence public.customer_customer_id_seq;

create sequence public.actor_actor_id_seq;

create sequence public.category_category_id_seq;

create sequence public.film_film_id_seq;

create sequence public.address_address_id_seq;

create sequence public.city_city_id_seq;

create sequence public.country_country_id_seq;

create sequence public.inventory_inventory_id_seq;

create sequence public.language_language_id_seq;

create sequence public.payment_payment_id_seq;

create sequence public.rental_rental_id_seq;

create sequence public.staff_staff_id_seq;

create sequence public.store_store_id_seq;

create schema helpers;

create function helpers._group_concat(text, text) returns text
    immutable
    language sql
as
$$
SELECT CASE
           WHEN $2 IS NULL THEN $1
           WHEN $1 IS NULL THEN $2
           ELSE $1 || ', ' || $2
           END
$$;

create function helpers.reversed_full_name(_first_name text, _last_name text) returns text
language sql
as $$
    select initcap(_last_name) || ', ' || initcap(_first_name);
    $$;

create function helpers.full_name(_first_name text, _last_name text) returns text
language sql
as $$
    select initcap(_first_name) || ' ' || initcap(_last_name);
    $$;

create aggregate helpers.group_concat(text) (
    sfunc = helpers._group_concat,
    stype = text
    );

set search_path to helpers, public;

create type public.mpaa_rating as enum ('G', 'PG', 'PG-13', 'R', 'NC-17');

create domain public.year as integer
    constraint year_check check ((VALUE >= 1901) AND (VALUE <= 2155));

create table public._template_timestamps
(
    created     timestamp with time zone default now()                        not null,
    created_by  varchar(250)             default current_user::character varying not null,
    modified    timestamp with time zone default now()                        not null,
    modified_by varchar(250)             default current_user::character varying not null
);

create table public.actor
(
    actor_id    integer                  default nextval('actor_actor_id_seq'::regclass) not null
        constraint actor_pkey
            primary key,
    first_name  text                                                                     not null,
    last_name   text                                                                     not null
) inherits (public._template_timestamps);

create index idx_actor_last_name
    on public.actor (last_name);

create table public.category
(
    category_id smallint                 default nextval('category_category_id_seq'::regclass) not null
        constraint category_pkey
            primary key,
    name        text                                                                           not null,
    last_update timestamp with time zone default now()                                         not null
) inherits (public._template_timestamps);

create table public.country
(
    country_id  smallint                 default nextval('country_country_id_seq'::regclass) not null
        constraint country_pkey
            primary key,
    country     text                                                                         not null
) inherits (public._template_timestamps);

create table public.city
(
    city_id     integer                  default nextval('city_city_id_seq'::regclass) not null
        constraint city_pkey
            primary key,
    city        text                                                                   not null,
    country_id  smallint                                                               not null
        constraint city_country_id_fkey
            references public.country
            on update cascade on delete restrict
) inherits (public._template_timestamps);

create table public.address
(
    address_id  integer                  default nextval('address_address_id_seq'::regclass) not null
        constraint address_pkey
            primary key,
    address     text                                                                         not null,
    address2    text,
    district    text                                                                         not null,
    city_id     integer                                                                      not null
        constraint address_city_id_fkey
            references public.city
            on update cascade on delete restrict,
    postal_code text,
    phone       text                                                                         not null
) inherits (public._template_timestamps);

create index idx_fk_city_id
    on public.address (city_id);

create index idx_fk_country_id
    on public.city (country_id);

create table public.language
(
    language_id smallint                 default nextval('language_language_id_seq'::regclass) not null
        constraint language_pkey
            primary key,
    name        char(20)                                                                       not null,
    last_update timestamp with time zone default now()                                         not null
) inherits (public._template_timestamps);

create table public.film
(
    film_id              integer                  default nextval('film_film_id_seq'::regclass) not null
        constraint film_pkey
            primary key,
    title                text                                                                   not null,
    description          text,
    release_year         year,
    language_id          smallint                                                               not null
        constraint film_language_id_fkey
            references public.language
            on update cascade on delete restrict,
    original_language_id smallint
        constraint film_original_language_id_fkey
            references public.language
            on update cascade on delete restrict,
    rental_duration      smallint                 default 3                                     not null,
    rental_rate          numeric(4, 2)            default 4.99                                  not null,
    length               smallint,
    replacement_cost     numeric(5, 2)            default 19.99                                 not null,
    rating               mpaa_rating              default 'G'::mpaa_rating,
    last_update          timestamp with time zone default now()                                 not null,
    special_features     text[],
    fulltext             tsvector                                                               not null
) inherits (public._template_timestamps);

create index film_fulltext_idx
    on public.film (fulltext);

create index idx_fk_language_id
    on public.film (language_id);

create index idx_fk_original_language_id
    on public.film (original_language_id);

create index idx_title
    on public.film (title);

create trigger film_fulltext_trigger
    before insert or update
    on public.film
    for each row
execute procedure tsvector_update_trigger('fulltext', 'pg_catalog.english', 'title', 'description');

create table public.film_actor
(
    actor_id    integer                                not null
        constraint film_actor_actor_id_fkey
            references public.actor
            on update cascade on delete restrict,
    film_id     integer                                not null
        constraint film_actor_film_id_fkey
            references public.film
            on update cascade on delete restrict,
    constraint film_actor_pkey
        primary key (actor_id, film_id)
) inherits (public._template_timestamps);

create index idx_fk_film_id
    on public.film_actor (film_id);

create table public.film_category
(
    film_id     integer                                not null
        constraint film_category_film_id_fkey
            references public.film
            on update cascade on delete restrict,
    category_id smallint                               not null
        constraint film_category_category_id_fkey
            references public.category
            on update cascade on delete restrict,
    constraint film_category_pkey
        primary key (film_id, category_id)
) inherits (public._template_timestamps);

create table public.payment
(
    payment_id    integer default nextval('payment_payment_id_seq'::regclass) not null,
    customer_id   integer                                                     not null,
    staff_id      integer                                                     not null,
    rental_id     integer                                                     not null,
    amount        numeric(5, 2)                                               not null,
    payment_date  timestamp with time zone                                    not null,
    customer_name text,
    staff_name    text,
    created     timestamp with time zone default now()                        not null,
    created_by  varchar(250)             default current_user::character varying not null,
    modified    timestamp with time zone default now()                        not null,
    modified_by varchar(250)             default current_user::character varying not null
) partition by RANGE (payment_date);

create table public.store
(
    store_id         integer                  default nextval('store_store_id_seq'::regclass) not null
        constraint store_pkey
            primary key,
    store_name       text,
    manager_staff_id integer                                                                  not null,
    address_id       integer                                                                  not null
        constraint store_address_id_fkey
            references public.address
            on update cascade on delete restrict
) inherits (public._template_timestamps);

create table public.customer
(
    customer_id serial                                               not null
        constraint customer_pkey
            primary key,
    store_id    integer                                              not null
        constraint customer_store_id_fkey
            references public.store
            on update cascade on delete restrict,
    create_date date                                                 not null,
    first_name  text                                                 not null,
    last_name   text                                                 not null,
    email       text,
    address_id  integer                                              not null
        constraint customer_address_id_fkey
            references public.address
            on update cascade on delete restrict,
    activebool  boolean                  default true                not null,
    active      integer
) inherits (public._template_timestamps);

create index idx_fk_address_id
    on public.customer (address_id);

create index idx_fk_store_id
    on public.customer (store_id);

create index idx_last_name
    on public.customer (last_name);

create table public.inventory
(
    inventory_id integer                  default nextval('inventory_inventory_id_seq'::regclass) not null
        constraint inventory_pkey
            primary key,
    film_id      integer                                                                          not null
        constraint inventory_film_id_fkey
            references public.film
            on update cascade on delete restrict,
    store_id     integer                                                                          not null
        constraint inventory_store_id_fkey
            references public.store
            on update cascade on delete restrict
) inherits (public._template_timestamps);

create index idx_store_id_film_id
    on public.inventory (store_id, film_id);

create table inventory_counter
(
    inventory_counter_id serial             not null
        constraint inventory_counter_pk
            primary key,
    store_id             integer            not null
        constraint fk_store_id
            references store
            on update cascade on delete cascade,
    film_id              integer            not null
        constraint fk_film_id
            references film
            on update cascade on delete cascade,
    counter              smallint default 0 not null,
    constraint idx_uq_storeid_filmid
        unique (store_id, film_id)
);

create table public.staff
(
    staff_id    integer                  default nextval('staff_staff_id_seq'::regclass) not null
        constraint staff_pkey
            primary key,
    first_name  text                                                                     not null,
    last_name   text                                                                     not null,
    address_id  integer                                                                  not null
        constraint staff_address_id_fkey
            references public.address
            on update cascade on delete restrict,
    email       text,
    store_id    integer                                                                  not null
        constraint staff_store_id_fkey
            references public.store,
    active      boolean                  default true                                    not null,
    username    text                                                                     not null,
    password    text,
    picture     bytea
) inherits (public._template_timestamps);

create table public.rental
(
    rental_id     integer                  default nextval('rental_rental_id_seq'::regclass) not null
        constraint rental_pkey
            primary key,
    rental_date   timestamp with time zone                                                   not null,
    inventory_id  integer
        constraint rental_inventory_id_fkey
            references public.inventory
            on update cascade on delete set null,
    film_title    text,
    customer_id   integer
        constraint rental_customer_id_fkey
            references public.customer
            on update cascade on delete set null,
    customer_name text,
    return_date   timestamp with time zone,
    staff_id      integer
        constraint rental_staff_id_fkey
            references public.staff
            on update cascade on delete set null,
    staff_name    text
) inherits (public._template_timestamps);

create table public.payment_p2020_01
    partition of public.payment
        (
            constraint payment_p2020_01_customer_id_fkey
                foreign key (customer_id) references public.customer on update cascade on delete set null,
            constraint payment_p2020_01_staff_id_fkey
                foreign key (staff_id) references public.staff on update cascade on delete set null,
            constraint payment_p2020_01_rental_id_fkey
                foreign key (rental_id) references public.rental on update cascade on delete set null
            )
        FOR VALUES FROM ('2020-01-01 00:00:00+00') TO ('2020-02-01 00:00:00+00');

create index payment_p2020_01_customer_id_idx
    on public.payment_p2020_01 (customer_id);

create index idx_fk_payment_p2020_01_customer_id
    on public.payment_p2020_01 (customer_id);

create index idx_fk_payment_p2020_01_staff_id
    on public.payment_p2020_01 (staff_id);

create table public.payment_p2020_02
    partition of public.payment
        (
            constraint payment_p2020_02_customer_id_fkey
                foreign key (customer_id) references public.customer on update cascade on delete set null,
            constraint payment_p2020_02_staff_id_fkey
                foreign key (staff_id) references public.staff on update cascade on delete set null,
            constraint payment_p2020_02_rental_id_fkey
                foreign key (rental_id) references public.rental on update cascade on delete set null
            )
        FOR VALUES FROM ('2020-02-01 00:00:00+00') TO ('2020-03-01 00:00:00+00');

create index payment_p2020_02_customer_id_idx
    on public.payment_p2020_02 (customer_id);

create index idx_fk_payment_p2020_02_customer_id
    on public.payment_p2020_02 (customer_id);

create index idx_fk_payment_p2020_02_staff_id
    on public.payment_p2020_02 (staff_id);

create table public.payment_p2020_03
    partition of public.payment
        (
            constraint payment_p2020_03_customer_id_fkey
                foreign key (customer_id) references public.customer on update cascade on delete set null,
            constraint payment_p2020_03_staff_id_fkey
                foreign key (staff_id) references public.staff on update cascade on delete set null,
            constraint payment_p2020_03_rental_id_fkey
                foreign key (rental_id) references public.rental on update cascade on delete set null
            )
        FOR VALUES FROM ('2020-03-01 00:00:00+00') TO ('2020-04-01 00:00:00+00');

create index payment_p2020_03_customer_id_idx
    on public.payment_p2020_03 (customer_id);

create index idx_fk_payment_p2020_03_customer_id
    on public.payment_p2020_03 (customer_id);

create index idx_fk_payment_p2020_03_staff_id
    on public.payment_p2020_03 (staff_id);

create table public.payment_p2020_04
    partition of public.payment
        (
            constraint payment_p2020_04_customer_id_fkey
                foreign key (customer_id) references public.customer on update cascade on delete set null,
            constraint payment_p2020_04_staff_id_fkey
                foreign key (staff_id) references public.staff on update cascade on delete set null,
            constraint payment_p2020_04_rental_id_fkey
                foreign key (rental_id) references public.rental on update cascade on delete set null
            )
        FOR VALUES FROM ('2020-04-01 00:00:00+00') TO ('2020-05-01 00:00:00+00');

create index payment_p2020_04_customer_id_idx
    on public.payment_p2020_04 (customer_id);

create index idx_fk_payment_p2020_04_customer_id
    on public.payment_p2020_04 (customer_id);

create index idx_fk_payment_p2020_04_staff_id
    on public.payment_p2020_04 (staff_id);

create table public.payment_p2020_05
    partition of public.payment
        (
            constraint payment_p2020_05_customer_id_fkey
                foreign key (customer_id) references public.customer on update cascade on delete set null,
            constraint payment_p2020_05_staff_id_fkey
                foreign key (staff_id) references public.staff on update cascade on delete set null,
            constraint payment_p2020_05_rental_id_fkey
                foreign key (rental_id) references public.rental on update cascade on delete set null
            )
        FOR VALUES FROM ('2020-05-01 00:00:00+00') TO ('2020-06-01 00:00:00+00');

create index payment_p2020_05_customer_id_idx
    on public.payment_p2020_05 (customer_id);

create index idx_fk_payment_p2020_05_customer_id
    on public.payment_p2020_05 (customer_id);

create index idx_fk_payment_p2020_05_staff_id
    on public.payment_p2020_05 (staff_id);

create table public.payment_p2020_06
    partition of public.payment
        (
            constraint payment_p2020_06_customer_id_fkey
                foreign key (customer_id) references public.customer on update cascade on delete set null,
            constraint payment_p2020_06_staff_id_fkey
                foreign key (staff_id) references public.staff on update cascade on delete set null,
            constraint payment_p2020_06_rental_id_fkey
                foreign key (rental_id) references public.rental on update cascade on delete set null
            )
        FOR VALUES FROM ('2020-06-01 00:00:00+00') TO ('2020-07-01 00:00:00+00');

create index payment_p2020_06_customer_id_idx
    on public.payment_p2020_06 (customer_id);

create index idx_fk_payment_p2020_06_customer_id
    on public.payment_p2020_06 (customer_id);

create index idx_fk_payment_p2020_06_staff_id
    on public.payment_p2020_06 (staff_id);

create index idx_fk_inventory_id
    on public.rental (inventory_id);

create unique index idx_unq_rental_rental_date_inventory_id_customer_id
    on public.rental (rental_date, inventory_id, customer_id, customer_name, film_title, staff_name);

create unique index idx_unq_manager_staff_id
    on public.store (manager_staff_id);

create function public.inventory_in_stock(p_inventory_id integer) returns boolean
    language plpgsql
as
$$
DECLARE
    v_rentals INTEGER;
    v_out     INTEGER;
BEGIN
    -- AN ITEM IS IN-STOCK IF THERE ARE EITHER NO ROWS IN THE rental TABLE
    -- FOR THE ITEM OR ALL ROWS HAVE return_date POPULATED

    SELECT count(*)
    INTO v_rentals
    FROM rental
    WHERE inventory_id = p_inventory_id;

    IF v_rentals = 0 THEN
        RETURN TRUE;
    END IF;

    SELECT COUNT(rental_id)
    INTO v_out
    FROM inventory
             LEFT JOIN rental USING (inventory_id)
    WHERE inventory.inventory_id = p_inventory_id
      AND rental.return_date IS NULL;

    IF v_out > 0 THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END
$$;

create function public.last_day(timestamp with time zone) returns date
    immutable
    strict
    language sql
as
$$
SELECT CASE
           WHEN EXTRACT(MONTH FROM $1) = 12 THEN
               (((EXTRACT(YEAR FROM $1) + 1) operator (pg_catalog.||) '-01-01')::date - INTERVAL '1 day')::date
           ELSE
               ((EXTRACT(YEAR FROM $1) operator (pg_catalog.||) '-' operator (pg_catalog.||)
                 (EXTRACT(MONTH FROM $1) + 1) operator (pg_catalog.||) '-01')::date - INTERVAL '1 day')::date
           END
$$;

create view public.actor_info(actor_id, first_name, last_name, film_info) as
SELECT a.actor_id,
       a.first_name,
       a.last_name,
       group_concat(DISTINCT ((c.name || ': '::text) || (SELECT group_concat(f.title) AS group_concat
                                                         FROM ((film f
                                                             JOIN film_category fc_1 ON ((f.film_id = fc_1.film_id)))
                                                                  JOIN film_actor fa_1 ON ((f.film_id = fa_1.film_id)))
                                                         WHERE ((fc_1.category_id = c.category_id) AND (fa_1.actor_id = a.actor_id))
                                                         GROUP BY fa_1.actor_id))) AS film_info
FROM (((actor a
    LEFT JOIN film_actor fa ON ((a.actor_id = fa.actor_id)))
    LEFT JOIN film_category fc ON ((fa.film_id = fc.film_id)))
         LEFT JOIN category c ON ((fc.category_id = c.category_id)))
GROUP BY a.actor_id, a.first_name, a.last_name;

create view public.customer_list(id, name, address, "zip code", phone, city, country, notes, sid) as
SELECT cu.customer_id                                 AS id,
       ((cu.first_name || ' '::text) || cu.last_name) AS name,
       a.address,
       a.postal_code                                  AS "zip code",
       a.phone,
       city.city,
       country.country,
       CASE
           WHEN cu.activebool THEN 'active'::text
           ELSE ''::text
           END                                        AS notes,
       cu.store_id                                    AS sid
FROM (((customer cu
    JOIN address a ON ((cu.address_id = a.address_id)))
    JOIN city ON ((a.city_id = city.city_id)))
         JOIN country ON ((city.country_id = country.country_id)));

create view public.film_list(fid, title, description, category, price, length, rating, actors) as
SELECT film.film_id                                                       AS fid,
       film.title,
       film.description,
       category.name                                                      AS category,
       film.rental_rate                                                   AS price,
       film.length,
       film.rating,
       group_concat(((actor.first_name || ' '::text) || actor.last_name)) AS actors
FROM ((((category
    LEFT JOIN film_category ON ((category.category_id = film_category.category_id)))
    LEFT JOIN film ON ((film_category.film_id = film.film_id)))
    JOIN film_actor ON ((film.film_id = film_actor.film_id)))
         JOIN actor ON ((film_actor.actor_id = actor.actor_id)))
GROUP BY film.film_id, film.title, film.description, category.name, film.rental_rate, film.length, film.rating;

create view public.nicer_but_slower_film_list(fid, title, description, category, price, length, rating, actors) as
SELECT film.film_id                                                                                          AS fid,
       film.title,
       film.description,
       category.name                                                                                         AS category,
       film.rental_rate                                                                                      AS price,
       film.length,
       film.rating,
       group_concat((((upper("substring"(actor.first_name, 1, 1)) || lower("substring"(actor.first_name, 2))) ||
                      upper("substring"(actor.last_name, 1, 1))) || lower("substring"(actor.last_name, 2)))) AS actors
FROM ((((category
    LEFT JOIN film_category ON ((category.category_id = film_category.category_id)))
    LEFT JOIN film ON ((film_category.film_id = film.film_id)))
    JOIN film_actor ON ((film.film_id = film_actor.film_id)))
         JOIN actor ON ((film_actor.actor_id = actor.actor_id)))
GROUP BY film.film_id, film.title, film.description, category.name, film.rental_rate, film.length, film.rating;

create view public.sales_by_film_category(category, total_sales) as
SELECT c.name        AS category,
       sum(p.amount) AS total_sales
FROM (((((payment p
    JOIN rental r ON ((p.rental_id = r.rental_id)))
    JOIN inventory i ON ((r.inventory_id = i.inventory_id)))
    JOIN film f ON ((i.film_id = f.film_id)))
    JOIN film_category fc ON ((f.film_id = fc.film_id)))
         JOIN category c ON ((fc.category_id = c.category_id)))
GROUP BY c.name
ORDER BY (sum(p.amount)) DESC;

create view public.sales_by_store(store, manager, total_sales) as
SELECT ((c.city || ','::text) || cy.country)        AS store,
       ((m.first_name || ' '::text) || m.last_name) AS manager,
       sum(p.amount)                                AS total_sales
FROM (((((((payment p
    JOIN rental r ON ((p.rental_id = r.rental_id)))
    JOIN inventory i ON ((r.inventory_id = i.inventory_id)))
    JOIN store s ON ((i.store_id = s.store_id)))
    JOIN address a ON ((s.address_id = a.address_id)))
    JOIN city c ON ((a.city_id = c.city_id)))
    JOIN country cy ON ((c.country_id = cy.country_id)))
         JOIN staff m ON ((s.manager_staff_id = m.staff_id)))
GROUP BY cy.country, c.city, s.store_id, m.first_name, m.last_name
ORDER BY cy.country, c.city;

create view public.staff_list(id, name, address, "zip code", phone, city, country, sid) as
SELECT s.staff_id                                   AS id,
       ((s.first_name || ' '::text) || s.last_name) AS name,
       a.address,
       a.postal_code                                AS "zip code",
       a.phone,
       city.city,
       country.country,
       s.store_id                                   AS sid
FROM (((staff s
    JOIN address a ON ((s.address_id = a.address_id)))
    JOIN city ON ((a.city_id = city.city_id)))
         JOIN country ON ((city.country_id = country.country_id)));

create function public.film_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) returns SETOF integer
    language sql
as
$$
SELECT inventory_id
FROM inventory
WHERE film_id = $1
  AND store_id = $2
  AND inventory_in_stock(inventory_id);
$$;

create function public.film_not_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) returns SETOF integer
    language sql
as
$$
SELECT inventory_id
FROM inventory
WHERE film_id = $1
  AND store_id = $2
  AND NOT inventory_in_stock(inventory_id);
$$;

create function public.get_customer_balance(p_customer_id integer, p_effective_date timestamp with time zone) returns numeric
    language plpgsql
as
$$
    --#OK, WE NEED TO CALCULATE THE CURRENT BALANCE GIVEN A CUSTOMER_ID AND A DATE
    --#THAT WE WANT THE BALANCE TO BE EFFECTIVE FOR. THE BALANCE IS:
    --#   1) RENTAL FEES FOR ALL PREVIOUS RENTALS
    --#   2) ONE DOLLAR FOR EVERY DAY THE PREVIOUS RENTALS ARE OVERDUE
    --#   3) IF A FILM IS MORE THAN RENTAL_DURATION * 2 OVERDUE, CHARGE THE REPLACEMENT_COST
    --#   4) SUBTRACT ALL PAYMENTS MADE BEFORE THE DATE SPECIFIED
DECLARE
    v_rentfees DECIMAL(5, 2); --#FEES PAID TO RENT THE VIDEOS INITIALLY
    v_overfees INTEGER; --#LATE FEES FOR PRIOR RENTALS
    v_payments DECIMAL(5, 2); --#SUM OF PAYMENTS MADE PREVIOUSLY
BEGIN
    SELECT COALESCE(SUM(film.rental_rate), 0)
    INTO v_rentfees
    FROM film,
         inventory,
         rental
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(IF((rental.return_date - rental.rental_date) > (film.rental_duration * '1 day'::interval),
                           ((rental.return_date - rental.rental_date) - (film.rental_duration * '1 day'::interval)),
                           0)), 0)
    INTO v_overfees
    FROM rental,
         inventory,
         film
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(payment.amount), 0)
    INTO v_payments
    FROM payment
    WHERE payment.payment_date <= p_effective_date
      AND payment.customer_id = p_customer_id;

    RETURN v_rentfees + v_overfees - v_payments;
END
$$;

create function public.inventory_held_by_customer(p_inventory_id integer) returns integer
    language plpgsql
as
$$
DECLARE
    v_customer_id INTEGER;
BEGIN

    SELECT customer_id
    INTO v_customer_id
    FROM rental
    WHERE return_date IS NULL
      AND inventory_id = p_inventory_id;

    RETURN v_customer_id;
END
$$;

create or replace function public.last_updated() returns trigger
    language plpgsql
as
$$
BEGIN
    --RAISE NOTICE 'New = (%)', NEW;
	NEW.modified_by = coalesce(NEW.modified_by, current_user);
    -- this does not work because if you update a single 
	-- column, say title, then the rest of the row is computed from the current row version so modified_by wont be null
    -- You always have to call your updates with modified_by specified in your queries

    NEW.modified = CURRENT_TIMESTAMP;
    RETURN NEW;
END
$$;

create trigger last_updated
    before update
    on public.customer
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.actor
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.category
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.film
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.film_actor
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.film_category
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.address
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.city
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.country
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.inventory
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.language
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.rental
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.staff
    for each row
execute procedure public.last_updated();

create trigger last_updated
    before update
    on public.store
    for each row
execute procedure public.last_updated();

create function public.rewards_report(min_monthly_purchases integer, min_dollar_amount_purchased numeric) returns SETOF customer
    security definer
    language plpgsql
as
$$
DECLARE
    last_month_start DATE;
    last_month_end   DATE;
    rr               RECORD;
    tmpSQL           TEXT;
BEGIN

    /* Some sanity checks... */
    IF min_monthly_purchases = 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases parameter must be > 0';
    END IF;
    IF min_dollar_amount_purchased = 0.00 THEN
        RAISE EXCEPTION 'Minimum monthly dollar amount purchased parameter must be > $0.00';
    END IF;

    last_month_start := CURRENT_DATE - '3 month'::interval;
    last_month_start :=
            to_date((extract(YEAR FROM last_month_start) || '-' || extract(MONTH FROM last_month_start) || '-01'),
                    'YYYY-MM-DD');
    last_month_end := LAST_DAY(last_month_start);

    /*
    Create a temporary storage area for Customer IDs.
    */
    CREATE TEMPORARY TABLE tmpCustomer
    (
        customer_id INTEGER NOT NULL PRIMARY KEY
    );

    /*
    Find all customers meeting the monthly purchase requirements
    */

    tmpSQL := 'INSERT INTO tmpCustomer (customer_id)
        SELECT p.customer_id
        FROM payment AS p
        WHERE DATE(p.payment_date) BETWEEN ' || quote_literal(last_month_start) || ' AND ' ||
              quote_literal(last_month_end) || '
        GROUP BY customer_id
        HAVING SUM(p.amount) > ' || min_dollar_amount_purchased || '
        AND COUNT(customer_id) > ' || min_monthly_purchases;

    EXECUTE tmpSQL;

    /*
    Output ALL customer information of matching rewardees.
    Customize output as needed.
    */
    FOR rr IN EXECUTE 'SELECT c.* FROM tmpCustomer AS t INNER JOIN customer AS c ON t.customer_id = c.customer_id'
        LOOP
            RETURN NEXT rr;
        END LOOP;

    /* Clean up */
    tmpSQL := 'DROP TABLE tmpCustomer';
    EXECUTE tmpSQL;

    RETURN;
END
$$;