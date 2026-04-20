import os
import requests
import json

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("Error: GEMINI_API_KEY not found in environment.")
    exit(1)

url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"

response = requests.get(url)
if response.status_code == 200:
    models = response.json().get("models", [])
    print("Available Models:")
    for m in models:
        print(f"- {m['name']}")
else:
    print(f"Error {response.status_code}: {response.text}")
