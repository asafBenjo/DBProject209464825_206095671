-- מחיקת טבלת תגובות לתמיכה
DROP TABLE IF EXISTS Support_Responses CASCADE;

-- מחיקת טבלת סטטוסים של קריאות שירות
DROP TABLE IF EXISTS Ticket_Status CASCADE;

-- מחיקת טבלת קריאות שירות
DROP TABLE IF EXISTS Support_Tickets CASCADE;

-- מחיקת טבלת סוגי בעיות
DROP TABLE IF EXISTS Issue_Types CASCADE;

-- מחיקת טבלת סוכני תמיכה
DROP TABLE IF EXISTS Support_Agent CASCADE;

-- מחיקת טבלת משתמשים
DROP TABLE IF EXISTS "Users" CASCADE;
