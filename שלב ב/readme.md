# שאילתות SELECT

## 1. מחזירה משתמשים עם טיקטים שלא נפתרו

```sql
SELECT DISTINCT t.ticket_id, u.username, u.email
FROM "User" u
JOIN Support_Tickets t ON u.user_id = t.user_id
WHERE t.ticket_id IN (
    SELECT ticket_id
    FROM Ticket_Status
    WHERE status = 'Waiting for Agent'
)
AND t.ticket_id NOT IN (
    SELECT ticket_id
    FROM Ticket_Status
    WHERE status = 'Resolved'
)
```
![שאילתה 1](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%201.png)

## 2. זמן טיפול ממוצע לפי סוג בעיה

```sql
SELECT 
  issue_type_name,
  ROUND(AVG(resolution_days), 2) AS avg_resolution_days
FROM (
  SELECT 
    it.issue_type_name,
    (MAX(ts.modified_date)::date - MIN(ts.modified_date)::date) AS resolution_days
  FROM Ticket_Status ts
  JOIN Support_Tickets t ON ts.ticket_id = t.ticket_id
  JOIN Issue_Types it ON t.issue_type_id = it.issue_type_id
  GROUP BY it.issue_type_name, ts.ticket_id
  HAVING COUNT(DISTINCT ts.status) = 3
) sub
GROUP BY issue_type_name;
```
![שאילתה 2](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%202.png)

## 3. מציאת 10 העובדים הכי פרודוקטיבים

```sql
WITH Productivity_Calculation AS (
  SELECT 
    SA.support_agent_id,
    COUNT(DISTINCT R.ticket_id) AS tickets_resolved,
    SA.Work_Hours,
    ROUND(COUNT(DISTINCT R.ticket_id) * 1.0 / NULLIF(SA.Work_Hours, 0), 2) AS productivity_per_hour
  FROM Support_Responses R
  JOIN Support_agent SA ON R.support_agent_id = SA.support_agent_id
  JOIN Ticket_Status TS ON R.ticket_id = TS.ticket_id
  WHERE TS.status = 'Resolved'
  GROUP BY SA.support_agent_id, SA.agent_name, SA.Work_Hours
)
SELECT *
FROM (
  SELECT 
    *,
    ROUND(productivity_per_hour / MAX(productivity_per_hour) OVER (), 2) * 100 AS productivity_score_out_of_100
  FROM Productivity_Calculation
) AS scored_agents
ORDER BY productivity_score_out_of_100 DESC
LIMIT 10;

```
![שאילתה 3](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%203.png)

## 4. מציאת טיקטים בעדיפות גבוהה שעדיין לא הוקצה להם סוכן

```sql
SELECT 
  ST.ticket_id,
  IT.priority,
  TS.status
FROM Support_Tickets ST
JOIN Issue_Types IT ON ST.issue_type_id = IT.issue_type_id
JOIN Ticket_Status TS ON ST.ticket_id = TS.ticket_id
WHERE IT.priority BETWEEN 4 AND 5
  AND TS.modified_date = (
      SELECT MAX(modified_date)
      FROM Ticket_Status TS2
      WHERE TS2.ticket_id = ST.ticket_id
  )
  AND TS.status IN ('Waiting for Agent')
  

```
![שאילתה 4](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%204.png)

## 5. מחזיר את כל הטיקטים שלא קיבלו תגובה לפחות חודש מהפתיחה

```sql
SELECT 
  ST.ticket_id,
  ST.ticket_date
FROM Support_Tickets ST
LEFT JOIN Support_Responses SR ON ST.ticket_id = SR.ticket_id
JOIN Issue_Types IT ON ST.issue_type_id = IT.issue_type_id
WHERE SR.response_id IS NULL
  AND DATE '2024-01-01' >= ST.ticket_date + INTERVAL '1 months'

```
![שאילתה 5](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%90%205.png)

## 6. מחזירה תדירות תקלות לפי נושאים על מנת להקצות את הסוכנים באופן חכם

```sql
SELECT 
  IT.issue_type_name AS topic,
  COUNT(*) AS total_tickets,
  RANK() OVER (ORDER BY COUNT(*) DESC) AS rank_by_frequency
FROM Support_Tickets ST
JOIN Issue_Types IT ON ST.issue_type_id = IT.issue_type_id
GROUP BY IT.issue_type_name

```
![שאילתה 6](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20select/%D7%A9%D7%90%D7%99%D7%9C%D7%AA%D7%94%206.png)

## 7. מחזיר את המשתמשים שפתחו הכי הרבה תקלות(לזהות לקוחות בעייתיים/בעלי צורך גבוהה בתמיכה)

```sql
SELECT 
  U.user_id,
  U.username,
  COUNT(*) AS total_tickets_opened,
  RANK() OVER (ORDER BY COUNT(*) DESC) AS user_rank
FROM Support_Tickets ST
JOIN "User" U ON ST.user_id = U.user_id
GROUP BY U.user_id, U.username
HAVING COUNT(*) > 3
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

## 1.  מחזיר את סוגי הקריאות בעלות עדיפות גבוהה ומה אחוז הקריאות שנפתרו מכל סוג

```sql
SELECT 
    IT.issue_type_name,
    IT.priority,
    COUNT(DISTINCT ST.ticket_id) AS total_tickets,
    COUNT(DISTINCT CASE WHEN TS.status = 'Resolved' THEN ST.ticket_id END) AS resolved_tickets,
    ROUND(
        COUNT(DISTINCT CASE WHEN TS.status = 'Resolved' THEN ST.ticket_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT ST.ticket_id), 0), 2
    ) AS resolution_rate_percent
FROM 
    Issue_Types IT
JOIN 
    Support_Tickets ST ON IT.issue_type_id = ST.issue_type_id
LEFT JOIN 
    Ticket_Status TS ON ST.ticket_id = TS.ticket_id
WHERE 
    IT.priority >= 3 -- נחשב עדיפות גבוהה
GROUP BY 
    IT.issue_type_name, IT.priority


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


# אילוצים
## 1. בדיקה שבכל כתובת אימייל קיים @

```sql
ALTER TABLE "User"
ADD CONSTRAINT chk_email_format
CHECK (email LIKE '%@%');
```
נראה שאכן אי אפשר להכניס כתובת אימייל ללא @
![אילוץ 1](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20%D7%90%D7%99%D7%9C%D7%95%D7%A6%D7%99%D7%9D/%D7%A6%D7%99%D7%9C%D7%95%D7%9D%20%D7%9E%D7%A1%D7%9A%202025-05-06%20155610.png)


## 2. מאלץ שלכל טיקט יהיה סטטוס ולא יהיה אפשר לשים ערך null

```sql
ALTER TABLE Ticket_Status 
ALTER COLUMN status SET NOT NULL;
```
נראה שאכן אי אפשר לשים ערך null
![אילוץ2](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20%D7%90%D7%99%D7%9C%D7%95%D7%A6%D7%99%D7%9D/%D7%A6%D7%99%D7%9C%D7%95%D7%9D%20%D7%9E%D7%A1%D7%9A%202025-05-06%20162110.png)

## 3. מאלץ שבהינתן שלא הוכנס ערך לשדה priority אז יוכנס ערך ברירית מחדל 1

```sql
ALTER TABLE issue_types
ALTER COLUMN priority SET DEFAULT 1;
```
נראה שאכן זה מכניס ערך ברירת מחדל 
![אילוץ3](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20%D7%90%D7%99%D7%9C%D7%95%D7%A6%D7%99%D7%9D/%D7%A6%D7%99%D7%9C%D7%95%D7%9D%20%D7%9E%D7%A1%D7%9A%202025-05-06%20163459.png)
![אילוץ3](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/%D7%A6%D7%99%D7%9C%D7%95%D7%9E%D7%99%20%D7%90%D7%99%D7%9C%D7%95%D7%A6%D7%99%D7%9D/%D7%A6%D7%99%D7%9C%D7%95%D7%9D%20%D7%9E%D7%A1%D7%9A%202025-05-06%20163524.png)
# commit and rollback

בדוגמה זו אנו מדגימים את השימוש בפקודות COMMIT ו־ROLLBACK כדי להבין כיצד מתבצעים שינויים זמניים בבסיס הנתונים.

ראשית, מריצים COMMIT כדי לשמור את כל השינויים שבוצעו עד כה. לאחר מכן, אנחנו מעדכנים את הערך של status עבור status_id = 2 ל־'Resolved' ובודקים שהשינוי אכן התרחש בעזרת SELECT.

לאחר מכן, מבצעים ROLLBACK שמבטל את כל השינויים שלא נשמרו אחרי ה-COMMIT. לבסוף, מריצים שוב SELECT כדי לראות שהערך חזר למצבו הקודם — כלומר, שהעדכון לא נשמר.

![עדכון 3](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/comit%20and%20rollback/commit.png)
![עדכון 3](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%91/comit%20and%20rollback/rollback.png)

