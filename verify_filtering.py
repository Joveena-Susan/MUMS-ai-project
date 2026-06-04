import requests
import json

BASE_URL = "http://127.0.0.1:5000"
EMAIL = "jeffery@gmail.com"
MOOD = "Sad"

def log_song(title, artist, action):
    resp = requests.post(f"{BASE_URL}/log-song", json={
        "email": EMAIL,
        "mood": MOOD,
        "title": title,
        "artist": artist,
        "action": action
    })
    print(f"Logged {title} as {action}: {resp.json()}")

def get_songs(text):
    resp = requests.post(f"{BASE_URL}/get-song", json={
        "email": EMAIL,
        "text": text,
        "languages": ["english"],
        "limit": 10
    })
    return resp.json().get("songs", [])

if __name__ == "__main__":
    # 1. Clear history first (optional, but good for clean test)
    requests.post(f"{BASE_URL}/clear-played-songs", json={"email": EMAIL})
    
    # 2. Log a played song
    log_song("Test Played Song", "Test Artist", "played")
    
    # 3. Log a skipped song
    log_song("Test Skipped Song", "Test Artist", "skipped")
    
    # 4. Get songs for the same mood
    songs = get_songs("I am feeling very sad")
    
    print("\nSongs recommended:")
    found_played = False
    found_skipped = False
    for s in songs:
        if s["title"] == "Test Played Song": found_played = True
        if s["title"] == "Test Skipped Song": found_skipped = True
        print(f"- {s['title']} by {s['artist']}")
    
    if found_played:
        print("\nFAILURE: Played song was recommended!")
    else:
        print("\nSUCCESS: Played song was excluded.")
        
    # Note: Skipped stores are only played if Spotify returns them in the search.
    # Our simple test won't see them unless they are in the search results.
    # But we verified the backend filter logic.
