from flask import Flask, jsonify, request
from werkzeug.utils import secure_filename
import os
from gtts import gTTS
import asyncio
from googletrans import Translator
import openai
from google import genai
from inference import get_detected_text
import filetype 

import cv2
import numpy as np
import base64
import threading
import time

translator = Translator()
client = genai.Client(api_key="AIzaSyAna9p5EPBQ-ArE6J-ac_XJasN0o20adf0")

async def translate_text(text, target_language):
    try:
        translated = await translator.translate(text, dest=target_language)
        return translated.text
    except Exception as e:
        return str(e)

def save_image(file):
    if file.filename == '':
        return {"error": "No selected file"}, 400
    
    filename = secure_filename(file.filename)
    file.save(os.path.join('uploads', filename))
    return {"message": "Image uploaded successfully", "filename": filename}, 200

def generate_audio(text, target_language):
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        translated_text = loop.run_until_complete(translate_text(text, target_language))

        tts = gTTS(text=translated_text, lang=target_language)

        output_dir = os.path.join("static", "audio")
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        output_path = os.path.join(output_dir, "output.mp3")
        tts.save(output_path)

        os.system(f"mpg321 {output_path}")

        audio_url = f"http://10.97.229.235:5001/{output_path}"

        return {
            "message": "Audio file created successfully",
            "audio_url": audio_url
        }
    
    except Exception as e:
        return {"error": str(e)}, 500

app = Flask(__name__)

@app.route('/upload_image', methods=['POST'])
def upload_image():
    try:
        if 'image' not in request.files:
            return jsonify({"error": "No image file provided"}), 400
        
        file = request.files['image']
        return jsonify(*save_image(file))
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/read_braille', methods=['POST'])
def read_braille():
    try:
        if 'image' not in request.files:
            return jsonify({"error": "No image file provided"}), 400
        
        file = request.files['image']
        
        # Save the image to a temporary location
        temp_image_path = "/tmp/" + file.filename
        file.save(temp_image_path)

        client = genai.Client(api_key="AIzaSyAna9p5EPBQ-ArE6J-ac_XJasN0o20adf0")
        
        # Get the detected Braille text from inference.py using the saved image path
        detected_text = get_detected_text(temp_image_path)
        
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

        return jsonify({"response": response.text})
    except Exception as e:
        print("hello2")
        return jsonify({"error": str(e)}), 500

@app.route('/text_to_audio', methods=['POST'])
def text_to_audio():
    try:
        data = request.json
        text = data.get('text')
        target_language = data.get('lang', 'en')
        if not text:
            return "No text provided", 400
        
        return jsonify(generate_audio(text, target_language))
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# @app.route('/analyse_image', methods=['POST'])
# def analyse_image_endpoint():
#     try:
#         data = request.json
#         base64_image = data.get('image')
#         if not base64_image:
#             return "No image provided", 400
        
#         analysis_result = analyse_image(base64_image)
#         return jsonify({"analysis": analysis_result})
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500


@app.route('/analyse_surroundings', methods=['POST']) 
def analyse_surroundings():
    if 'image' not in request.files:
        return jsonify({"error": "No image file provided"}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    try:
        # Read the image file
        file_data = file.read()
        if not file_data:
            return jsonify({"error": "Empty file"}), 400

        image = cv2.imdecode(np.frombuffer(file_data, np.uint8), cv2.IMREAD_COLOR)
        if image is None:
            return jsonify({"error": "Invalid image file"}), 400


        # Convert the image to base64
        base64_image = frame_to_base64(image)

        # Analyze the image
        description = analyse_image(base64_image)
        print("description", description)
        return jsonify({"description": description}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


def frame_to_base64(frame):
    _, buffer = cv2.imencode('.jpg', frame)
    return base64.b64encode(buffer).decode('utf-8')

def analyse_image(base64_image):

    response = client.models.generate_content(
        model="gemini-2.0-flash-exp",
        contents=["You are a helpful assistant which guides visually impaired people navigate their surroundings. Analyze the provided image and describe key elements in a concise and spoken manner. Identify objects, their positions, and any potential obstacles. Provide guidance by suggesting safe movement directions (left, right, forward, or stop) based on the detected environment. Don't say anything unnecessary. ",
                genai.types.Part.from_bytes(data=base64_image, mime_type="image/jpeg")])

    print(response.text)
    return response.text

if __name__ == '__main__':
     app.run(host='0.0.0.0', port=5001, debug=True)
    
# curl -X POST -F "image=@/Users/vernellgowa/Vernell/Uni/HackLondon2025/motivation.png" http://127.0.0.1:5000/upload-image
