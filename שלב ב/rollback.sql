COMMIT;

UPDATE Ticket_Status
SET status = 'Resolved'
WHERE status_id = '2';

SELECT  status_id, status
FROM Ticket_Status
WHERE status_id = '2';

ROLLBACK;

SELECT status_id, status
FROM Ticket_Status
WHERE status_id = '2';


