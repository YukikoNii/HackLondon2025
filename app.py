from io import BytesIO
from tkinter import Image
from flask import Flask, jsonify, request, send_file
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

@app.route('/read_braille', methods=['POST'])
def read_braille():
    try:
        if 'image' not in request.files:
            return jsonify({"error": "No image file provided"}), 400
        
        file = request.files['image']
        temp_image_path = "/tmp/" + file.filename
        file.save(temp_image_path)

        detected_text = get_detected_text(temp_image_path)
        
        return jsonify({"response": detected_text}) if detected_text else jsonify({"error": "No text detected"}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/get_image/<path:img_path>', methods=['GET'])
def get_image(img_path):
    try:
        # Set the base directory where images are stored
        base_dir = "braille/"  # Change this to your actual image folder
        image_full_path = f"{base_dir}{img_path}"

        return send_file(image_full_path, mimetype='image/jpeg')
    except FileNotFoundError:
        return {"error": "Image not found"}, 404


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

@app.route('/analyse_image', methods=['POST'])
def analyse_image_endpoint():
    try:
        data = request.json
        base64_image = data.get('image')
        if not base64_image:
            return "No image provided", 400
        
        analysis_result = analyse_image(base64_image)
        return jsonify({"analysis": analysis_result})
    except Exception as e:
        return jsonify({"error": str(e)}), 500



if __name__ == '__main__':
     app.run(host='0.0.0.0', port=5001, debug=True)
    
# curl -X POST -F "image=@/Users/vernellgowa/Vernell/Uni/HackLondon2025/alphabet.png" http://127.0.0.1:5001/read_braille
