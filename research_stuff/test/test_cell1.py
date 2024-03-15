import re
from os import listdir, path

import cv2

from cell_module.cell_1 import get_cells_number_one
from my_utils.logging_setup import Logger
from my_utils.path_helper import path_test_inputs

input_folder = path.join(path_test_inputs(), 'detection_tests')


def load_test_data():
	pattern = r'Pic._row_._1.jpg'
	file_paths = [
		path.join(input_folder, file)
		for file in listdir(input_folder)
		if re.match(pattern, file)
	]
	images = [cv2.imread(image_path) for image_path in file_paths]
	return images


def test_cell1():
	images = load_test_data()
	results = get_cells_number_one(images)
	Logger.info(results)
	assert len(results) == len(images), f"Expected {len(images)} results, but got {len(results)}"
