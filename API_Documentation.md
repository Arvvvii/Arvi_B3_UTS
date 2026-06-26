{
  "info": {
    "name": "Helpdesk E-Ticketing ITIL API",
    "description": "Dokumentasi REST API lengkap untuk project E-Ticketing Helpdesk.",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth: Login",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"email\": \"user@example.com\",\n  \"password\": \"yourpassword123\"\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "http://localhost:8080/api/auth/login",
          "protocol": "http",
          "host": [
            "localhost"
          ],
          "port": "8080",
          "path": [
            "api",
            "auth",
            "login"
          ]
        }
      }
    },
    {
      "name": "Tickets: Fetch All Tickets",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer <access_token>"
          },
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "url": {
          "raw": "http://localhost:8080/api/tickets",
          "protocol": "http",
          "host": [
            "localhost"
          ],
          "port": "8080",
          "path": [
            "api",
            "tickets"
          ]
        }
      }
    },
    {
      "name": "Tickets: Create Ticket",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer <access_token>"
          },
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"title\": \"Aplikasi E-Faktur Error\",\n  \"description\": \"Tidak bisa generate PDF di aplikasi e-faktur\",\n  \"status\": \"open\",\n  \"created_by\": \"uuid-user-1234\",\n  \"attachment_url\": \"https://storage.../error.png\"\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "http://localhost:8080/api/tickets",
          "protocol": "http",
          "host": [
            "localhost"
          ],
          "port": "8080",
          "path": [
            "api",
            "tickets"
          ]
        }
      }
    },
    {
      "name": "Tickets: Update Ticket Status (Assign & Progress)",
      "request": {
        "method": "PUT",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer <access_token>"
          },
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"assigned_to\": \"uuid-helpdesk-9999\",\n  \"status\": \"inProgress\"\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "http://localhost:8080/api/tickets/:id/status",
          "protocol": "http",
          "host": [
            "localhost"
          ],
          "port": "8080",
          "path": [
            "api",
            "tickets",
            ":id",
            "status"
          ],
          "variable": [
            {
              "key": "id",
              "value": "ticket-uuid-003",
              "description": "ID dari tiket"
            }
          ]
        }
      }
    },
    {
      "name": "Comments/Timeline: Add Comment",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer <access_token>"
          },
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"user_id\": \"uuid-helpdesk-9999\",\n  \"user_name\": \"Budi IT Support\",\n  \"message\": \"Sedang melakukan remote desktop untuk memperbaiki aplikasi e-faktur.\"\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        },
        "url": {
          "raw": "http://localhost:8080/api/tickets/:id/comments",
          "protocol": "http",
          "host": [
            "localhost"
          ],
          "port": "8080",
          "path": [
            "api",
            "tickets",
            ":id",
            "comments"
          ],
          "variable": [
            {
              "key": "id",
              "value": "ticket-uuid-003",
              "description": "ID dari tiket"
            }
          ]
        }
      }
    }
  ]
}
