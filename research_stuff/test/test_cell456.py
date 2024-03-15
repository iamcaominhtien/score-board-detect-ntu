import logging
import re
from os import listdir, path
from typing import Sequence

import cv2

from cell_module.cell_456.cell_456 import cell_456_process
from my_utils.path_helper import path_test_inputs

input_folder = path.join(path_test_inputs(), 'detection_tests')


def load_test_data():
	pattern = r'Pic._row_._[456].jpg'
	file_paths = [
		path.join(input_folder, file)
		for file in listdir(input_folder)
		if re.match(pattern, file)
	]
	images = [cv2.imread(image_path) for image_path in file_paths]
	return images


def test_cell456():
	images = load_test_data()
	for index, image in enumerate(images):
		try:
			results = cell_456_process(image)
			assert isinstance(results, Sequence), f'Error when run {index + 1}th image: {results}'
		except Exception as e:
			logging.error(f'Error in test_cell456: {e}')
			assert False, f'Error when run {index + 1}th image: {e}'
