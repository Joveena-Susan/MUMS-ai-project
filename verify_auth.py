import requests
import json

BASE_URL = "http://127.0.0.1:5000"

def test_auth():
    # 1. Register
    reg_data = {
        "email": "test@example.com",
        "password": "password123",
        "name": "Test User",
        "dob": "1990-01-01",
        "age": "34",
        "gender": "Male"
    }
    print("Testing /register...")
    r = requests.post(f"{BASE_URL}/register", json=reg_data)
    print(f"Status: {r.statusCode if hasattr(r, 'statusCode') else r.status_code}")
    print(f"Response: {r.text}")
    
    # 2. Login
    login_data = {
        "email": "test@example.com",
        "password": "password123"
    }
    print("\nTesting /login...")
    r = requests.post(f"{BASE_URL}/login", json=login_data)
    print(f"Status: {r.status_code}")
    print(f"Response: {r.text}")

def test_sync():
    # 3. Sync History
    history_data = {
        "email": "test@example.com",
        "history": [
            {
                "date": "2026-03-03 15:00",
                "start_mood": "sad",
                "target_mood": "happy",
                "end_mood": "happy",
                "intensity": 75,
                "duration": "10:00",
                "isLive": False,
                "songs": [
                    {"title": "Song 1", "artist": "Artist 1", "played_in_mood": "sad"}
                ],
                "transitions": [
                    {"from": "sad", "to": "happy", "time": "15:05", "intensity": 80}
                ]
            }
        ]
    }
    print("\nTesting /sync-history...")
    r = requests.post(f"{BASE_URL}/sync-history", json=history_data)
    print(f"Status: {r.status_code}")
    print(f"Response: {r.text}")

    # 4. Get History
    print("\nTesting /get-history...")
    r = requests.post(f"{BASE_URL}/get-history", json={"email": "test@example.com"})
    print(f"Status: {r.status_code}")
    j = r.json()
    print(f"History count: {len(j.get('history', []))}")
    if j.get('history'):
        print(f"First session date: {j['history'][0]['date']}")

    # 5. Sync Preferences
    pref_data = {
        "email": "test@example.com",
        "blocked": [{"title": "Blocked 1", "artist": "Bad Artist"}],
        "liked": [{"title": "Favorite 1", "artist": "Good Artist"}]
    }
    print("\nTesting /sync-preferences...")
    r = requests.post(f"{BASE_URL}/sync-preferences", json=pref_data)
    print(f"Status: {r.status_code}")
    print(f"Response: {r.text}")

    # 6. Get Preferences
    print("\nTesting /get-preferences...")
    r = requests.post(f"{BASE_URL}/get-preferences", json={"email": "test@example.com"})
    print(f"Status: {r.status_code}")
    print(f"Response: {r.text}")

if __name__ == "__main__":
    # test_auth() # Already tested, will fail if user exists
    test_sync()
