import cv2
import torch
import numpy as np
import pyttsx3
from openai import OpenAI
import base64

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
    return client.chat.completions.create(
        model="o1",
        messages=[
            {"role": "developer", "content": "You are a helpful assistant which guides visually impaired people navigate their surroundings.."},
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

# Load YOLO model
# model = torch.hub.load('ultralytics/yolov5', 'yolov5s', pretrained=True)

# Open webcam
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FPS, 30)  # Set frame rate
cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Reduce buffering

detect_objects = False  # Detection is off initially

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    
    # Show the video feed without detection
    cv2.imshow('Blind Navigation', frame)

    key = cv2.waitKey(1) & 0xFF
    if key == ord('d'):  # Press 'd' to trigger detection
        detect_objects = True
    elif key == ord('q'):  # Press 'q' to quit
        break

    if detect_objects:
        detect_objects = False  # Reset detection flag

        # results = model(frame)
        detected_labels = []

        # for obj in results.xyxy[0]:
        #     x1, y1, x2, y2, conf, cls = obj.tolist()
        #     label = model.names[int(cls)]
        #     if conf > 0.5:
        #         detected_labels.append(label)

        # cv2.rectangle(frame, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
        # cv2.putText(frame, f"{label}", (int(x1), int(y1) - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

        # Convert frame to base64
        cv2.imwrite('uploads/frame.jpg', frame)
        frame_base64 = frame_to_base64(frame)

        # Pass the base64 image to the function
        response = analyse_image(frame_base64)
        print(response.choices)
        text = response.choices[0].message.content
        print(text)
        speak(text)


        if detected_labels:
            speak("Objects detected: " + ", ".join(detected_labels))
        else:
            speak("No objects found.")

cap.release()
cv2.destroyAllWindows()

