import os
from os import path

import cv2

from cell_module import helper_function as helper
from cell_module.detect_table import detect_table
from cell_module.detect_table.cut_table_row_by_row import cut_table_row_by_row
from cell_module.detect_table.filter_lines.horizontal_lines import filter_horizontal_lines
from cell_module.detect_table.filter_lines.ver_lines import filter_vertical_lines
from my_utils.path_helper import path_test_inputs

input_folder = path.join(path_test_inputs(), 'detect_table')


def load_test_data():
	file_paths = [path.join(input_folder, file) for file in os.listdir(input_folder)]
	images = [cv2.imread(image_path) for image_path in file_paths]
	return images


def test_detect_table():
	images = load_test_data()
	for index, image in enumerate(images):
		h_raw = image.shape[0]
		if h_raw > 1500:
			image = cv2.resize(image, (1199, 1631), interpolation=cv2.INTER_LANCZOS4)

		img_bin = helper.convert_to_bin_image(image, 5)

		my_detect_table = detect_table.DetectTable(img_bin, image)
		horizontal_lines_filtered = my_detect_table.horizontal_lines.copy()
		if len(horizontal_lines_filtered) > 0:
			horizontal_lines_filtered = filter_horizontal_lines(my_detect_table.horizontal_lines)

		vertical_lines_filtered = my_detect_table.vertical_lines.copy()
		if len(vertical_lines_filtered) > 0 and len(horizontal_lines_filtered) > 0:
			vertical_lines_filtered = filter_vertical_lines(
				my_detect_table.vertical_lines,
				horizontal_lines_filtered
			)
		cut_table_row_by_row(
			horizontal_lines_filtered, vertical_lines_filtered, image, index_of_image=index
		)
