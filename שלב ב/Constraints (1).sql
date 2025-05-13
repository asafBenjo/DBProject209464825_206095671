ALTER TABLE "User"
ADD CONSTRAINT chk_email_format
CHECK (email LIKE '%@%');


ALTER TABLE Ticket_Status 
ALTER COLUMN status SET NOT NULL;


ALTER TABLE issue_types
ALTER COLUMN priority SET DEFAULT 1;



