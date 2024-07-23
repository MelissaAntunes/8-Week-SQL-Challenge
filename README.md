/* --------------------
   Case Study Questions
   --------------------*/
1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- 1. What is the total amount each customer spent at the restaurant?
```sql
SELECT
	s.customer_id,
	SUM(m.price) AS total_gasto
FROM sales s
JOIN menu m
	ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 1;
```
| customer_id | total_gasto |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

-- 2. How many days has each customer visited the restaurant?
```sql
SELECT
	s.customer_id,
	COUNT(DISTINCT s.order_date) AS total_dias
FROM sales s
GROUP BY 1;
```
|customer_id| total_dias |
|-----------|------------|
|A          |4           |
|B          |6           |
|C          |2           |

-- 3. What was the first item from the menu purchased by each customer?
```sql
WITH cte_primeiro AS (
	SELECT
		s.customer_id,
		m.product_name,
		ROW_NUMBER() OVER (
			PARTITION BY s.customer_id
			ORDER BY s.order_date, s.product_id
			) AS item
	FROM sales s
	JOIN menu m
		ON m.product_id = s.product_id
)
SELECT * 
FROM cte_primeiro
where item = 1;
```
| customer_id | product_name |    item    |
| ----------- | ------------ | ---------- |
| A           | sushi        | 1          |
| B           | curry        | 1          |
| C           | ramen        | 1          |

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
SELECT
	m.product_name,
	COUNT(s.product_id) AS vezes_comprado
FROM sales s
JOIN menu m
	ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
```
|product_name|vezes_comprado|
|------------|--------------|
|ramen       |8             |

-- 5. Which item was the most popular for each customer?
```sql
WITH cte_cont_pedido AS (
	SELECT 
		s.customer_id,
		m.product_name,
		COUNT(*) AS cont_pedido
	FROM sales s 
	JOIN menu m
		ON m.product_id = s.product_id
	GROUP BY s.customer_id, m.product_name
	ORDER BY s.customer_id, cont_pedido DESC
),
cte_popular AS (
	SELECT
		*,
		RANK() OVER(
			PARTITION BY customer_id
			ORDER BY cont_pedido DESC
		) AS pop_rank
FROM cte_cont_pedido
)
SELECT * 
FROM cte_popular
WHERE pop_rank = 1;
```
|customer_id|product_name|cont_pedido|  pop_rank |
|-----------|------------|-----------|-----------|
|A          |ramen       |3          |1          |
|B          |curry       |2          |1          |
|B          |sushi       |2          |1          |
|B          |ramen       |2          |1          |
|C          |ramen       |3          |1          |

-- 6. Which item was purchased first by the customer after they became a member?
```sql
WITH cte_first_item_purc AS (
	SELECT
		s.customer_id,
		s.order_date,
		mem.join_date,
		m.product_name,
		RANK() OVER(
			PARTITION BY s.customer_id
			ORDER BY s.order_date
		) AS rank_first_purc
	FROM sales AS s
	JOIN members AS mem
		ON mem.customer_id = s.customer_id
	JOIN menu AS m
		ON m.product_id = s.product_id
	WHERE s.order_date >= mem.join_date
)
SELECT 
	customer_id,
	product_name
FROM cte_first_item_purc
WHERE rank_first_purc = 1;
```
| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| B           | sushi        |

-- 7. Which item was purchased just before the customer became a member?
```sql
WITH cte_first_item_purc AS (
	SELECT
		s.customer_id,
		s.order_date,
		mem.join_date,
		m.product_name,
		RANK() OVER(
			PARTITION BY s.customer_id
			ORDER BY s.order_date DESC
		) AS rank_first_purc
	FROM sales AS s
	JOIN members AS mem
		ON mem.customer_id = s.customer_id
	JOIN menu AS m
		ON m.product_id = s.product_id
	WHERE s.order_date < mem.join_date
)
SELECT 
	customer_id,
	product_name
FROM cte_first_item_purc
WHERE rank_first_purc = 1;
```
| customer_id | product_name |
| ----------- | ------------ | 
| A           | sushi        | 
| A           | curry        | 
| B           | sushi        | 

-- 8. What is the total items and amount spent for each member before they became a member?
```sql
SELECT
	s.customer_id,
	COUNT(m.product_id) AS total_items,
	SUM(price) AS amount_spent
FROM sales AS s
JOIN members AS mem
	ON mem.customer_id = s.customer_id
JOIN menu AS m
	ON m.product_id = s.product_id
WHERE s.order_date < mem.join_date
GROUP BY 1
ORDER BY amount_spent;
```
| customer_id | total_items | amount_spent |
| ----------- | ----------- | ------------ |
| A           | 2           | 25           |
| B           | 3           | 40           |

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
SELECT 
	customer_id,
	SUM(CASE
		WHEN product_name = "sushi" THEN price * 10 * 2
		ELSE price * 10 END) AS points_multi
FROM menu AS M
JOIN sales AS s
	ON s.product_id = m.product_id
GROUP BY customer_id;
```
| customer_id | total_points |
| ----------- | ------------ |
| A           | 860          |
| B           | 940          |
| C           | 360          |

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
WITH cte AS (
	SELECT
		customer_id,
		join_date,
		DATE_ADD(join_date, INTERVAL 6 DAY) AS first_week,
		LAST_DAY('2021-01-31') AS last_date
	FROM members
)
SELECT
	s.customer_id,
	SUM(CASE
		WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
		WHEN s.order_date BETWEEN cte.join_date AND cte.first_week THEN m.price * 10 * 2
		ELSE m.price * 10 END) AS points
FROM sales AS s
JOIN cte
	ON s.customer_id = cte.customer_id
	AND s.order_date <= cte.last_date
JOIN menu AS m
	ON m.product_id = s.product_id
GROUP BY s.customer_id;
```
| customer_id |  points  |
| ----------- | -------- |
| B           | 820      |
| A           | 1370     |
