import cv2
import numpy as np
import pyttsx3
from openai import OpenAI
import base64
import threading
import time

client = OpenAI()

def speak(text):
    engine = pyttsx3.init()
    engine.say(text)
    engine.runAndWait()

def frame_to_base64(frame):
    _, buffer = cv2.imencode('.jpg', frame)
    jpg_as_text = base64.b64encode(buffer).decode('utf-8')
    return jpg_as_text

def analyse_image(base64_image):
    response = client.chat.completions.create(
        model="o1",
        messages=[
            {"role": "developer", "content": "You are a helpful assistant which guides visually impaired people navigate their surroundings."},
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": (
                            "Analyze the provided image and describe key elements in a concise and spoken manner. "
                            "Identify objects, their positions, and any potential obstacles. "
                            "Provide guidance by suggesting safe movement directions (left, right, forward, or stop) based on the detected environment."
                        ),
                    },
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"},
                    },
                ],
            }
        ],
    )
    return response.choices[0].message.content

def process_frame(frame):
    global processing
    processing = True  # Set processing flag to prevent multiple triggers

    frame_base64 = frame_to_base64(frame)
    text = analyse_image(frame_base64)
    print(text)
    speak(text)

    processing = False  # Reset processing flag after completion

# Open webcam
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FPS, 30)  # Set frame rate
cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Reduce buffering

processing = False  # Flag to prevent multiple processing triggers
spinner_frames = ['|', '/', '-', '\\']  # Frames for the spinner animation
spinner_index = 0

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # Display processing status
    if processing:
        spinner_index = (spinner_index + 1) % len(spinner_frames)
        cv2.putText(frame, f"Processing {spinner_frames[spinner_index]}", 
                    (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2, cv2.LINE_AA)
    
    # Show the video feed
    cv2.imshow('Blind Navigation', frame)

    key = cv2.waitKey(1) & 0xFF
    if key == ord('d') and not processing:  # Press 'd' to trigger detection if not already processing
        threading.Thread(target=process_frame, args=(frame,), daemon=True).start()

    elif key == ord('q'):  # Press 'q' to quit
        break

cap.release()
cv2.destroyAllWindows()
