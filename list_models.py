import os
from google import genai
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("Error: GEMINI_API_KEY not found in .env")
    exit(1)

client = genai.Client(api_key=api_key)

try:
    print("Checking for models containing '1.5-flash'...")
    for model in client.models.list():
        if "1.5-flash" in model.name:
            print(f"Found: {model.name}")
except Exception as e:
    print(f"Error: {e}")
