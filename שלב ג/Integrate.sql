הוספת שדות ל user שנמצאים ב subscription

ALTER TABLE "User"
ADD COLUMN customer_name TEXT,
ADD COLUMN plan_id INTEGER,
ADD COLUMN discount_id INTEGER

ALTER TABLE "User"
ALTER COLUMN customer_name TYPE varchar(40);

הוספת נתונים לשדות שהוספנו ל user:
UPDATE "User" U
SET plan_id = S.plan_id,
    discount_id = S.discount_id,
	customer_name = S.customer_name
FROM subscriptions S
WHERE U.user_id = S.subscription_id;



ALTER TABLE Payments
RENAME COLUMN subscription_id TO user_id;


ALTER TABLE Payments
DROP CONSTRAINT IF EXISTS payments_subscription_id_fkey;

ALTER TABLE Payments
ADD CONSTRAINT fk_payments_user
FOREIGN KEY (user_id)
REFERENCES Users(user_id);

DROP TABLE IF EXISTS subscriptions CASCADE;

ALTER TABLE "User"
ADD CONSTRAINT fk_users_plan
FOREIGN KEY (plan_id)
REFERENCES subscription_plans(plan_id);

ALTER TABLE "User"
ADD CONSTRAINT fk_users_discount
FOREIGN KEY (discount_id)
REFERENCES discounts(discount_id);
