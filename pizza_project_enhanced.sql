
-- Existing Queries

select * from pizzas;
select * from pizza_types;
select * from orders;
select * from order_details;

-- Total revenue
select sum(pizzas.price * order_details.quantity)
from pizzas join order_details on pizzas.pizza_id = order_details.pizza_id;

-- Sales by Day
select orders.order_date, sum(pizzas.price * order_details.quantity)
from order_details
join orders on order_details.order_id = orders.order_id
join pizzas on order_details.pizza_id = pizzas.pizza_id
group by orders.order_date;

-- Most popular pizzas
SELECT pizza_types.name, SUM(order_details.quantity * pizzas.price) AS total_revenue
FROM order_details
JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
JOIN pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY pizza_types.name
order by total_revenue desc
limit 5;

-- Most expensive pizzas
select pizza_types.name, sum(pizzas.price) as ris
from pizzas
join pizza_types on pizzas.pizza_type_id = pizza_types.pizza_type_id
group by pizza_types.name
order by ris desc
limit 1;

-- Top 5 Best-Selling Pizzas
select pizza_types.name, sum(pizzas.price) as total
from pizzas
join pizza_types on pizzas.pizza_type_id = pizza_types.pizza_type_id
group by pizza_types.name
order by total desc
limit 5;

WITH pizza_sales AS (
  SELECT 
      p.name, 
      SUM(od.quantity) AS total_sold
  FROM 
      order_details od
  JOIN pizzas p ON od.pizza_id = p.pizza_id
  GROUP BY p.name
)
SELECT * FROM pizza_sales
ORDER BY total_sold DESC
LIMIT 5;

SELECT 
    pizzas.size,
    SUM(order_details.quantity),
    CASE 
      WHEN SUM(order_details.quantity) > 5 THEN 'Very Popular'
      WHEN SUM(order_details.quantity) > 2 THEN 'Moderate'
      ELSE 'Low'
    END AS popularity_label
FROM 
    order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pizzas.size;


-- === Enhancements Below ===

-- Enhancement: View for Daily Revenue
CREATE VIEW daily_revenue AS
SELECT orders.order_date, 
       ROUND(SUM(pizzas.price * order_details.quantity), 2) AS total_revenue
FROM order_details
JOIN orders ON order_details.order_id = orders.order_id
JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
GROUP BY orders.order_date;

-- Enhancement: Stored Procedure to Get Sales on a Specific Date
DELIMITER //
CREATE PROCEDURE get_sales_by_date(IN input_date DATE)
BEGIN
  SELECT 
      input_date AS sales_date,
      ROUND(SUM(pizzas.price * order_details.quantity), 2) AS total_sales
  FROM orders
  JOIN order_details ON orders.order_id = order_details.order_id
  JOIN pizzas ON order_details.pizza_id = pizzas.pizza_id
  WHERE orders.order_date = input_date;
END //
DELIMITER ;

-- Enhancement: Function to Apply Discount
DELIMITER //
CREATE FUNCTION apply_discount(price DECIMAL(10,2), quantity INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  IF quantity >= 5 THEN
    RETURN price * 0.90;
  ELSE
    RETURN price;
  END IF;
END //
DELIMITER ;

-- Enhancement: CTE for Most Sold Category
WITH category_sales AS (
  SELECT pt.category, SUM(od.quantity) AS total_quantity
  FROM order_details od
  JOIN pizzas p ON od.pizza_id = p.pizza_id
  JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
  GROUP BY pt.category
)
SELECT * FROM category_sales ORDER BY total_quantity DESC;

-- Enhancement: CASE usage to Label Pizza Category Performance
SELECT 
    pt.category,
    SUM(od.quantity) AS total_sold,
    CASE 
      WHEN SUM(od.quantity) >= 10 THEN 'Best Seller'
      WHEN SUM(od.quantity) >= 5 THEN 'Good Seller'
      ELSE 'Low Seller'
    END AS performance
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category;
