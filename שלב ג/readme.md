# שלב ג' - אינגטרציה 

## תמונות

## כספים erd
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/erdnew.jpg)

## כספים dsd
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/dsdnew.jpg)

## משותף erd
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/erd.png.jpg)

## משותף dsd
![צילום מסך](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/dsd.jpg)

#  אינטגרציית טבלאות: מיזוג subscriptions עם User

במסגרת שלב האינטגרציה בפרויקט, בחרנו לאחד את טבלת subscriptions לתוך טבלת User. להלן תיאור השינויים שבוצעו ומטרתם:

---

##  הוספת שדות לטבלת User

```sql
ALTER TABLE "User"
ADD COLUMN customer_name TEXT,
ADD COLUMN plan_id INTEGER,
ADD COLUMN discount_id INTEGER;
```


 *מטרה:* הוספת שדות מתוך טבלת subscriptions לתוך User, כהכנה למחיקת הטבלה המקורית.

---


##  העתקת נתונים מטבלת subscriptions ל־User

```sql
UPDATE "User" U
SET plan_id = S.plan_id,
    discount_id = S.discount_id,
    customer_name = S.customer_name
FROM subscriptions S
WHERE U.user_id = S.subscription_id;
```


 *מטרה:* העברת הנתונים הרלוונטיים מהטבלה subscriptions אל הטבלה User.

---

##  שינוי שם עמודה בטבלת Payments

```sql
ALTER TABLE Payments
RENAME COLUMN subscription_id TO user_id;
```

 *מטרה:* עדכון שם העמודה כך שתשקף את הקשר החדש בין Payments ל־User.

---

##  הסרת קשר ישן בין Payments ל־subscriptions

```sql
ALTER TABLE Payments
DROP CONSTRAINT IF EXISTS payments_subscription_id_fkey;
```

 *מטרה:* מחיקת קשר חוץ שכבר אינו רלוונטי לאחר האינטגרציה.

---

##  יצירת קשר חדש בין Payments ל־User

```sql
ALTER TABLE Payments
ADD CONSTRAINT fk_payments_user
FOREIGN KEY (user_id)
REFERENCES Users(user_id);
```

 *מטרה:* הגדרת קשר חוץ חדש בהתאם למבנה החדש, בו Payments מתייחס ישירות ל־User.

---

##  מחיקת טבלת subscriptions

```sql
DROP TABLE IF EXISTS subscriptions CASCADE;
```

 *מטרה:* מחיקת הטבלה שכבר הועתקה לתוך User ואין בה צורך יותר.

---

##  יצירת קשר בין User ל־subscription_plans

```sql
ALTER TABLE "User"
ADD CONSTRAINT fk_users_plan
FOREIGN KEY (plan_id)
REFERENCES subscription_plans(plan_id);
```

 *מטרה:* שמירה על הקשר בין משתמשים לתוכניות המנויים שלהם גם לאחר המעבר לטבלה המאוחדת.

---

##  יצירת קשר בין User ל־discounts

```sql
ALTER TABLE "User"
ADD CONSTRAINT fk_users_discount
FOREIGN KEY (discount_id)
REFERENCES discounts(discount_id);
```

 *מטרה:* שמירה על הקשר בין משתמשים להנחות שהוגדרו להם.

---



# מבטים

## View 1: Full_Customer_Info_View1

מבט מנקודת המבט של שירות הלקוחות  
מטרת ה־View הזה היא לרכז את כל המידע הרלוונטי עבור נציגי שירות הלקוחות:

- פרטי הלקוח (שם משתמש, דוא"ל, תוכנית מנויים, הנחה)  
- פרטי התשלום האחרון שביצע  
- התקלה האחרונה שדווחה  
- סטטוס התקלה האחרון ורמת הסיכון שלה  

באמצעות מידע זה, נציג השירות יכול להבין את הרקע הכללי של הלקוח, לראות האם יש בעיות פעילות או לא פתורות, והאם יש סיכון מתמשך.


```sql
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
```

![תמונה View 1](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/view1.jpg)


## שאילתה 1: בדיקת כל המידע עבור לקוח בשם 'Ellery'

שימושי לזיהוי היסטוריה אחרונה של לקוח ספציפי, לדוגמה כאשר הוא פונה לתמיכה.

```sql
SELECT *
FROM Full_Customer_Info_View1
WHERE username = 'Ellery';
```

![שאילתה 1](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/select11.jpg)

## שאילתה 2: לקוחות עם תשלום גבוה ובעיה פתוחה עם סיכון גבוה

השאילתה מסייעת לזהות לקוחות "יקרים" עם תקלות שלא נפתרו, במיוחד כאלה שעשויות להשפיע על שביעות הרצון והנטישה.

```sql
SELECT DISTINCT username, last_payment_amount, status, status_risk
FROM Full_Customer_Info_View1
WHERE last_payment_amount > 5000
  AND status != 'Resolved'
  AND status_risk >= 5;
```

![שאילתה 2](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/select12.jpg)

# View 2: Customer_Status_Summary_View

מבט מנקודת המבט של צוות הניתוח העסקי  
המבט הזה מספק מידע מסוכם על כל לקוח:

- פרטי מנוי  
- מספר הסטטוסים (תקלות/תשובות/עדכונים) שהיו לו לאורך הזמן  

מטרת המבט היא להציג מגמות כלליות לגבי לקוחות, למשל האם לקוחות בתוכנית מסוימת חווים יותר תקלות.


```sql
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

```

![תמונה View 2](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/view2.jpg)



## שאילתה 3: לקוחות בתוכנית 'premium' עם יותר מ־6 סטטוסים

מועיל לבדוק אם לקוחות שמשלמים הרבה חווים בעיות רבות, מה שעלול להעיד על בעיה במוצר או השירות לתוכנית הזו.

```sql
SELECT *
FROM Customer_Status_Summary_View
WHERE plan_type = 'premium'
  AND total_status_count > 10;
```

![שאילתה 3](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/select21.jpg)

## שאילתה 4: סיכום סטטוסים ללקוח בשם 'Kassia'

מאפשר להבין כמה אינטראקציות היו עם הלקוח הזה ולאיזה סוג מנוי הוא שייך.

```sql
SELECT *
FROM Customer_Status_Summary_View
WHERE username = 'Kassia';
```


![שאילתה 4](https://github.com/asafBenjo/DBProject209464825_206095671/blob/main/%D7%A9%D7%9C%D7%91%20%D7%92/select22.jpg)

