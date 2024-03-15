from itertools import product

import cv2
import numpy as np

from my_utils.line_helper import find_intersection_of_2_lines


def cut_table_row_by_row(horizontal_lines, vertical_lines, img, index_of_image=1):
	"""
	Cuts the table into rows based on the detected horizontal and vertical lines.

	This method iterates over the horizontal lines and for each pair of consecutive lines, it iterates over the vertical lines.
	It then finds the intersections of the horizontal and vertical lines and uses these intersections to define a region in the image.
	This region is then transformed to a new image and added to the row.
	If the row contains 5 images, it is added to the cells.

	Args:
		horizontal_lines (np.ndarray): The detected horizontal lines in the image.
		vertical_lines (np.ndarray): The detected vertical lines in the image.
		img (np.array): The original image.
		index_of_image (int, optional): The index of the image. Defaults to 1.

	Returns:
		list: A list of rows, where each row is a list of dictionaries. Each dictionary contains the name of the image and the image itself.
	"""
	cells = list()
	for i in range(1, len(horizontal_lines)):
		h_line1 = horizontal_lines[i - 1]
		h_line2 = horizontal_lines[i]

		row = list()
		for j, v_line in enumerate(vertical_lines):
			if j not in [1, 2, 4, 5, 6]:
				continue
			v_line1 = vertical_lines[j - 1]
			v_line2 = v_line

			intersections = np.array(
				[
					intersection
					for h_l, v_l in product([h_line1, h_line2], [v_line1, v_line2])
					if (intersection := find_intersection_of_2_lines(h_l, v_l)) is not None
				]
			)

			if len(intersections) == 4:
				intersections[:2, 1] += 4
				intersections[-2:, 1] += 8
				all_x = intersections[:, 0]
				all_y = intersections[:, 1]

				# find x_min, x_max, y_min, y_max in intersections
				x_min, x_max = min(all_x), max(all_x)
				y_min, y_max = min(all_y), max(all_y)

				pts_dst = [[0, 0], [x_max - x_min, 0], [0, y_max - y_min], [x_max - x_min, y_max - y_min]]
				M = cv2.getPerspectiveTransform(np.float32(intersections), np.float32(pts_dst))
				dst = cv2.warpPerspective(img, M, (x_max - x_min, y_max - y_min))
				row.append({'name': r'Pic{}_row_{}_{}.jpg'.format(index_of_image, i, j), 'point': dst})

		if len(row) == 5:
			cells.append(row)

	return cells
