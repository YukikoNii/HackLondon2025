#!/usr/bin/env python3
from google import genai
from HackLondon2025.inference import get_detected_text

def main():
    image_path = 'alphabet.png'  # Replace with your actual image file path
    
    client = genai.Client(api_key="AIzaSyAna9p5EPBQ-ArE6J-ac_XJasN0o20adf0")
    
    # Get the detected Braille text from inference.py
    detected_text = get_detected_text(image_path)
    if not detected_text:
        print("No Braille text detected.")
        return
    
    # Construct a prompt for Google Gemini.
    prompt = f"""I have detected the following Braille pattern from an image:

    {detected_text}

    On a single line, display what the sequence is approximately equivalent to in English. 
    If its approximately equal to alphabet letters then just print out the alphabet and nothing else

    """




    
    # Query Google Gemini.
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt
    )
    
    print(response.text)

if __name__ == "__main__":
    main()
