import os
from google import genai
from google.genai import errors
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=api_key)

print("Listing all models available for this key:")
for m in client.models.list():
    print(f"- {m.name}")

models_to_test = ["gemini-1.5-flash-8b", "gemini-1.5-flash", "gemini-2.5-flash"]

for m_id in models_to_test:
    print(f"\nTesting {m_id}...")
    try:
        res = client.models.generate_content(model=m_id, contents="test")
        print(f"✅ SUCCESS with {m_id}!")
        break
    except errors.ClientError as e:
        print(f"❌ FAILED {m_id} (ClientError): {e}")
    except Exception as e:
        print(f"❌ ERROR {m_id} ({type(e).__name__}): {e}")
