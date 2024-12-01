import cv2
import numpy as np
import os

# Recognize a face
def recognize_face(image_path):
    clf = cv2.face.LBPHFaceRecognizer_create()
    clf.read("classifier.xml")
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
    
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.1, 4)

    for (x, y, w, h) in faces:
        face = gray[y:y+h, x:x+w]
        id, confidence = clf.predict(face)
        if confidence < 70:
            return {"status": "success", "user": f"User {id}"}
    return {"status": "failed", "message": "Face not recognized"}


# Add a new user
def add_user(image_path, name):
    os.rename(image_path, f"data/user.{len(os.listdir('data'))+1}.jpg")


# Delete a user
def delete_user(name, folder):
    user_files = [f for f in os.listdir(folder) if name in f]
    for file in user_files:
        os.remove(os.path.join(folder, file))
