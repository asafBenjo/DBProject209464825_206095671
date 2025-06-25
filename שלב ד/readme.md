# שלב ד

# שלב ד – תוכניות ב־PL/pgSQL ו־Triggers

## 🎯 מטרה
בשלב זה כתבנו פונקציות, פרוצדורות, טריגרים ותוכניות ראשיות לעבודה עם בסיס הנתונים.  


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

## פונקציות

### פונקציה 1: CountUnresolvedTicketsPerUser
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

### פונקציה 2: SuggestPremiumUpgrade
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

## פרוצדורות

### פרוצדורה 1: EvaluateAgentPerformance
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

### פרוצדורה 2: GiveFreeMonthForSlowResponse
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

### תוספת טור
```sql
ALTER TABLE "User"
ADD COLUMN subscription_end_date DATE;

UPDATE "User"
SET subscription_end_date = CURRENT_DATE + INTERVAL '12 month'; 
```

## טריגרים

### טריגר 1: create_high_risk_alert
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

### טריגר 2: insert_initial_ticket_status
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
