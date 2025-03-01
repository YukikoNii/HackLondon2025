from ultralytics import YOLO
import cv2

# Load trained model
model = YOLO("runs/detect/train4/weights/best.pt")

# Load Braille dictionary
braille_dict = {
    "100000": "A", "101000": "B", "110000": "C", "110100": "D",
    "100100": "E", "111000": "F", "111100": "G", "101100": "H",
    "011000": "I", "011100": "J", "100010": "K", "101010": "L",
    "110010": "M", "110110": "N", "100110": "O", "111010": "P",
    "111110": "Q", "101110": "R", "011010": "S", "011110": "T",
    "100011": "U", "101011": "V", "011101": "W", "110011": "X",
    "110111": "Y", "100111": "Z"
}

# Load image
image_path = "data/img.webp"
image = cv2.imread(image_path)

# Run YOLO inference
results = model(image_path)

# Store detected Braille dots
detected_cells = []

# Process detected bounding boxes
for result in results:
    for box in result.boxes.xyxy:
        x1, y1, x2, y2 = map(int, box)
        
        # Find center of bounding box
        center_x = (x1 + x2) // 2
        center_y = (y1 + y2) // 2
        
        # Store detected Braille dot
        detected_cells.append((center_x, center_y))

        # Draw bounding box
        cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 2)

# Sort dots top-to-bottom, left-to-right
detected_cells.sort(key=lambda p: (p[1], p[0]))

# Convert detected dots into Braille binary patterns
braille_binary = []
for i in range(0, len(detected_cells), 6):
    cell = ['0'] * 6  
    for j, (x, y) in enumerate(detected_cells[i:i+6]):
        cell[j] = '1'  
    braille_binary.append("".join(cell))

# Convert Braille binary to text
translated_text = "".join([braille_dict.get(cell, "?") for cell in braille_binary])

# Display translated Braille text
print("Translated Braille:", translated_text)

# Show image with detections
cv2.imshow("Detected Braille", image)
cv2.waitKey(0)
cv2.destroyAllWindows()
