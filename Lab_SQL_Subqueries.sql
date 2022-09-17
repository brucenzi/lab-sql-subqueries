use sakila;

-- 1. List all films whose length is longer than the average of all the films.

select * from film;
select avg(length) from film; -- checking the average

select film_id, length from film
where length > (select avg(length) from film)
order by length;


-- 2. Use subqueries to display all actors who appear in the film Alone Trip.

select * from film;
select * from film_actor;

select actor_id, film_id from film_actor
where film_id in (
	select film_id
    from film
    where title = "Alone Trip"
    );
	
-- 3. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.

select * from film;
select * from film_category;
select * from category;

-- using WHERE IN
select title, film_id from film
where film_id in (
	select film_id
    from film_category
    where category_id in (
		select category_id
		from category
		where name = "Family"));

-- using JOIN
select f.title, f.film_id, fc.category_id  from film f
join film_category fc on fc.film_id = f.film_id
where category_id in (
	select category_id
    from category
    where name = "Family");

-- 4. Get name and email from customers from Canada using subqueries. Do the same with joins. Note that to create a join, you will have to identify the correct tables with their primary keys and foreign keys, that will help you get the relevant information.

select * from customer;
select * from address;
select * from city;
select * from country;

-- using SUBQUERIES
 select concat(first_name, " ", last_name) as customers, email 
 from customer
 where address_id in (
	select address_id 
    from address
    where city_id in (
		select city_id 
        from city
        where country_id in (
			select country_id
            from country
            where country = "Canada")
        )
	);

-- using JOIN
select concat(cu.first_name, " ", cu.last_name) as customers, cu.email from customer cu
left join address a on a.address_id = cu.address_id
left join city ci on ci.city_id = a.city_id
left join country co on co.country_id = ci.country_id
where country = "Canada";


-- 5. Which are films starred by the most prolific actor? Most prolific actor is defined as the actor that has acted in the most number of films. 
	-- First you will have to find the most prolific actor and then use that actor_id to find the different films that he/she starred.

select * from film;
select * from film_actor;

-- double check of the required actor_id and number of films
select row_number() over(order by count(film_id) desc) ranking, actor_id, count(film_id)
from film_actor
group by actor_id;

-- subquery 
select actor_id from (
	select actor_id, count(film_id), row_number() over(order by count(film_id) desc) ranking 
    from film_actor
    group by actor_id) sub1
where ranking = 1;

-- Final query using WHERE IN
select film_id, title from film
where film_id in (
	select film_id from film_actor
	where actor_id = (
		select actor_id from (
			select actor_id, count(film_id), row_number() over(order by count(film_id) desc) ranking 
			from film_actor
			group by actor_id) sub1
		where ranking = 1));

-- Final query using JOIN
select fa.film_id, f.title from film_actor fa
left join film f on f.film_id = fa.film_id
where actor_id = (
	select actor_id from (
		select actor_id, count(film_id), row_number() over(order by count(film_id) desc) ranking 
		from film_actor
		group by actor_id) sub1
	where ranking = 1);


-- 6. Films rented by most profitable customer. 
	-- You can use the customer table and payment table to find the most profitable customer 
    -- ie the customer that has made the largest sum of payments

select * from customer;
select * from payment;
select * from rental;
select * from inventory;
select * from film;

-- quality check of required customer_id
select customer_id, sum(amount), row_number() over(order by sum(amount) desc) ranking 
from payment
group by customer_id; 

-- first query: identify the most profitable customer
select customer_id from (
	select customer_id, sum(amount), row_number() over(order by sum(amount) desc) ranking 
	from payment
	group by customer_id)sub1
where ranking = 1;

-- Final query: films rented by the most profitable customer
select title from film
where film_id in (
	select film_id
    from inventory
    where inventory_id in (
		select inventory_id
        from rental
        where rental_id in (
			select rental_id
            from payment
            where customer_id = (
				select customer_id from (
					select customer_id, sum(amount), row_number() over(order by sum(amount) desc) ranking 
					from payment
					group by customer_id)sub1
				where ranking = 1)
				)
			)
		)
;
-- 7. Get the client_id and the total_amount_spent of those clients who spent more than the average 
--    of the total_amount spent by each client.

select * from payment;

-- first query: sum amount per customer
select customer_id, sum(amount) as total 
from payment
group by customer_id;

-- second query: average of the sum amount per customer
select avg(total) Average from (
	select sum(amount) as total 
	from payment
	group by customer_id)sub1;

-- final query: clients that spent more than the average of the total amount

select customer_id, sum(amount) total_amount_spent from payment
group by customer_id
having total_amount_spent > (
	select avg(total) from (
	select sum(amount) total 
	from payment
	group by customer_id)sub1
    )
order by sum(amount) asc
;