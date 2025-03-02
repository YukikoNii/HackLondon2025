import cv2
import torch
import numpy as np
import pyttsx3
import time

def speak(text):
    engine = pyttsx3.init()
    engine.say(text)
    engine.runAndWait()

# Load YOLOv8 model
# model = torch.hub.load('ultralytics/yolov5', 'yolov5s', pretrained=True)
model = torch.hub.load('ultralytics/yolov5', 'yolov5n', pretrained=True)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")
model = model.to(device)

# Open webcam
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FPS, 30)  # Increase frame rate for smoother video
cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Reduce buffering to lower lag

# Set frame size
frame_width = 640
frame_height = 480
cap.set(cv2.CAP_PROP_FRAME_WIDTH, frame_width)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, frame_height)

# Background subtraction for motion detection
fgbg = cv2.createBackgroundSubtractorMOG2()
last_message = ""

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    
    frame = cv2.resize(frame, (frame_width, frame_height))

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    fgmask = fgbg.apply(gray)
    
    # Detect motion by checking significant foreground changes
    motion_detected = np.count_nonzero(fgmask) > 5000  # Adjust threshold as needed
    
    results = model(frame)
    closest_object = None
    object_position = ""
    movement_suggestion = ""
    
    for obj in results.xyxy[0]:
        x1, y1, x2, y2, conf, cls = obj.tolist()
        label = model.names[int(cls)]
        
        if conf > 0.5:
            center_x = (x1 + x2) / 2
            
            # Determine object position
            if center_x < frame_width / 4:
                object_position = "far to the left"
                movement_suggestion = "You can move right."
            elif center_x < frame_width / 2:
                object_position = "on your left"
                movement_suggestion = "Move slightly right."
            elif center_x < 3 * frame_width / 4:
                object_position = "right ahead"
                movement_suggestion = "Stop or turn around."
            else:
                object_position = "far to the right"
                movement_suggestion = "You can move left."
            
            cv2.rectangle(frame, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
            cv2.putText(frame, f"{label} {object_position}", (int(x1), int(y1) - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
            
            closest_object = label
    
        if closest_object:
            speak(f"Warning! {closest_object} is {object_position}. {movement_suggestion}")
        elif motion_detected:
            speak("Warning! Moving object detected ahead.")
        else:
            speak("Clear path ahead.")  

        if closest_object:
            message = f"Warning! {closest_object} is {object_position}. {movement_suggestion}"
        elif motion_detected:
            message = "Warning! Moving object detected ahead."
        else:
            message = "Clear path ahead."

        if message != last_message:  # Only speak if message has changed
            last_message = message
            speak(message)

        
    cv2.imshow('Blind Navigation', frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()