import os
from flask import Flask, request, jsonify
import cv2
import numpy as np
from werkzeug.utils import secure_filename
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

CLASSIFIER_DIR = 'classifiers'
UPLOAD_FOLDER = 'uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

os.makedirs(CLASSIFIER_DIR, exist_ok=True)
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/train', methods=['POST'])
def train_user():
    name = request.form['name'].strip()
    if not name:
        return jsonify({'error': 'Name is required'}), 400

    images = request.files.getlist('images')
    if len(images) < 10:
        return jsonify({'error': 'At least 10 images are required for training'}), 400

    user_dir = os.path.join(CLASSIFIER_DIR, secure_filename(name))
    os.makedirs(user_dir, exist_ok=True)

    for i, img in enumerate(images):
        img_path = os.path.join(user_dir, f'{i}.jpg')
        img.save(img_path)

    classifier_path = os.path.join(user_dir, 'classifier.xml')
    train_classifier(user_dir, classifier_path)

    for file in os.listdir(user_dir):
        file_path = os.path.join(user_dir, file)
        if file.endswith('.jpg') or file.endswith('.png'):
            os.remove(file_path)

    return jsonify({'message': 'User trained successfully', 'classifier': classifier_path})


def train_classifier(user_dir, classifier_path):
    images = []
    labels = []

    label_map = {}
    label_counter = 0

    for subdir, _, files in os.walk(user_dir):
        for file in files:
            if file.endswith('jpg') or file.endswith('png'):
                image_path = os.path.join(subdir, file)
                image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
                if image is None:
                    continue

                user_name = os.path.basename(subdir)
                if user_name not in label_map:
                    label_map[user_name] = label_counter
                    label_counter += 1

                label = label_map[user_name]
                images.append(image)
                labels.append(label)

    if not images or not labels:
        raise ValueError("No valid training data found")

    images = np.array(images)
    labels = np.array(labels)

    recognizer = cv2.face.LBPHFaceRecognizer_create()
    recognizer.train(images, labels)
    recognizer.save(classifier_path)


@app.route('/login', methods=['POST'])
def login_user():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    # Save the uploaded image
    image = request.files['image']
    img_path = os.path.join(UPLOAD_FOLDER, secure_filename(image.filename))
    image.save(img_path)

    xml_path = os.path.join('utils', 'haarcascade_frontalface_default.xml')
    if not os.path.exists(xml_path):
        return jsonify({'error': 'Face detection XML not found'}), 500

    face_cascade = cv2.CascadeClassifier(xml_path)
    match_results = {}  # Store best matching percentages for each user

    # Loop through each user's classifier
    for user_folder in os.listdir(CLASSIFIER_DIR):
        user_classifier_path = os.path.join(CLASSIFIER_DIR, user_folder, 'classifier.xml')
        if not os.path.exists(user_classifier_path):
            continue

        recognizer = cv2.face.LBPHFaceRecognizer_create()
        recognizer.read(user_classifier_path)

        img = cv2.imread(img_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=10)

        # Check face recognition for each face detected
        for (x, y, w, h) in faces:
            face = gray[y:y+h, x:x+w]
            label, confidence = recognizer.predict(face)
            match_percentage = max(0, 100 - confidence)  # Convert confidence to match percentage

            # Update with the best match percentage for each user
            if user_folder not in match_results or match_percentage > match_results[user_folder]:
                match_results[user_folder] = match_percentage

    # Delete the temporary uploaded image
    os.remove(img_path)

    if not match_results:
        return jsonify({'error': 'No face detected or no match found'}), 404

    # Include all matching percentages in the response
    all_matches = [{'user': user, 'match_percentage': percentage} for user, percentage in match_results.items()]
    best_match = max(all_matches, key=lambda x: x['match_percentage'])
    response = {
        'message': 'Face recognition completed',
        'best_match': best_match,
        'all_matches': all_matches  # List of all user matching percentages
    }

    if best_match['match_percentage'] >= 50:  # Threshold for successful login
        response['login_status'] = 'success'
    else:
        response['login_status'] = 'failed'

    return jsonify(response), 200


if __name__ == '__main__':
    app.run(debug=True)
