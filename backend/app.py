from flask import Flask, request, jsonify
import cv2
import os
import numpy as np
from werkzeug.utils import secure_filename

app = Flask(__name__)

# Directory to save classifier files
CLASSIFIER_DIR = 'classifiers'
UPLOAD_FOLDER = 'uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/train', methods=['POST'])
def train_user():
    name = request.form['name'].strip()  # Remove leading/trailing spaces
    if not name:
        return jsonify({'error': 'Name is required'}), 400

    images = request.files.getlist('images')
    if not images:
        return jsonify({'error': 'No images provided'}), 400

    user_dir = os.path.join(CLASSIFIER_DIR, secure_filename(name))  # Ensure a valid folder name
    os.makedirs(user_dir, exist_ok=True)

    # Save images for training
    for i, img in enumerate(images):
        img_path = os.path.join(user_dir, f'{i}.jpg')
        img.save(img_path)

    # Train classifier
    classifier_path = os.path.join(user_dir, 'classifier.xml')
    train_classifier(user_dir, classifier_path)

    return jsonify({'message': 'User trained successfully', 'classifier': classifier_path})


def train_classifier(user_dir, classifier_path):
    images = []
    labels = []

    label_map = {}
    label_counter = 0

    for subdir, dirs, files in os.walk(user_dir):
        for file in files:
            if file.endswith('jpg') or file.endswith('png'):
                image_path = os.path.join(subdir, file)
                image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)

                user_name = os.path.basename(subdir)

                if user_name not in label_map:
                    label_map[user_name] = label_counter
                    label_counter += 1

                label = label_map[user_name]

                images.append(image)
                labels.append(label)

    images = np.array(images)
    labels = np.array(labels)

    recognizer = cv2.face.LBPHFaceRecognizer_create()
    recognizer.train(images, labels)

    recognizer.save(classifier_path)

@app.route('/login', methods=['POST'])
def login_user():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    image = request.files['image']

    # Save the uploaded image temporarily
    img_path = os.path.join(UPLOAD_FOLDER, secure_filename(image.filename))
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)  # Ensure upload directory exists
    image.save(img_path)

    # Initialize face detection
    xml_path = os.path.join('utils', 'haarcascade_frontalface_default.xml')
    faceCascade = cv2.CascadeClassifier(xml_path)

    # Variables to track the best match
    best_user = None
    best_confidence = float('inf')

    # Loop through all classifiers in the "classifiers" folder
    for user_folder in os.listdir(CLASSIFIER_DIR):
        user_classifier_path = os.path.join(CLASSIFIER_DIR, user_folder, 'classifier.xml')

        if not os.path.exists(user_classifier_path):
            continue

        # Load the classifier for the user
        recognizer = cv2.face.LBPHFaceRecognizer_create()
        recognizer.read(user_classifier_path)

        # Process the uploaded image for face recognition
        img = cv2.imread(img_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = faceCascade.detectMultiScale(gray, 1.1, 4)

        for (x, y, w, h) in faces:
            face = gray[y:y+h, x:x+w]
            label, confidence = recognizer.predict(face)

            # Track the user with the lowest confidence
            if confidence < best_confidence:
                best_user = user_folder
                best_confidence = confidence

    # Clean up the uploaded image
    os.remove(img_path)

    # Check if a match was found
    if best_user and best_confidence < 70:  # Confidence threshold
        return jsonify({'message': 'Login successful', 'username': best_user}), 200

    return jsonify({'error': 'Face not recognized or no match found'}), 404


if __name__ == '__main__':
    app.run(debug=True)
