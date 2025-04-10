-- הכנסת נתונים לטבלת המשתמשים
INSERT INTO "Users" (user_id, username, email) VALUES (1, 'roni92', 'roni92@example.com');
INSERT INTO "Users" (user_id, username, email) VALUES (2, 'lior_k', 'lior.k@example.com');
INSERT INTO "Users" (user_id, username, email) VALUES (3, 'maya_m', 'maya.m@example.com');

-- הכנסת נתונים לטבלת סוכני התמיכה
INSERT INTO Support_Agent (support_agent_id, agent_name, role) VALUES (1, 'Tomer Levi', 'Tier 1');
INSERT INTO Support_Agent (support_agent_id, agent_name, role) VALUES (2, 'Dana Cohen', 'Tier 2');
INSERT INTO Support_Agent (support_agent_id, agent_name, role) VALUES (3, 'Avi Segal', 'Manager');

-- הכנסת נתונים לטבלת סוגי הבעיות
INSERT INTO Issue_Types (issue_type_id, issue_type_name, priority) VALUES (1, 'Login Issue', 2);
INSERT INTO Issue_Types (issue_type_id, issue_type_name, priority) VALUES (2, 'Streaming Error', 1);
INSERT INTO Issue_Types (issue_type_id, issue_type_name, priority) VALUES (3, 'Billing Problem', 3);

-- הכנסת נתונים לטבלת קריאות השירות
INSERT INTO Support_Tickets (ticket_id, user_id, issue_description, issue_type_id, ticket_date) 
VALUES (1, 1, 'Cannot login to my account', 1, '2025-04-07');
INSERT INTO Support_Tickets (ticket_id, user_id, issue_description, issue_type_id, ticket_date) 
VALUES (2, 2, 'Video not streaming properly', 2, '2025-04-06');
INSERT INTO Support_Tickets (ticket_id, user_id, issue_description, issue_type_id, ticket_date) 
VALUES (3, 3, 'Charged incorrectly on my account', 3, '2025-04-05');

-- הכנסת נתונים לטבלת תגובות לתמיכה
INSERT INTO Support_Responses (response_id, support_agent_id, response_description, response_date, ticket_id) 
VALUES (1, 1, 'We are investigating the issue. Please try again later.', '2025-04-07', 1);
INSERT INTO Support_Responses (response_id, support_agent_id, response_description, response_date, ticket_id) 
VALUES (2, 2, 'This is a known issue, we are working on a fix.', '2025-04-06', 2);
INSERT INTO Support_Responses (response_id, support_agent_id, response_description, response_date, ticket_id) 
VALUES (3, 3, 'We have resolved your billing issue, please verify your account.', '2025-04-05', 3);

-- הכנסת נתונים לטבלת סטטוסים של קריאות שירות
INSERT INTO Ticket_Status (status_id, status_risk, status, ticket_id) 
VALUES (1, 2, 'Open', 1);
INSERT INTO Ticket_Status (status_id, status_risk, status, ticket_id) 
VALUES (2, 1, 'Closed', 2);
INSERT INTO Ticket_Status (status_id, status_risk, status, ticket_id) 
VALUES (3, 3, 'Resolved', 3);
