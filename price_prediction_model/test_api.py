import requests
import json

# API endpoint
url = "http://localhost:8000/predict"

# Test data that matches the expected input format
test_data = {
    "state": "Karnataka",
    "district": "Bangalore",
    "market": "Binny Mill (F&V), Bangalore",
    "commodity": "Apple",
    "variety": "Apple",
    "grade": "Large",
    "arrival_date": "2025-03-04",
    "min_price": 10000,
    "max_price": 15000,
    "collection_date": "2025-03-04",
    "temperature_c": 32.3,
    "humidity": 40,
    "precipitation_mm": 0.5,
    "wind_kph": 6,
    "weekday": 2
}

# Make POST request to the API
response = requests.post(url, json=test_data)

# Print the response
print("Status code:", response.status_code)
print("Response body:", json.dumps(response.json(), indent=2))

# Try the model info endpoint
info_response = requests.get("http://localhost:8000/model-info")
print("\nModel Info:")
print(json.dumps(info_response.json(), indent=2))