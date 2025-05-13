# שאילתות SELECT

## 1. משתמשים עם הכי הרבה פניות שממתינות למענה

```sql
SELECT u.username, u.email, COUNT(t.ticket_id) AS open_tickets
FROM "User" u
JOIN Support_Tickets t ON u.user_id = t.user_id
WHERE t.ticket_id IN (
    SELECT ticket_id FROM Ticket_Status WHERE status = 'Waiting for Agent'
)
GROUP BY u.username, u.email
ORDER BY open_tickets DESC;
```
![שאילתה 1](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%201.png)

## 2. זמן טיפול ממוצע לפי סוג בעיה

```sql
SELECT it.issue_type_name,
       AVG(EXTRACT(EPOCH FROM (ts.modified_date::timestamp - t.ticket_date::timestamp)) / 3600) AS avg_hours
FROM Support_Tickets t
JOIN Ticket_Status ts ON t.ticket_id = ts.ticket_id
JOIN Issue_Types it ON t.issue_type_id = it.issue_type_id
GROUP BY it.issue_type_name;
```
![שאילתה 2](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%202.png)

## 3. מספר קריאות שטופלו ע"י נציג כל חודש

```sql
SELECT sa.support_agent_id, sa.agent_name,
       TO_CHAR(t.ticket_date, 'YYYY-MM') AS year_month,
       COUNT(DISTINCT t.ticket_id) AS tickets_handled
FROM Support_Tickets t
JOIN Support_Responses sr ON t.ticket_id = sr.ticket_id
JOIN Support_Agent sa ON sr.support_agent_id = sa.support_agent_id
GROUP BY sa.support_agent_id, sa.agent_name, TO_CHAR(t.ticket_date, 'YYYY-MM')
ORDER BY sa.support_agent_id ASC, year_month ASC;
```
![שאילתה 3](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%203.png)

## 4. קריאות שטופלו בהצלחה (סטטוס Resolved) לכל משתמש

```sql
SELECT u.user_id, u.username, COUNT(t.ticket_id) AS total_tickets
FROM "User" u
JOIN Support_Tickets t ON u.user_id = t.user_id
WHERE t.ticket_id IN (
    SELECT ticket_id FROM Ticket_Status WHERE status = 'Resolved'
)
GROUP BY u.user_id, u.username
ORDER BY u.user_id ASC;
```
![שאילתה 4](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%204.png)

## 5. פרטי קריאה, סטטוס אחרון ונציג

```sql
SELECT u.user_id, u.username, sa.support_agent_id, sa.agent_name,
       t.ticket_id, ts.status, ts.modified_date
FROM Support_Tickets t
JOIN "User" u ON t.user_id = u.user_id
JOIN Ticket_Status ts ON t.ticket_id = ts.ticket_id
JOIN Support_Responses sr ON t.ticket_id = sr.ticket_id
JOIN Support_Agent sa ON sr.support_agent_id = sa.support_agent_id
WHERE ts.modified_date = (
    SELECT MAX(modified_date) FROM Ticket_Status WHERE ticket_id = t.ticket_id
);
```
![שאילתה 5](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%205.png)

## 6. ממוצע תגובות לפי סוג בעיה

```sql
SELECT it.issue_type_name, AVG(response_count) AS avg_responses
FROM (
    SELECT t.issue_type_id, COUNT(sr.response_id) AS response_count
    FROM Support_Tickets t
    LEFT JOIN Support_Responses sr ON t.ticket_id = sr.ticket_id
    GROUP BY t.ticket_id, t.issue_type_id
) AS subq
JOIN Issue_Types it ON subq.issue_type_id = it.issue_type_id
GROUP BY it.issue_type_name;
```
![שאילתה 6](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%94%206.png)

## 7. תגובות לקריאה מסוימת

```sql
SELECT sr.response_description, sr.response_date, sa.agent_name
FROM Support_Responses sr
JOIN Support_Agent sa ON sr.support_agent_id = sa.support_agent_id
WHERE sr.ticket_id = 123
ORDER BY sr.response_date DESC;
```

## 8. מספר תגובות של נציג לפי חודש

```sql
SELECT sa.agent_name,
       TO_CHAR(sr.response_date, 'YYYY-MM') AS year_month,
       COUNT(sr.response_id) AS responses_count,
       MAX(sr.response_date) AS last_response_date
FROM Support_Responses sr
JOIN Support_Agent sa ON sr.support_agent_id = sa.support_agent_id
GROUP BY sa.agent_name, TO_CHAR(sr.response_date, 'YYYY-MM')
ORDER BY sa.agent_name, year_month;
```
![שאילתה 8](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%208.png)

# DELETE

## 1.  מחיקת טיקטים שהסטטוס שלהם 'Resolved' ותאריך העדכון האחרון הוא יותר מחודש

```sql
DELETE FROM Ticket_Status
WHERE ticket_id IN (
    SELECT ticket_id
    FROM Ticket_Status
    WHERE status = 'Resolved'
      AND modified_date < (CURRENT_DATE - INTERVAL '1 month')
);

```
![מחיקה 1](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20delete/%D7%A6%D7%99%D7%9C%D7%95%D7%9D%20%D7%9E%D7%A1%D7%9A%202025-04-28%20164229.png)


## 2. מחיקת תגובות לקריאות ישנות (לפני 6 במאי 2022)

```sql
DELETE FROM Support_Responses
WHERE ticket_id IN (
    SELECT ticket_id FROM Support_Tickets
    WHERE ticket_date < '2022-05-06'
);
```
![מחיקה 2](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20delete/%D7%A6%D7%99%D7%9C%D7%95%D7%9D%20%D7%9E%D7%A1%D7%9A%202025-05-06%20151930.png)

## 3. מחיקת נציגים שלא הגיבו באף קריאה

```sql
DELETE FROM Support_Agent
WHERE support_agent_id NOT IN (
    SELECT DISTINCT support_agent_id FROM Support_Responses
);
```
![מחיקה 3](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20delete/%D7%A6%D7%99%D7%9C%D7%95%D7%9D%20%D7%9E%D7%A1%D7%9A%202025-04-28%20165512.png)

# UPDATE

## 1. עדכון סטטוס ל-Resolved

```sql
UPDATE Ticket_Status
SET status = 'Resolved', modified_date = CURRENT_DATE
WHERE status_id = '3';
```
![עדכון 1](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20up%20dete/%D7%A6%D7%99%D7%9C%D7%95%D7%9D%20%D7%9E%D7%A1%D7%9A%202025-05-06%20141335.png)

## 2. קידום נציגים לרמת Senior Agent

```sql
UPDATE Support_Agent
SET role = 'Senior Agent'
WHERE support_agent_id IN (
    SELECT sr.support_agent_id
    FROM Support_Responses sr
    GROUP BY sr.support_agent_id
    HAVING COUNT(DISTINCT sr.ticket_id) > 4
);
```
![עדכון 2](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20up%20dete/%D7%A6%D7%99%D7%9C%D7%95%D7%9D%20%D7%9E%D7%A1%D7%9A%202025-05-06%20153333.png)

## 3. עדכון עדיפות לבעיה מסוג Buffering Issues

```sql
UPDATE Issue_Types
SET priority = '1'
FROM Issue_Types it
JOIN Support_Tickets st ON it.issue_type_id = st.issue_type_id
WHERE it.issue_type_name = 'Buffering Issues';
```
![עדכון 3](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20up%20dete/%D7%A6%D7%99%D7%9C%D7%95%D7%9D%20%D7%9E%D7%A1%D7%9A%202025-05-06%20152734.png)
