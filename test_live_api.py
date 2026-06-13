"""Full live API test for https://jumandi.onrender.com"""
import asyncio
import json
import urllib.error
import urllib.parse
import urllib.request
import uuid

BASE = "https://jumandi.onrender.com"
passed: list[tuple[str, int, str]] = []
failed: list[tuple[str, int, str]] = []
skipped: list[tuple[str, str]] = []


def record(name: str, ok: bool, code: int, detail: str = "") -> None:
    (passed if ok else failed).append((name, code, str(detail)))


def req(method, path, data=None, token=None, form=None, query=None):
    url = BASE + path
    if query:
        url += "?" + urllib.parse.urlencode(query)
    headers: dict[str, str] = {}
    body = None
    if form is not None:
        body = urllib.parse.urlencode(form).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    elif data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=90) as resp:
            raw = resp.read().decode()
            try:
                payload = json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                payload = raw
            return resp.status, payload
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            payload = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            payload = raw
        return e.code, payload


def main() -> None:
    uid = uuid.uuid4().hex[:8]
    customer_email = f"cust_{uid}@jumandi.com"
    delivery_email = f"drv_{uid}@jumandi.com"
    password = "secret123"

    print(f"Testing all APIs at {BASE}")
    print("=" * 60)

    code, data = req("GET", "/")
    record("GET /", code == 200, code, str(data.get("app", data)))

    code, data = req(
        "POST",
        "/api/auth/register",
        {
            "name": "API Test Customer",
            "email": customer_email,
            "phone": "+1111111111",
            "password": password,
            "role": "customer",
        },
    )
    record("POST /api/auth/register (customer)", code == 201, code, data.get("user", {}).get("email", data))
    ctoken = data.get("access_token") if isinstance(data, dict) else None

    code, data = req(
        "POST",
        "/api/auth/register",
        {
            "name": "API Test Driver",
            "email": delivery_email,
            "phone": "+1222222222",
            "password": password,
            "role": "delivery",
        },
    )
    record("POST /api/auth/register (delivery)", code == 201, code, data.get("user", {}).get("email", data))
    dtoken = data.get("access_token") if isinstance(data, dict) else None

    code, data = req(
        "POST",
        "/api/auth/login",
        form={"username": customer_email, "password": password},
    )
    record("POST /api/auth/login", code == 200, code, data.get("user", {}).get("email", data))

    code, data = req("GET", "/api/auth/me", token=ctoken)
    record("GET /api/auth/me", code == 200, code, data.get("name", data))

    code, data = req(
        "PATCH",
        "/api/auth/me",
        {"name": "Updated Customer", "phone": "+1333333333"},
        token=ctoken,
    )
    record("PATCH /api/auth/me", code == 200, code, data.get("name", data))

    code, data = req("POST", "/api/auth/otp/send", token=ctoken)
    otp_code = data.get("code") if isinstance(data, dict) else None
    record("POST /api/auth/otp/send", code == 200, code, f"code={otp_code}" if otp_code else data)

    if otp_code:
        code, data = req("POST", "/api/auth/otp/verify", {"code": otp_code}, token=ctoken)
        detail = data.get("is_verified", data) if isinstance(data, dict) else data
        record("POST /api/auth/otp/verify", code == 200, code, detail)
    else:
        skipped.append(("POST /api/auth/otp/verify", "no otp code returned"))

    reset_email = f"reset_{uid}@jumandi.com"
    req(
        "POST",
        "/api/auth/register",
        {
            "name": "Reset User",
            "email": reset_email,
            "phone": "+1444444444",
            "password": password,
            "role": "customer",
        },
    )
    code, data = req("POST", "/api/auth/forgot-password", {"email": reset_email})
    reset_token = data.get("reset_token") if isinstance(data, dict) else None
    record("POST /api/auth/forgot-password", code == 200, code, "token received" if reset_token else data)

    if reset_token:
        code, data = req(
            "POST",
            "/api/auth/reset-password",
            {"email": reset_email, "token": reset_token, "new_password": "newsecret123"},
        )
        record("POST /api/auth/reset-password", code == 200, code, data)
    else:
        skipped.append(("POST /api/auth/reset-password", "no reset token"))

    code, data = req(
        "POST",
        "/api/bookings",
        {
            "gas_kg": 12.5,
            "address": "123 API Test Street",
            "latitude": 6.5244,
            "longitude": 3.3792,
            "notes": "full api test",
        },
        token=ctoken,
    )
    booking_id = data.get("id") if isinstance(data, dict) else None
    record("POST /api/bookings", code == 201, code, f"booking_id={booking_id}")

    code, data = req("GET", "/api/bookings/my", token=ctoken)
    record("GET /api/bookings/my", code == 200, code, f"{len(data)} bookings")

    if booking_id:
        code, data = req("GET", f"/api/bookings/{booking_id}", token=ctoken)
        record("GET /api/bookings/{id}", code == 200, code, data.get("status", data))

    code, data = req("GET", "/api/delivery/pending", token=dtoken)
    record("GET /api/delivery/pending", code == 200, code, f"{len(data)} pending")

    code, data = req(
        "POST",
        "/api/bookings",
        {
            "gas_kg": 6.0,
            "address": "456 Decline Test Ave",
            "latitude": 6.53,
            "longitude": 3.38,
        },
        token=ctoken,
    )
    booking2_id = data.get("id") if isinstance(data, dict) else None
    if booking2_id:
        code, data = req("POST", f"/api/delivery/{booking2_id}/decline", token=dtoken)
        record("POST /api/delivery/{id}/decline", code == 200, code, data.get("status", data))

    if booking_id:
        code, data = req("POST", f"/api/delivery/{booking_id}/accept", token=dtoken)
        record("POST /api/delivery/{id}/accept", code == 200, code, data.get("status", data))

    code, data = req("GET", "/api/delivery/my", token=dtoken)
    record("GET /api/delivery/my", code == 200, code, f"{len(data)} deliveries")

    code, data = req(
        "POST",
        "/api/delivery/location",
        {"latitude": 6.5250, "longitude": 3.3800},
        token=dtoken,
    )
    record("POST /api/delivery/location", code == 200, code, data)

    code, data = req("PATCH", "/api/delivery/availability", token=dtoken, query={"is_available": "false"})
    record("PATCH /api/delivery/availability", code == 200, code, data)
    req("PATCH", "/api/delivery/availability", token=dtoken, query={"is_available": "true"})

    if booking_id:
        code, data = req("POST", f"/api/delivery/{booking_id}/start", token=dtoken)
        record("POST /api/delivery/{id}/start", code == 200, code, data.get("status", data))

    if booking_id:
        code, data = req("GET", f"/api/chat/{booking_id}/messages", token=ctoken)
        record("GET /api/chat/{id}/messages", code == 200, code, f"{len(data)} messages")

    if booking_id:
        code, data = req(
            "POST",
            f"/api/chat/{booking_id}/messages",
            {"content": "Hello from API test"},
            token=ctoken,
        )
        record("POST /api/chat/{id}/messages", code == 201, code, data.get("content", data))

    call_id = None
    if booking_id:
        code, data = req("GET", f"/api/calls/booking/{booking_id}/contact", token=ctoken)
        record("GET /api/calls/booking/{id}/contact", code == 200, code, data.get("contact_phone", data))

        code, data = req("POST", f"/api/calls/booking/{booking_id}/initiate", token=ctoken)
        record("POST /api/calls/booking/{id}/initiate", code == 201, code, data.get("tel_uri", data))
        call_id = data.get("call_id") if isinstance(data, dict) else None

        code, data = req("GET", f"/api/calls/booking/{booking_id}", token=ctoken)
        record("GET /api/calls/booking/{id}", code == 200, code, f"{len(data)} calls")

    if call_id:
        code, data = req(
            "PATCH",
            f"/api/calls/{call_id}/status",
            {"status": "completed"},
            token=ctoken,
        )
        record("PATCH /api/calls/{id}/status", code == 200, code, data.get("status", data))

    if booking_id:
        code, data = req("POST", f"/api/delivery/{booking_id}/complete", token=dtoken)
        record("POST /api/delivery/{id}/complete", code == 200, code, data.get("status", data))

    code, data = req(
        "POST",
        "/api/bookings",
        {
            "gas_kg": 9.0,
            "address": "789 Cancel Test Road",
            "latitude": 6.52,
            "longitude": 3.37,
        },
        token=ctoken,
    )
    cancel_id = data.get("id") if isinstance(data, dict) else None
    if cancel_id:
        code, data = req("POST", f"/api/bookings/{cancel_id}/cancel", token=ctoken)
        record("POST /api/bookings/{id}/cancel", code == 200, code, data.get("status", data))

    try:
        import websockets

        async def ws_notifications():
            uri = f"wss://jumandi.onrender.com/ws/notifications?token={ctoken}"
            async with websockets.connect(uri, open_timeout=15) as ws:
                return json.loads(await asyncio.wait_for(ws.recv(), timeout=10))

        msg = asyncio.run(ws_notifications())
        record("WS /ws/notifications", msg.get("type") == "connected", 200, msg)

        if booking_id:

            async def ws_tracking():
                uri = f"wss://jumandi.onrender.com/ws/tracking/{booking_id}?token={ctoken}"
                async with websockets.connect(uri, open_timeout=15) as ws:
                    return json.loads(await asyncio.wait_for(ws.recv(), timeout=10))

            tmsg = asyncio.run(ws_tracking())
            record("WS /ws/tracking/{id}", "type" in tmsg, 200, tmsg)
    except Exception as exc:
        failed.append(("WebSocket tests", 0, str(exc)))

    print(f"\nPASSED: {len(passed)}")
    for name, code, detail in passed:
        print(f"  [OK] {name} ({code}) -> {detail}")

    if skipped:
        print(f"\nSKIPPED: {len(skipped)}")
        for name, reason in skipped:
            print(f"  [--] {name} -> {reason}")

    if failed:
        print(f"\nFAILED: {len(failed)}")
        for name, code, detail in failed:
            print(f"  [XX] {name} ({code}) -> {detail}")

    print(f"\nSUMMARY: {len(passed)} passed, {len(failed)} failed, {len(skipped)} skipped")


if __name__ == "__main__":
    main()
