
ALTER TABLE "User"
ADD COLUMN subscription_end_date DATE;

UPDATE "User"
SET subscription_end_date = CURRENT_DATE + INTERVAL '12 month'; 

CREATE TABLE IF NOT EXISTS alerts (
    alert_id SERIAL PRIMARY KEY,
    user_id INTEGER,
    ticket_id INTEGER,
    alert_message TEXT,
    alert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);