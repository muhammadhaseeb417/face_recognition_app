import cv2
import numpy as np
import os
from PIL import Image


def train_model(data_dir):
    paths = [os.path.join(data_dir, f) for f in os.listdir(data_dir)]
    faces = []
    ids = []

    for path in paths:
        img = Image.open(path).convert('L')
        image_np = np.array(img, 'uint8')
        id = int(os.path.split(path)[-1].split('.')[1])
        faces.append(image_np)
        ids.append(id)

    clf = cv2.face.LBPHFaceRecognizer_create()
    clf.train(faces, np.array(ids))
    clf.write("classifier.xml")
