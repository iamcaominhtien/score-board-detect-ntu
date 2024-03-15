import os

import cv2

import cell_module.colors as colors
import cell_module.detect_table as detect_table
import cell_module.helper_function as helper
from my_utils.path_helper import path_images, path_test_inputs

output_path = os.path.join(path_test_inputs(), "detection_tests")

if not os.path.exists(output_path):
	os.makedirs(output_path)

for k in range(1, 15):
	file = os.path.join(path_images(), "Anh{}.jpg".format(k))
	IMAGE = cv2.imread(file)

	h_raw, _ = IMAGE.shape[:2]
	if h_raw > 1500:
		IMAGE = cv2.resize(IMAGE, (1199, 1631), interpolation=cv2.INTER_LANCZOS4)

	gray_img = cv2.cvtColor(IMAGE, cv2.COLOR_BGR2GRAY)
	img_bin = helper.convert_to_bin_image(IMAGE, 5)
	my_detect_table = detect_table.DetectTable(img_bin, IMAGE)

	horizontal_lines_filtered = my_detect_table.horizontal_lines.copy()
	if len(horizontal_lines_filtered) > 0:
		horizontal_lines_filtered = detect_table.filter_horizontal_lines(my_detect_table.horizontal_lines)

	vertical_lines_filtered = my_detect_table.vertical_lines.copy()
	if len(vertical_lines_filtered) > 0 and len(horizontal_lines_filtered) > 0:
		vertical_lines_filtered = detect_table.filter_vertical_lines(
			my_detect_table.vertical_lines,
			horizontal_lines_filtered
		)
	points = detect_table.cut_table_row_by_row(
		horizontal_lines_filtered, vertical_lines_filtered, IMAGE, img_bin, index_of_image=k
	)

	if points is not None:
		for row in points:
			for point in row:
				path_dir = os.path.join(output_path, point['name'])
				cv2.imwrite(path_dir, point['point'])
