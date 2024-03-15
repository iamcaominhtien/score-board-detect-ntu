import os
from os.path import join

import cv2

import cell_module.colors as colors
import cell_module.helper_function as helper
from cell_module.detect_table.cut_table_row_by_row import cut_table_row_by_row
from cell_module.detect_table.detect_table import DetectTable
from cell_module.detect_table.filter_lines.horizontal_lines import filter_horizontal_lines
from cell_module.detect_table.filter_lines.ver_lines import filter_vertical_lines
from my_utils.line_helper import crop_ver_and_hor_lines
from my_utils.path_helper import path_images

IMAGES_PATH = path_images()

for k in range(1, 15):
	file = os.path.join(IMAGES_PATH, "Anh{}.jpg".format(k))
	IMAGE = cv2.imread(file)

	h_raw, _ = IMAGE.shape[:2]
	if h_raw > 1500:
		IMAGE = cv2.resize(IMAGE, (1199, 1631), interpolation=cv2.INTER_LANCZOS4)

	helper.imshow(IMAGE, "Image.jpg", 500)
	img_bin = helper.convert_to_bin_image(IMAGE, 5)
	helper.imshow(img_bin, "Image_bin.jpg", 500)

	my_detect_table = DetectTable(img_bin, IMAGE)
	# helper.imshow(detect_table.vertical_lines_img, "vertical_lines.jpg", 500)
	# helper.imshow(detect_table.horizontal_lines_img, "horizontal_lines.jpg", 500)
	# helper.imshow(detect_table.img_final_bin, "img_final_bin.jpg", 500)

	# draw lines on image
	img_lines = IMAGE.copy()
	for line in my_detect_table.vertical_lines:
		cv2.line(img_lines, (line[0], line[1]), (line[2], line[3]), colors.BLUE, 3, cv2.LINE_AA)
	for line in my_detect_table.horizontal_lines:
		cv2.line(img_lines, (line[0], line[1]), (line[2], line[3]), colors.BLUE, 3, cv2.LINE_AA)

	helper.imshow(img_lines, "Image{}_with_lines.jpg".format(k), 500)
	cv2.waitKey(0)

	horizontal_lines_filtered = my_detect_table.horizontal_lines.copy()
	if len(horizontal_lines_filtered) > 0:
		horizontal_lines_filtered = filter_horizontal_lines(my_detect_table.horizontal_lines)

	vertical_lines_filtered = my_detect_table.vertical_lines.copy()
	if len(vertical_lines_filtered) > 0 and len(horizontal_lines_filtered) > 0:
		vertical_lines_filtered = filter_vertical_lines(
			my_detect_table.vertical_lines,
			horizontal_lines_filtered
		)
	points = cut_table_row_by_row(horizontal_lines_filtered, vertical_lines_filtered, IMAGE, index_of_image=k)

	if points is not None:
		# points = remove_outlier(points)
		# draw line on image
		img_lines = IMAGE.copy()
		cropped_vertical_lines, cropped_horizontal_lines = crop_ver_and_hor_lines(
			vertical_lines_filtered,
			horizontal_lines_filtered
		)
		for line in cropped_horizontal_lines:
			cv2.line(img_lines, (line[0], line[1]), (line[2], line[3]), colors.BLUE, 3, cv2.LINE_AA)
		for line in cropped_vertical_lines:
			cv2.line(img_lines, (line[0], line[1]), (line[2], line[3]), colors.BLUE, 3, cv2.LINE_AA)

		helper.imshow(img_lines, "Image{}_with_lines_filter.jpg".format(k), 500)
		cv2.waitKey(0)

		row_cut_example_path = join(IMAGES_PATH, 'row_cut_example')
		if not os.path.exists(row_cut_example_path):
			os.makedirs(row_cut_example_path)
		for row in points:
			for point in row:
				cv2.imwrite(str(join(row_cut_example_path, point['name'])), point['point'])

	cv2.destroyAllWindows()
