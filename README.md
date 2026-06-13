# Jumandi — Gas Delivery Backend

Python backend for **Jumandi**, a gas cylinder delivery app with two sides:

- **Customer** — book gas (select kg), provide address/location, track delivery on a map
- **Delivery agent** — receive booking notifications, accept/decline orders, share live GPS location

Built with **FastAPI**, **SQLAlchemy**, and **WebSockets**.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs: http://localhost:8000/docs

## User Roles

| Role       | Value        | Description              |
|------------|--------------|--------------------------|
| Customer   | `customer`   | Books gas deliveries     |
| Delivery   | `delivery`   | Fulfills deliveries      |

## API Overview

### Authentication

| Method | Endpoint              | Description                    |
|--------|-----------------------|--------------------------------|
| POST   | `/api/auth/register`  | Register customer or delivery  |
| POST   | `/api/auth/login`     | Login (returns JWT token)      |
| GET    | `/api/auth/me`        | Get current user profile       |

**Register example:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "secret123",
  "role": "customer"
}
```

**Login:** Use form data with `username` (email) and `password` at `/api/auth/login`.

All protected routes require header: `Authorization: Bearer <token>`

### Customer — Bookings

| Method | Endpoint                        | Description              |
|--------|---------------------------------|--------------------------|
| POST   | `/api/bookings`                 | Create a gas booking     |
| GET    | `/api/bookings/my`              | List my bookings         |
| GET    | `/api/bookings/{id}`            | Get booking details      |
| POST   | `/api/bookings/{id}/cancel`     | Cancel a booking         |

**Create booking example:**
```json
{
  "gas_kg": 12.5,
  "address": "123 Main Street, Lagos",
  "latitude": 6.5244,
  "longitude": 3.3792,
  "notes": "Call when you arrive"
}
```

### Delivery Agent

| Method | Endpoint                              | Description                    |
|--------|---------------------------------------|--------------------------------|
| GET    | `/api/delivery/pending`               | View pending bookings          |
| GET    | `/api/delivery/my`                    | View my assigned deliveries    |
| POST   | `/api/delivery/{id}/accept`           | Accept a booking               |
| POST   | `/api/delivery/{id}/decline`          | Decline (stays for others)   |
| POST   | `/api/delivery/{id}/start`            | Start delivery (enables tracking)|
| POST   | `/api/delivery/{id}/complete`         | Mark as delivered              |
| POST   | `/api/delivery/location`              | Send GPS location              |
| PATCH  | `/api/delivery/availability`          | Toggle online/offline          |

**Update location example:**
```json
{
  "latitude": 6.5300,
  "longitude": 3.3850
}
```

### Calls (Customer ↔ Delivery)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/calls/booking/{id}/contact` | Get the other party's phone number for an active booking |
| POST | `/api/calls/booking/{id}/initiate` | Log a call and notify the other party (returns `tel:` URI for the dialer) |
| GET | `/api/calls/booking/{id}` | List call history for a booking |
| PATCH | `/api/calls/{call_id}/status` | Mark call as `completed` or `missed` |

**Who can call:**
- **Customer** — after a delivery agent is assigned (accepted / in transit)
- **Delivery agent** — on pending orders or their assigned bookings

**WebSocket event:** `incoming_call` — sent to the receiver when someone initiates a call.

### WebSockets (Real-time)

| Endpoint                              | Who connects  | Purpose                          |
|---------------------------------------|---------------|----------------------------------|
| `ws://host/ws/notifications?token=JWT` | Both          | Booking notifications            |
| `ws://host/ws/tracking/{id}?token=JWT` | Customer      | Live map tracking during delivery |

**Notification events:**
- `new_booking` — delivery agents receive new orders
- `booking_accepted` — customer notified when agent accepts
- `delivery_started` — customer can open map tracking
- `location_update` — live GPS position on map
- `delivery_completed` — order finished
- `incoming_call` — someone is calling about a booking

## Booking Flow

```
Customer books gas
       ↓
Delivery agents get notification (WebSocket)
       ↓
Agent accepts → Customer notified
       ↓
Agent starts delivery → Customer opens map tracking
       ↓
Agent sends GPS updates → Customer sees movement on map
       ↓
Agent completes delivery → Customer notified
```

## Booking Statuses

`pending` → `accepted` → `in_transit` → `delivered`

Also: `declined`, `cancelled`

## Configuration

Settings are loaded from `.env` in the project root:

```env
APP_NAME=Jumandi
SECRET_KEY=change-this-secret-key-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080
DATABASE_URL=sqlite:///./jumandi.db
```

Change `SECRET_KEY` before deploying to production.

## Deploy to Render

### Option A — Blueprint (recommended)

1. Push this project to **GitHub**
2. Go to [render.com](https://render.com) → **New** → **Blueprint**
3. Connect your GitHub repo — Render reads `render.yaml` and creates:
   - **jumandi-api** — web service
   - **jumandi-db** — PostgreSQL database
4. Click **Apply** and wait for the deploy to finish

Your API will be live at: `https://jumandi-api.onrender.com`  
Docs: `https://jumandi-api.onrender.com/docs`

### Option B — Manual setup

1. **New → PostgreSQL** — create database, copy the **Internal Database URL**
2. **New → Web Service** — connect GitHub repo
3. Settings:
   - **Build command:** `pip install -r requirements.txt`
   - **Start command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
4. **Environment variables:**

| Key | Value |
|-----|-------|
| `SECRET_KEY` | random long string |
| `DATABASE_URL` | PostgreSQL URL from step 1 |
| `APP_NAME` | Jumandi |

### After deploy

Use your Render URL in the mobile app:

```
https://jumandi-api.onrender.com/api/auth/login
wss://jumandi-api.onrender.com/ws/notifications?token=JWT
wss://jumandi-api.onrender.com/ws/tracking/1?token=JWT
```

> **Note:** Free tier services sleep after inactivity (~50s cold start). WebSockets work on Render web services.

## Project Structure

```
app/
├── main.py              # FastAPI app entry point
├── config.py            # Settings
├── database.py          # SQLAlchemy setup
├── models/              # User & Booking models
├── schemas/             # Request/response schemas
├── routers/             # API routes
│   ├── auth.py
│   ├── bookings.py
│   ├── delivery.py
│   └── websocket.py
├── services/
│   └── websocket_manager.py
└── utils/
    └── auth.py          # JWT & password helpers
```
