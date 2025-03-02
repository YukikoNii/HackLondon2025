import os
from ultralytics import YOLO
import cv2
import numpy as np

# Load trained model
model = YOLO("runs/detect/train4/weights/best.pt")

# Load image
image_path = "data/2734_jpg.rf.94d9dd5a3d4a9d6590190de96c08a5e3.jpg"
file_name = os.path.basename(image_path)

image = cv2.imread(image_path)

# Run YOLO inference
results = model(image_path)

# Load class names from the model
class_names = model.names  # Dictionary mapping class indices to names

detections = []

for result in results:
    for box in result.boxes:
        class_id = int(box.cls)  # Get class ID
        label = class_names[class_id]  # Get class name
        confidence = box.conf.item()  # Confidence score
        x_min = box.xyxy[0][0].item()  # Left X coordinate
        y_min = box.xyxy[0][1].item()  # Top Y coordinate

        detections.append((x_min, y_min, label, confidence))
    result.save(filename=f'braille/{file_name}')
    result.show()

# Convert detections to NumPy array for sorting
detections = np.array(detections, dtype=object)

# Sort by Y-coordinate first
detections = detections[detections[:, 1].argsort()]

# Group by rows using a Y threshold (to cluster letters in the same row)
y_threshold = 20  # Adjust if needed
rows = []
current_row = [detections[0]]

for i in range(1, len(detections)):
    if abs(detections[i, 1] - current_row[-1][1]) < y_threshold:
        current_row.append(detections[i])
    else:
        rows.append(sorted(current_row, key=lambda x: x[0]))  # Sort row by X-coordinates
        current_row = [detections[i]]

# Append last row
if current_row:
    rows.append(sorted(current_row, key=lambda x: x[0]))

# Flatten sorted rows into the final ordered text
ordered_text = "".join([char[2] for row in rows for char in row])
print("Detected Text:", ordered_text)
