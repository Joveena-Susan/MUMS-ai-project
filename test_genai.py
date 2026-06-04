import os
from google import genai
from google.genai import errors
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("GEMINI_API_KEY not found")
    exit(1)

client = genai.Client(api_key=api_key)

models_to_try = [
    "gemini-1.5-flash",
    "gemini-1.5-flash-8b",
    "gemini-2.0-flash",
    "gemini-2.0-flash-lite-preview-02-05", # some accounts have this
]

for model_id in models_to_try:
    print(f"\nTesting {model_id}...")
    try:
        response = client.models.generate_content(
            model=model_id,
            contents="Say hi"
        )
        print(f"SUCCESS: {model_id} works!")
        print(f"Response: {response.text}")
        break
    except errors.ClientError as e:
        print(f"FAILED: {model_id} - {e}")
    except Exception as e:
        print(f"ERROR: {model_id} - {type(e).__name__}: {e}")
