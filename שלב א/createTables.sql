-- יצירת טבלת המשתמשים עם מפתח רץ (Auto Increment)
CREATE TABLE "Users" (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL
);

-- יצירת טבלת סוכני התמיכה עם מפתח רץ (Auto Increment)
CREATE TABLE Support_Agent (
  support_agent_id SERIAL PRIMARY KEY,
  agent_name VARCHAR(255) NOT NULL,
  role VARCHAR(255) NOT NULL
);

-- יצירת טבלת סוגי הבעיות עם מפתח רץ (Auto Increment)
CREATE TABLE Issue_Types (
  issue_type_id SERIAL PRIMARY KEY,
  issue_type_name VARCHAR(255) NOT NULL,
  priority INT NOT NULL
);

-- יצירת טבלת קריאות שירות עם מפתח רץ (Auto Increment)
CREATE TABLE Support_Tickets (
  ticket_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  issue_description TEXT NOT NULL,
  issue_type_id INT NOT NULL,
  ticket_date DATE NOT NULL,
  FOREIGN KEY (user_id) REFERENCES "Users" (user_id),
  FOREIGN KEY (issue_type_id) REFERENCES Issue_Types (issue_type_id)
);

-- יצירת טבלת תגובות לתמיכה עם מפתח רץ (Auto Increment)
CREATE TABLE Support_Responses (
  response_id SERIAL PRIMARY KEY,
  support_agent_id INT NOT NULL,
  response_description TEXT NOT NULL,
  response_date DATE NOT NULL,
  ticket_id INT NOT NULL,
  FOREIGN KEY (ticket_id) REFERENCES Support_Tickets (ticket_id),
  FOREIGN KEY (support_agent_id) REFERENCES Support_Agent (support_agent_id)
);

-- יצירת טבלת סטטוסים של קריאות שירות עם מפתח רץ (Auto Increment)
CREATE TABLE Ticket_Status (
  status_id SERIAL PRIMARY KEY,
  status_risk INT NOT NULL,
  status VARCHAR(255) NOT NULL,
  ticket_id INT NOT NULL,
  FOREIGN KEY (ticket_id) REFERENCES Support_Tickets (ticket_id)
);
