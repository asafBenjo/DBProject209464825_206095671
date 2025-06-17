כספים erd
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/erdnew.jpg)

כספים dsd
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/dsdnew.jpg)

משותף erd
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/erd.png.jpg)

משותף dsd
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/dsd.jpg)

# 🔄 אינטגרציית טבלאות: מיזוג subscriptions עם User

במסגרת שלב האינטגרציה בפרויקט, בחרנו לאחד את טבלת subscriptions לתוך טבלת User. להלן תיאור השינויים שבוצעו ומטרתם:

---

## ✅ הוספת שדות לטבלת User

sql
ALTER TABLE "User"
ADD COLUMN customer_name TEXT,
ADD COLUMN plan_id INTEGER,
ADD COLUMN discount_id INTEGER;


📌 *מטרה:* הוספת שדות מתוך טבלת subscriptions לתוך User, כהכנה למחיקת הטבלה המקורית.

---

## ✏ שינוי סוג עמודת customer_name

sql
ALTER TABLE "User"
ALTER COLUMN customer_name TYPE varchar(40);


📌 *מטרה:* הגבלת אורך השדה ל־40 תווים, לשמירה על תקינות ואחידות הנתונים.

---

## 📥 העתקת נתונים מטבלת subscriptions ל־User

sql
UPDATE "User" U
SET plan_id = S.plan_id,
    discount_id = S.discount_id,
    customer_name = S.customer_name
FROM subscriptions S
WHERE U.user_id = S.subscription_id;


📌 *מטרה:* העברת הנתונים הרלוונטיים מהטבלה subscriptions אל הטבלה User.

---

## 🔄 שינוי שם עמודה בטבלת Payments

sql
ALTER TABLE Payments
RENAME COLUMN subscription_id TO user_id;


📌 *מטרה:* עדכון שם העמודה כך שתשקף את הקשר החדש בין Payments ל־User.

---

## 🗑 הסרת קשר ישן בין Payments ל־subscriptions

sql
ALTER TABLE Payments
DROP CONSTRAINT IF EXISTS payments_subscription_id_fkey;


📌 *מטרה:* מחיקת קשר חוץ שכבר אינו רלוונטי לאחר האינטגרציה.

---

## 🔗 יצירת קשר חדש בין Payments ל־User

sql
ALTER TABLE Payments
ADD CONSTRAINT fk_payments_user
FOREIGN KEY (user_id)
REFERENCES Users(user_id);


📌 *מטרה:* הגדרת קשר חוץ חדש בהתאם למבנה החדש, בו Payments מתייחס ישירות ל־User.

---

## 🗑 מחיקת טבלת subscriptions

sql
DROP TABLE IF EXISTS subscriptions CASCADE;


📌 *מטרה:* מחיקת הטבלה שכבר הועתקה לתוך User ואין בה צורך יותר.

---

## 🔗 יצירת קשר בין User ל־subscription_plans

sql
ALTER TABLE "User"
ADD CONSTRAINT fk_users_plan
FOREIGN KEY (plan_id)
REFERENCES subscription_plans(plan_id);


📌 *מטרה:* שמירה על הקשר בין משתמשים לתוכניות המנויים שלהם גם לאחר המעבר לטבלה המאוחדת.

---

## 🔗 יצירת קשר בין User ל־discounts

sql
ALTER TABLE "User"
ADD CONSTRAINT fk_users_discount
FOREIGN KEY (discount_id)
REFERENCES discounts(discount_id);


📌 *מטרה:* שמירה על הקשר בין משתמשים להנחות שהוגדרו להם.





##מבטים
מבט 1

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
  AND status_risk >= 5;בב
