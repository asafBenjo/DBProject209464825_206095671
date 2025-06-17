CREATE VIEW Full_Customer_Info_View1 AS
WITH LatestPayment AS (
    SELECT
        p.user_id,
        p.amount,
        p.payment_date,
        ROW_NUMBER() OVER(PARTITION BY p.user_id ORDER BY p.payment_date DESC) as rn
    FROM payments p
),
LatestTicket AS (
    SELECT
        t.user_id,
        t.ticket_id,
        t.issue_description,
        t.ticket_date,
        ROW_NUMBER() OVER(PARTITION BY t.user_id ORDER BY t.ticket_date DESC) as trn
    FROM support_tickets t
),
LatestTicketStatus AS (
    SELECT
        s.ticket_id,
        s.status,
        s.status_risk,
        s.modified_date,
        ROW_NUMBER() OVER(PARTITION BY s.ticket_id ORDER BY s.modified_date DESC) as srn
    FROM ticket_status s
)
SELECT
    u.user_id,
    u.username,
    u.email,
    u.customer_name,
    sp.plan_type,
    sp.monthly_cost,
    d.discount_percent,
    lp.amount AS last_payment_amount,
    lp.payment_date,
    lt.ticket_id,
    lt.issue_description,
    lt.ticket_date,
    lts.status,
    lts.status_risk,
    lts.modified_date
FROM "User" u
LEFT JOIN subscription_plans sp ON u.plan_id = sp.plan_id
LEFT JOIN discounts d ON u.discount_id = d.discount_id
LEFT JOIN LatestPayment lp ON u.user_id = lp.user_id AND lp.rn = 1
LEFT JOIN LatestTicket lt ON u.user_id = lt.user_id AND lt.trn = 1
LEFT JOIN LatestTicketStatus lts ON lt.ticket_id = lts.ticket_id AND lts.srn = 1
ORDER BY u.user_id; -- Added ORDER BY to sort by user_id

SELECT *
FROM Full_Customer_Info_View1
WHERE username = 'Ellery';

  SELECT DISTINCT username, last_payment_amount, status, status_risk
FROM Full_Customer_Info_View1
WHERE last_payment_amount > 5000
  AND status != 'Resolved'
  AND status_risk >= 5;


CREATE VIEW Customer_Status_Summary_View AS
SELECT
    u.user_id,
    u.username,
    u.customer_name,
    sp.plan_type,
    sp.monthly_cost,
    COUNT(s.status) AS total_status_count -- Changed s.status_id to s.status, assuming status is a relevant column for counting
FROM "User" u
LEFT JOIN subscription_plans sp ON u.plan_id = sp.plan_id
LEFT JOIN discounts d ON u.discount_id = d.discount_id
LEFT JOIN payments p ON u.user_id = p.user_id
LEFT JOIN support_tickets t ON u.user_id = t.user_id
LEFT JOIN ticket_status s ON t.ticket_id = s.ticket_id
GROUP BY
    u.user_id, u.username, u.customer_name,
    sp.plan_type, sp.monthly_cost
ORDER BY u.user_id; -- הוספנו מיון לפי user_id

SELECT *
FROM Customer_Status_Summary_View2
WHERE plan_type = 'premium'
  AND total_status_count > 6;


SELECT *
FROM Customer_Status_Summary_View
WHERE username = 'Kassia';