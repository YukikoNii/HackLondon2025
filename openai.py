import base64
from openai import OpenAI

client = OpenAI()

# Function to encode the image
def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")


# Path to your image
image_path = "data/img.webp"

# Getting the Base64 string
base64_image = encode_image(image_path)

response = client.chat.completions.create(
    model="o1",
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "convert this image of braille to text",
                },
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"},
                    
                },
            ],
        }
    ],
)

print(response.choices[0])