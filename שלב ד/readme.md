
# שלב ד – תוכניות ב־PL/pgSQL ו־Triggers

##  מטרה
בשלב זה כתבנו פונקציות, פרוצדורות, טריגרים ותוכניות ראשיות לעבודה עם בסיס הנתונים.  

## פונקציות

### פונקציה 1: CountUnresolvedTicketsPerUser
#### תיאור:
פונקציה זו סורקת את כלל המשתמשים ובודקת לכל אחד מהם כמה תקלות עדיין פתוחות (שאינן 'Resolved').  
אם נמצאו מעל 4 תקלות פתוחות למשתמש מסוים, תופיע התראה באמצעות `RAISE NOTICE`.  
📌 מטרת הפונקציה: לאפשר זיהוי משתמשים שיש להם עומס תקלות חריג – דבר שעשוי להעיד על בעיות חמורות או תסכול מצטבר מצד הלקוח.

```sql
CREATE OR REPLACE FUNCTION CountUnresolvedTicketsPerUser()
RETURNS void AS $$
DECLARE
    rec RECORD;
    unresolved_count INT;
BEGIN
    FOR rec IN SELECT user_id, username FROM "User" LOOP
        SELECT COUNT(*) INTO unresolved_count
        FROM Support_Tickets t
        JOIN Ticket_Status ts ON t.ticket_id = ts.ticket_id
        WHERE t.user_id = rec.user_id
          AND ts.status != 'Resolved';

        IF unresolved_count > 4 THEN
            RAISE NOTICE 'למשתמש % יש % תקלות פתוחות', rec.user_id, unresolved_count;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql; 
```

![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%93/%D7%A4%D7%95%D7%A0%D7%A7%D7%A6%D7%99%201.jpg)


### פונקציה 2: SuggestPremiumUpgrade
#### תיאור:
הפונקציה מאתרת משתמשים עם מנוי 'basic' שנמצאים איתנו למעלה משנה, וממליצה להם לשדרג למנוי Premium תוך הצעת הטבה.  
📌 מטרת הפונקציה: שיפור שיווקי ושימור לקוחות ותיקים על־ידי עידוד שדרוג. ובנוסף קבלת רווח לחברה על ידי שדרוג תוכנית המנוי של המשתמש.

```sql
CREATE OR REPLACE FUNCTION SuggestPremiumUpgrade()
RETURNS void AS $$
DECLARE
    rec RECORD;
    first_payment_date DATE;
BEGIN
    FOR rec IN
        SELECT u.user_id, u.username, sp.plan_type
        FROM "User" u
        JOIN subscription_plans sp ON u.plan_id = sp.plan_id
        WHERE sp.plan_type = 'basic'
    LOOP
        SELECT MIN(payment_date)
        INTO first_payment_date
        FROM Payments
        WHERE user_id = rec.user_id;

        IF first_payment_date IS NOT NULL AND first_payment_date <= CURRENT_DATE - INTERVAL '1 year' THEN
            RAISE NOTICE 'Hi %, thanks for being with us for over a year! Unlock more features and save 20%% when you upgrade to Premium now.', rec.username;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%93/%D7%A4%D7%95%D7%A0%D7%A7%D7%A6%D7%99%D7%94%202.jpg)

## פרוצדורות

### פרוצדורה 1: EvaluateAgentPerformance
#### תיאור:
הפרוצדורה מחשבת את מספר התקלות שכל סוכן פתר ביחס לשעות העבודה שלו ומייצרת מדד פרודוקטיביות.  
אם סוכן עם פרודוקטיביות נמוכה מזוהה, מודפסת התרעה מתאימה.  
📌 חשיבות: ניטור ביצועים של סוכנים באופן רציף לצורך שיפור איכות השירות וקבלת החלטות ניהוליות.

```sql
CREATE OR REPLACE PROCEDURE EvaluateAgentPerformance()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    tickets_resolved INT;
    productivity NUMERIC;
BEGIN
    FOR rec IN SELECT support_agent_id, agent_name, work_hours FROM Support_Agent LOOP
        BEGIN
            SELECT COUNT(DISTINCT sr.ticket_id)
            INTO tickets_resolved
            FROM Support_Responses sr
            JOIN Ticket_Status ts ON sr.ticket_id = ts.ticket_id
            WHERE sr.support_agent_id = rec.support_agent_id
              AND ts.status = 'Resolved';

            IF rec.work_hours > 0 THEN
                productivity := tickets_resolved::NUMERIC / rec.work_hours;
            ELSE
                productivity := 0;
            END IF;

            IF productivity < 0.5 THEN
                RAISE NOTICE '⚠ Agent % resolved only % problems over % working hours (productivity: %)',
                    rec.agent_name, tickets_resolved, rec.work_hours, ROUND(productivity, 2);
            END IF;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'שגיאה בעת ניתוח הסוכן % – בדוק את הנתונים שלו.', rec.agent_name;
        END;
    END LOOP;
END;
$$; 
```
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%93/%D7%A4%D7%A8%D7%95%D7%A6%D7%93%D7%95%D7%A8%D7%94%201.jpg)

### פרוצדורה 2: GiveFreeMonthForSlowResponse
#### תיאור:
הפרוצדורה מעניקה חודש חינם למשתמשים עבור תקלות שקיבלו תגובה ראשונית רק לאחר יותר מ־100 ימים.  
📌 מטרת הפעולה: שמירה על שביעות רצון הלקוח ופיצוי אוטומטי למצבים חריגים של שירות איטי.

```sql
CREATE OR REPLACE PROCEDURE GiveFreeMonthForSlowResponse()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT t.user_id, t.ticket_id, t.ticket_date, MIN(r.response_date) AS first_response
        FROM Support_Tickets t
        JOIN Support_Responses r ON t.ticket_id = r.ticket_id
        GROUP BY t.user_id, t.ticket_id, t.ticket_date
        HAVING MIN(r.response_date) > t.ticket_date + INTERVAL '100 days'
    LOOP
        BEGIN
            UPDATE "User"
            SET subscription_end_date = subscription_end_date + INTERVAL '1 month'
            WHERE user_id = rec.user_id;

            RAISE NOTICE '🎁 המשתמש % קיבל חודש חינם על תגובה איטית לתקלה %', rec.user_id, rec.ticket_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠ שגיאה בהענקת פיצוי למשתמש %', rec.user_id;
        END;
    END LOOP;
END;
$$;
```
### הוספת עמודה 
#### בשביל לייצר את הפרוצדורה הזאת היינו צריכים להוסיף עמודה למשתמש - שתציג מתי מסתיים המנוי שלו, ולאחר מכן אפשר היה להוסיף לו עוד חודש חינם


```sql
ALTER TABLE "User"
ADD COLUMN subscription_end_date DATE;

UPDATE "User"
SET subscription_end_date = CURRENT_DATE + INTERVAL '12 month'; 
```

![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%93/%D7%A4%D7%A8%D7%9F%D7%A6%D7%93%D7%95%D7%A8%D7%94%202.jpg)

## טריגרים

### טריגר 1: 
#### תיאור:
טריגר זה מופעל כאשר מוכנסת או מתעדכנת תקלה עם רמת סיכון גבוהה (מעל 7).  
הוא מייצר באופן אוטומטי רשומה בטבלת `alerts` עם פרטי ההתראה.  
📌 מטרת הטריגר: לאפשר התראה מיידית על תקלות חמורות הדורשות טיפול מיידי.
##### הפונקציה של הטריגר - create_high_risk_alert

```sql
CREATE FUNCTION create_high_risk_alert() RETURNS trigger AS $$
BEGIN
  IF NEW.status_risk > 7 THEN
    INSERT INTO alerts(user_id, ticket_id, alert_message)
    VALUES (
      (SELECT user_id FROM Support_Tickets WHERE ticket_id = NEW.ticket_id),
      NEW.ticket_id,
      'דווחה תקלה ברמת סיכון גבוהה (יותר מ־7)'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### יצירת טבלת alerts 
#### בשביל לעשות את הטריגר הזה היינו צריכים להוסיף טבלה שתכיל את ההתראות

```sql
CREATE TABLE IF NOT EXISTS alerts (
    alert_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    ticket_id INTEGER,
    alert_message TEXT,
    alert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### יצירת טריגר:
```sql
CREATE TRIGGER high_risk_ticket_alert
AFTER INSERT OR UPDATE ON Ticket_Status
FOR EACH ROW
EXECUTE FUNCTION create_high_risk_alert();
```

### בדיקה:
```sql
INSERT INTO Ticket_Status (status_id, status_risk, status, modified_date, ticket_id)
VALUES (66666, 9, 'Escalated', '2023-11-12', 345);
```
### תמונה שמראה את הצלחת הבדיקה:
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%93/%D7%98%D7%A8%D7%99%D7%92%D7%A8%201.jpg)


### טריגר 2: 
#### תיאור:
טריגר זה מופעל אוטומטית בעת יצירת קריאת שירות חדשה (`Support_Tickets`) ויוצר לה סטטוס פתיחה ברירת מחדל (`Opened`).  
📌 חשיבות: מבטיח עקביות בין טבלאות ומונע מצב שבו נפתחת תקלה ללא סטטוס ראשוני.
#### פונקצית הטריגר - insert_initial_ticket_status

```sql
CREATE OR REPLACE FUNCTION insert_initial_ticket_status()
RETURNS trigger AS $$

BEGIN
    INSERT INTO Ticket_Status (ticket_id, status,status_risk, modified_date)
    VALUES (NEW.ticket_id, 'Opened', 1, CURRENT_DATE);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### יצירת טריגר:
```sql
CREATE TRIGGER trg_insert_initial_ticket_status
AFTER INSERT ON Support_Tickets
FOR EACH ROW
EXECUTE FUNCTION insert_initial_ticket_status();
```

### בדיקה:
```sql
INSERT INTO Support_Tickets (ticket_id, user_id, ticket_date, issue_type_id, issue_description)
VALUES (5500,123, CURRENT_DATE, 2, 'בעיית התחברות');
```

#### תמונה להמחשה: 
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%93/%D7%98%D7%A8%D7%99%D7%92%D7%A8%202.jpg)


## תוכניות ראשיות

### תוכנית ראשית 1
```sql
DO $$
BEGIN
    PERFORM CountUnresolvedTicketsPerUser();
    CALL EvaluateAgentPerformance(); 
END;
$$ LANGUAGE plpgsql;
```

### תוכנית ראשית 2
```sql
DO $$
BEGIN
    PERFORM SuggestPremiumUpgrade();
    CALL GiveFreeMonthForSlowResponse();
END;
$$ LANGUAGE plpgsql;
```
