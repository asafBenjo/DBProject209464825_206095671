import random
import datetime

# Function to generate random date
def generate_random_date():
    start_date = datetime.date(2020, 1, 1)
    end_date = datetime.date(2025, 12, 31)
    delta = end_date - start_date
    random_days = random.randint(0, delta.days)
    random_date = start_date + datetime.timedelta(days=random_days)
    return random_date

# Generate INSERT statements for Support_Tickets, Support_Responses, and Ticket_Status tables
def generate_insert_statements():
    insert_statements = []

    # Support_Tickets INSERTs
    for ticket_id in range(1, 1001):
        user_id = random.randint(1, 1000)
        issue_type_id = random.randint(1, 10)
        ticket_date = generate_random_date()
        ticket_date_str = ticket_date.strftime('%Y-%m-%d')
        insert_statements.append(f"INSERT INTO Support_Tickets (ticket_id, user_id, issue_description, issue_type_id, ticket_date) "
                                 f"VALUES ({ticket_id}, {user_id}, 'Issue description for ticket {ticket_id}', {issue_type_id}, '{ticket_date_str}');")

    # Support_Responses INSERTs
    for response_id in range(1, 1001):
        support_agent_id = random.randint(1, 1000)
        response_date = generate_random_date()
        response_date_str = response_date.strftime('%Y-%m-%d')
        ticket_id = random.randint(1, 1000)
        insert_statements.append(f"INSERT INTO Support_Responses (response_id, support_agent_id, response_description, response_date, ticket_id) "
                                 f"VALUES ({response_id}, {support_agent_id}, 'Response for ticket {ticket_id}', '{response_date_str}', {ticket_id});")

    # Ticket_Status INSERTs
    statuses = ["Waiting for Agent", "In Progress", "Resolved"]
    for status_id in range(1, 1001):
        status_risk = random.randint(1, 7)
        ticket_id = random.randint(1, 1000)
        status = random.choice(statuses)
        modified_date = generate_random_date()
        modified_date_str = modified_date.strftime('%Y-%m-%d')
        insert_statements.append(f"INSERT INTO Ticket_Status (status_id, status_risk, status, ticket_id, modified_date) "
                                 f"VALUES ({status_id}, {status_risk}, '{status}', {ticket_id}, '{modified_date_str}');")

    # Write to file
    with open('insertTicketResponseStatus.sql', 'w') as file:
        for statement in insert_statements:
            file.write(statement + '\n')

# Run the function to generate the SQL statements
generate_insert_statements()
