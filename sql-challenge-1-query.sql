/* --------------------
   Case Study Questions
   --------------------*/


-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id,
    SUM(m.price) AS total_gasto
FROM sales s
JOIN menu m
	ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 1;

-- 2. How many days has each customer visited the restaurant?
SELECT
	s.customer_id,
    COUNT(DISTINCT s.order_date) AS total_dias
FROM sales s
GROUP BY 1;

-- 3. What was the first item from the menu purchased by each customer?
WITH cte_primeiro AS (
	SELECT
		s.customer_id,
		m.product_name,
		ROW_NUMBER() OVER (
							PARTITION BY s.customer_id
							ORDER BY s.order_date,
									s.product_id
							) AS item
	FROM sales s
	JOIN menu m
		ON m.product_id = s.product_id
)
SELECT * 
FROM cte_primeiro
where item = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
	m.product_name,
    COUNT(s.product_id) AS vezes_comprado
FROM sales s
JOIN menu m
	ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
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

-- 6. Which item was purchased first by the customer after they became a member?
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


-- 7. Which item was purchased just before the customer became a member?
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

-- 8. What is the total items and amount spent for each member before they became a member?
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

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
	customer_id,
    SUM(CASE
		WHEN product_name = "sushi" THEN price * 10 * 2
		ELSE price * 10 END) AS points_multi
FROM menu AS M
JOIN sales AS s
	ON s.product_id = m.product_id
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
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