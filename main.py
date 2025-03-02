#!/usr/bin/env python3
from google import genai
from inference import get_detected_text

def main():
    image_path = 'motivation.png'  # Replace with your actual image file path
    
    client = genai.Client(api_key="AIzaSyAna9p5EPBQ-ArE6J-ac_XJasN0o20adf0")
    
    # Get the detected Braille text from inference.py
    detected_text = get_detected_text(image_path)
    if not detected_text:
        print("No Braille text detected.")
        return
    
    # Construct a prompt for Google Gemini.
    prompt = f"""I have detected the following Braille pattern from an image:

    {detected_text}

    If "C CC" is detected, then output "You can do it" in this exact form. 
    Otherwise, if alphabet is detected, output "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
    DO NOT output any other word or punctuation. 
    """

    # Query Google Gemini.
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt
    )
    
    print(response.text)

if __name__ == "__main__":
    main()
