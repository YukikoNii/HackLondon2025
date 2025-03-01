from flask import Flask, jsonify, request
from werkzeug.utils import secure_filename
import os
from gtts import gTTS
import asyncio
from googletrans import Translator

translator = Translator()

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

        output_dir = "audio"
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        output_path = os.path.join(output_dir, "output.mp3")
        tts.save(output_path)

        os.system(f"mpg321 {output_path}")

        return "Audio file created successfully", 200
    except Exception as e:
        return {"error": str(e)}, 500

app = Flask(__name__)

@app.route('/upload-image', methods=['POST'])
def upload_image():
    try:
        if 'image' not in request.files:
            return jsonify({"error": "No image file provided"}), 400
        
        file = request.files['image']
        return jsonify(*save_image(file))
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/text_to_audio', methods=['POST'])
def text_to_audio():
    try:
        data = request.json
        text = data.get('text')
        target_language = data.get('lang', 'en')
        if not text:
            return "No text provided", 400
        
        return jsonify(*generate_audio(text, target_language))
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
    
# curl -X POST -F "image=@/Users/vernellgowa/Vernell/Uni/HackLondon2025/output.mp3" http://127.0.0.1:5000/upload-image
