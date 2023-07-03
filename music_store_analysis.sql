Q1: who is the senior most employ based on job tital?

select * from employee
order by levels desc
limit 1;

Q2: which 3 country have most invoices?

select count(*) as c,billing_country 
from invoice
group by billing_COuntry
order by c desc
limit 3;

What are top 3 values of total invoice?

select total from invoice
order by total desc
limit 3

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select sum(total)as s,billing_city
from invoice
group by billing_city
order by s desc
limit 1

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
select c.first_name , c.last_name,CONCAT(c.first_name,c.last_name) as full_name ,sum(i.total) as total
From customer as c
join invoice as i
on c.customer_id=i.customer_id
group by c.customer_id
order by total desc
limit 1;

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

/*Method 1 */

SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoiceline ON invoice.invoice_id = invoiceline.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;


/* Method 2 */

select c.email,c.first_name,c.last_name,genre.name
from customer as c
join invoice
on c.customer_id=invoice.customer_id
join invoice_line
on invoice.invoice_id=invoice_line.invoice_id
join track
on invoice_line.track_id=track.track_id
join genre
on track.genre_id=genre.genre_id
where genre.name like 'Rock'
order by email asc

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands */

SELECT artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name, Milliseconds from track
where Milliseconds > (select avg(milliseconds) from track
					 )
order by milliseconds desc

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists?
Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

with best_selling_artist as  (
select artist.artist_id as artist_id,artist.name as artist_name, Sum(il.quantity*il.unit_price) as total_sales
from artist
JOin Album on album.artist_id=artist.artist_id	
join track on track.album_id=album.album_id
join invoice_line il on Il.track_id=track.track_id
group by 1
order by 3 desc
limit 1
) 
select c.first_name, c.last_name,c.customer_id,bsa.artist_name, sum(il.quantity*il.unit_price)
from customer c
join invoice i on i.customer_id=c.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
join track t on t.track_id=il.track_id
join album a on a.album_id=t.album_id
join best_selling_artist bsa on bsa.artist_id=a.artist_id
group by 1,2,3,4
order by 5 desc;

/* Q2: We want to find out the most popular music Genre for each country.
We determine the most popular genre as the genre 
with the highest amount of purchases.
Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */
with top_genre as (
select g.name,g.genre_id,count(il.quantity) as purchases,c.country,
	row_number () over(partition BY c.country order by count(il.quantity) desc) as ROwno
	from genre g
	join track t on t.genre_id=g.genre_id
	join invoice_line il on il.track_id=t.track_id
	join invoice i on i.invoice_id=il.invoice_id
	join customer c on c.customer_id=i.customer_id
	group by 1,2,4
	order by 4 asc, 2 desc
)
select * from top_genre
where Rowno<=1

/* Method 2: : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using CTE */

with top_customer as (
select c.first_name ,c.last_name, i.billing_country,sum(il.unit_price*il.quantity)as total_amount
, row_number() over(partition by i.billing_country  order by sum(il.unit_price*il.quantity)) as rn
	from customer c
	join invoice i on i.customer_id=i.customer_id
	join Invoice_line il on il.invoice_id=i.invoice_id
	group by 1,2,3
	order by 3 asc,4 desc
)
select* from top_customer where rn<=1

with recursive customer_spent as (
select c.first_name ,c.last_name, i.billing_country,sum(il.unit_price*il.quantity)as total_amount
	from customer c
	join invoice i on i.customer_id=i.customer_id
	join Invoice_line il on il.invoice_id=i.invoice_id
	group by 1,2,3
	order by 3 asc,4 desc
),
max_customer_spent as(
select max(total_amount) as max_total_amount,billing_country
	from customer_spent
	group by 2
	order by 2
)
select cs.first_name,cs.last_name,cs.billing_country,mcs.max_total_amount from
customer_spent cs
join max_customer_spent mcs on mcs.billing_country=cs.billing_country
where mcs.billing_country=cs.billing_country