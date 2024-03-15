import os

import cv2

from cell_module.detect_api.api import detect_table_api
from my_utils.logging_setup import Logger
from my_utils.path_helper import path_images

IMAGES_PATH = path_images()

for k in range(1, 15):
	file = os.path.join(IMAGES_PATH, "Anh{}.jpg".format(k))
	IMAGE = cv2.imread(file)
	Logger.info('Image: {}'.format(file))
	Logger.info(f'\n{detect_table_api(IMAGE)}')
	Logger.info('-' * 50)
