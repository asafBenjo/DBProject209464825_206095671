SELECT u.username, u.email, COUNT(t.ticket_id) AS open_tickets
FROM "User" u
JOIN Support_Tickets t ON u.user_id = t.user_id
WHERE t.ticket_id IN (
    SELECT ticket_id FROM Ticket_Status WHERE status = 'Waiting for Agent'
)
GROUP BY u.username, u.email
ORDER BY open_tickets DESC;

SELECT 
  it.issue_type_name,
  AVG(EXTRACT(EPOCH FROM (ts.modified_date::timestamp - t.ticket_date::timestamp)) / 3600) AS avg_hours
FROM 
  Support_Tickets t
JOIN 
  Ticket_Status ts ON t.ticket_id = ts.ticket_id
JOIN 
  Issue_Types it ON t.issue_type_id = it.issue_type_id
GROUP BY 
  it.issue_type_name;

SELECT 
  sa.support_agent_id,
  sa.agent_name,
  TO_CHAR(t.ticket_date, 'YYYY-MM') AS year_month,
  COUNT(DISTINCT t.ticket_id) AS tickets_handled
FROM 
  Support_Tickets t
JOIN 
  Support_Responses sr ON t.ticket_id = sr.ticket_id
JOIN 
  Support_Agent sa ON sr.support_agent_id = sa.support_agent_id
GROUP BY 
  sa.support_agent_id, sa.agent_name, TO_CHAR(t.ticket_date, 'YYYY-MM')
ORDER BY 
  sa.support_agent_id ASC, year_month ASC;

SELECT 
  u.user_id,
  u.username,
  COUNT(t.ticket_id) AS total_tickets
FROM 
  "User" u
JOIN 
  Support_Tickets t ON u.user_id = t.user_id
WHERE 
  t.ticket_id IN (
    SELECT ticket_id 
    FROM Ticket_Status 
    WHERE status = 'Resolved'
)
GROUP BY 
  u.user_id, u.username
ORDER BY 
  u.user_id ASC;



SELECT 
  u.user_id,
  u.username,
  sa.support_agent_id,
  sa.agent_name,
  t.ticket_id,
  ts.status,
  ts.modified_date
FROM 
  Support_Tickets t
JOIN 
  "User" u ON t.user_id = u.user_id
JOIN 
  Ticket_Status ts ON t.ticket_id = ts.ticket_id
JOIN 
  Support_Responses sr ON t.ticket_id = sr.ticket_id  
JOIN 
  Support_Agent sa ON sr.support_agent_id = sa.support_agent_id  
WHERE 
  ts.modified_date = (
    SELECT MAX(modified_date) 
    FROM Ticket_Status 
    WHERE ticket_id = t.ticket_id
);




SELECT it.issue_type_name, AVG(response_count) AS avg_responses
FROM (
    SELECT t.issue_type_id, COUNT(sr.response_id) AS response_count
    FROM Support_Tickets t
    LEFT JOIN Support_Responses sr ON t.ticket_id = sr.ticket_id
    GROUP BY t.ticket_id, t.issue_type_id
) AS subq
JOIN Issue_Types it ON subq.issue_type_id = it.issue_type_id
GROUP BY it.issue_type_name;


SELECT sr.response_description, sr.response_date, sa.agent_name
FROM Support_Responses sr
JOIN Support_Agent sa ON sr.support_agent_id = sa.support_agent_id
WHERE sr.ticket_id = 123 -- תחליף למספר טיקט רלוונטי
ORDER BY sr.response_date DESC;



SELECT 
    sa.agent_name,
    TO_CHAR(sr.response_date, 'YYYY-MM') AS year_month,
    COUNT(sr.response_id) AS responses_count,
    MAX(sr.response_date) AS last_response_date
FROM 
    Support_Responses sr
JOIN 
    Support_Agent sa ON sr.support_agent_id = sa.support_agent_id
GROUP BY 
    sa.agent_name, TO_CHAR(sr.response_date, 'YYYY-MM')
ORDER BY 
    sa.agent_name, year_month;



DELETE FROM Support_Responses
WHERE response_date < (CURRENT_DATE - INTERVAL '1 year');




-- שלב 1: מחיקת תגובות (Support_Responses) המשויכות לקריאות שירות ישנות
DELETE FROM Support_Responses
WHERE ticket_id IN (
    SELECT ticket_id
    FROM Support_Tickets
    WHERE ticket_date < '2022-05-06' -- קריאות שנוצרו לפני יותר מ-3 שנים מהיום (2025-05-06)
);



DELETE FROM Support_Agent
WHERE support_agent_id NOT IN (
    SELECT DISTINCT support_agent_id
    FROM Support_Responses
);

DELETE FROM "User"
WHERE user_id = '8';



UPDATE Ticket_Status
SET status = 'Resolved', modified_date = CURRENT_DATE
WHERE status_id = '3';



UPDATE Support_Agent
SET role = 'Senior Agent'
WHERE support_agent_id IN (
    SELECT sr.support_agent_id
    FROM Support_Responses sr
    GROUP BY sr.support_agent_id
    HAVING COUNT(DISTINCT sr.ticket_id) > 4
);


UPDATE Issue_Types
SET priority = '1'
FROM Issue_Types it
JOIN Support_Tickets st ON it.issue_type_id = st.issue_type_id
WHERE it.issue_type_name = 'Buffering Issues';