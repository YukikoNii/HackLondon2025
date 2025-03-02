import requests

# Define the endpoint URL
url = "https://hacklondonserver.onrender.com/read_braille"

# Specify the image file to send
files = {
    "image": ("alphabet.png", open("alphabet.png", "rb"), "image/jpeg")
}

# Send the POST request
response = requests.post(url, files=files)

# Print the response
print(response.status_code)
print(response.json())  # If the server returns JSON
