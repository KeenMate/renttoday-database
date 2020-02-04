update payment set customer_name = helpers.reversed_full_name(c.first_name, c.last_name)
from customer c
where c.customer_id = payment.customer_id;

update payment set staff_name = helpers.reversed_full_name(s.first_name, s.last_name)
from staff s
where s.staff_id = payment.staff_id;

update rental set customer_name = helpers.reversed_full_name(c.first_name, c.last_name)
from customer c
where c.customer_id = rental.customer_id;

update rental set staff_name = helpers.reversed_full_name(s.first_name, s.last_name)
from staff s
where s.staff_id = rental.staff_id;

update rental set film_title = f.title
from inventory i
inner join film f on i.film_id = f.film_id
where i.inventory_id = rental.inventory_id;