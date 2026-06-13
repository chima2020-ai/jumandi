import json
import uuid
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://jumandi.onrender.com"
results = []


def hit(name, method, path, data=None, token=None, form=None, ok=lambda c: c in (200, 201)):
    url = BASE + path
    headers = {}
    body = None
    if form:
        body = urllib.parse.urlencode(form).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    elif data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, body, headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            raw = resp.read().decode()
            try:
                payload = json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                payload = raw
            results.append((name, "PASS" if ok(resp.status) else "FAIL", resp.status, str(payload)[:120]))
            return resp.status, payload
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            payload = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            payload = raw
        results.append((name, "PASS" if ok(e.code) else "FAIL", e.code, str(payload)[:120]))
        return e.code, payload


def main():
    uid = uuid.uuid4().hex[:8]
    pwd = "secret123"
    cemail = f"c_{uid}@jumandi.com"
    demail = f"d_{uid}@jumandi.com"

    hit("GET /", "GET", "/")
    _, cp = hit(
        "Register customer",
        "POST",
        "/api/auth/register",
        {
            "name": "Test Customer",
            "email": cemail,
            "phone": "+1234567890",
            "password": pwd,
            "role": "customer",
        },
    )
    ctoken = cp.get("access_token") if isinstance(cp, dict) else None
    _, dp = hit(
        "Register delivery",
        "POST",
        "/api/auth/register",
        {
            "name": "Test Driver",
            "email": demail,
            "phone": "+1987654321",
            "password": pwd,
            "role": "delivery",
        },
    )
    dtoken = dp.get("access_token") if isinstance(dp, dict) else None
    hit("Login", "POST", "/api/auth/login", form={"username": cemail, "password": pwd})
    hit("GET /api/auth/me", "GET", "/api/auth/me", token=ctoken)
    hit("POST /api/auth/otp/send", "POST", "/api/auth/otp/send", token=ctoken)
    hit(
        "POST /api/auth/otp/verify (bad code)",
        "POST",
        "/api/auth/otp/verify",
        {"code": "0000"},
        token=ctoken,
        ok=lambda c: c == 400,
    )
    _, bp = hit(
        "POST /api/bookings",
        "POST",
        "/api/bookings",
        {"gas_kg": 12, "address": "Test St", "latitude": 6.5, "longitude": 3.3},
        token=ctoken,
    )
    bid = bp.get("id") if isinstance(bp, dict) else None
    hit("GET /api/bookings/my", "GET", "/api/bookings/my", token=ctoken)
    hit("GET /api/delivery/pending", "GET", "/api/delivery/pending", token=dtoken)
    if bid:
        hit("POST /api/delivery/{id}/accept", "POST", f"/api/delivery/{bid}/accept", token=dtoken)
        hit("POST /api/delivery/{id}/start", "POST", f"/api/delivery/{bid}/start", token=dtoken)
        hit(
            "POST /api/chat/{id}/messages",
            "POST",
            f"/api/chat/{bid}/messages",
            {"content": "hi"},
            token=ctoken,
            ok=lambda c: c == 201,
        )
        hit(
            "POST /api/calls/booking/{id}/initiate",
            "POST",
            f"/api/calls/booking/{bid}/initiate",
            token=ctoken,
            ok=lambda c: c == 201,
        )
        hit("POST /api/delivery/{id}/complete", "POST", f"/api/delivery/{bid}/complete", token=dtoken)
    hit(
        "POST /api/delivery/location",
        "POST",
        "/api/delivery/location",
        {"latitude": 6.5, "longitude": 3.3},
        token=dtoken,
    )

    print(f"LIVE API TEST — {BASE}\n" + "=" * 55)
    for name, status, code, detail in results:
        print(f"[{status}] {name} ({code})")
        print(f"         {detail}")
    passed = sum(1 for r in results if r[1] == "PASS")
    print(f"\n{passed}/{len(results)} passed")


if __name__ == "__main__":
    main()
