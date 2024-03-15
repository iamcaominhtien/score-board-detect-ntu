import cv2
import numpy as np
from cell_module import colors, helper_function as helper


def merger_horizontal_lines_groups_into_one(groups: np.ndarray) -> np.ndarray:
	"""
	This function merges groups of horizontal lines into a single line per group.

	It calculates the slope (m) of each line in the group and averages them. If the average slope is negative,
	the function assumes the lines are decreasing and the start point of the merged line is the topmost point
	(smallest y-coordinate) and the end point is the bottommost point (largest y-coordinate).
	If the average slope is non-negative, the start point is the bottommost point and the end point is the topmost point.

	The function returns a numpy array of the merged lines, sorted by the y-coordinate of the start point.

	Args:
		groups (np.ndarray): A numpy array of groups of lines. Each group is a numpy array of lines, and each line is
		 a 4-element array [x1, y1, x2, y2].

	Returns:
		np.ndarray: A numpy array of the merged lines. Each line is a 4-element array [x1, y1, x2, y2].
	"""
	return_groups = list()
	for group in groups:
		x = np.sort(np.concatenate((group[:, 0], group[:, 2])))

		subtract_x = np.array([line[0] - line[2] for line in group])
		subtract_y = np.array([line[1] - line[3] for line in group])
		m = [subtract_y[i] / subtract_x[i] for i in range(len(subtract_x)) if subtract_x[i] != 0]
		m_avg = np.average(m) if len(m) > 0 else 0.0
		y = sorted([np.average([line[1] for line in group]), np.average([line[3] for line in group])])

		return_groups.append(
			[x[0], y[-1], x[-1], y[0]]
			if len(m) > 0 > m_avg
			else [x[0], y[0], x[-1], y[-1]]
		)

	return_groups.sort(key=lambda x: x[1])
	return np.array(return_groups).astype(np.int64)


def is_group_ok(group: np.ndarray, level: float) -> bool:
	"""
	Checks if the group of lines is within the specified level.

	This function checks if the difference between the maximum and minimum y-coordinates of the start and end points
	of the lines in the group is within the specified level. If the difference is greater than the level for either
	the start or end points, the function returns False, indicating that the group is not okay. Otherwise, it returns
	True, indicating that the group is okay.

	Args:
		group (np.ndarray): The group of lines to check. Each line is represented as a 4-element array [x1, y1, x2, y2].
		level (float): The level within which the y-coordinates of the start and end points of the lines should be.

	Returns:
		bool: True if the group is okay, False otherwise.
	"""
	y1_min, y1_max = np.min(group[:, 1]), np.max(group[:, 1])
	y2_min, y2_max = np.min(group[:, 3]), np.max(group[:, 3])

	if y1_max - y1_min > level or y2_max - y2_min > level:
		return False

	return True


def group_horizontal_lines(lines: np.ndarray, level=15, unify=True) -> np.ndarray:
	"""
	Groups lines based on the y1 distance being less than a specified level.

	This function iterates over the provided lines and groups them based on the y1 distance.
	If the y1 distance is less than the specified level, the lines are grouped together.
	The function can either return the groups as they are or unify the lines in each group into a single line.

	Args:
		lines (np.ndarray): The list of lines to group. Each line is represented as a 4-element array [x1, y1, x2, y2].
		level (int): The level within which the y1 distance should be for the lines to be grouped together. Defaults to 15.
		unify (bool): Whether to unify the lines in each group into a single line. Defaults to True.

	Returns:
		np.ndarray: An array of the grouped lines. If unify is True, each group is represented by a single line.
					If unify is False, each group is an array of lines.
	"""
	if lines.size == 0:
		return np.array([], dtype=object)

	groups = [np.array([lines[0]])]
	for line_index in range(1, lines.shape[0]):
		line = lines[line_index]
		for index, group in enumerate(groups):
			if not is_group_ok(group, level):
				continue
			if np.any(np.abs(group[:, 1] - line[1]) < level):
				groups[index] = np.append(group, [line], axis=0)
				break
		else:
			groups.append(np.array([line]))

	if unify:
		# Now, in each group, combine all the lines to only 1 line
		return merger_horizontal_lines_groups_into_one(np.array(groups, dtype=object))
	return np.array(groups, dtype=object)


def stretch_horizontal_lines(lines: np.ndarray, width: int) -> np.ndarray:
	"""
	This function stretches horizontal lines to the full width of the image.

	It iterates over the provided lines and calculates the slope (m) and y-intercept (b) of each line. If the
	x-coordinates of the start and end points of the line are the same (indicating a vertical line), the line is
	skipped. For non-vertical lines, the function calculates the y-coordinates of the start and end points of the
	stretched line using the equation of the line (y = mx + b), where x is 0 for the start point and the width of the
	image for the end point. If the slope of the line is 0 (indicating a horizontal line), the y-coordinates of the
	start and end points of the original line are used for the stretched line.

	The function returns a numpy array of the stretched lines, each represented as a 4-element array [x1, y1, x2, y2].

	Args:
		lines (list): A list of lines to stretch. Each line is represented as a 4-element array [x1, y1, x2, y2].
		width (int): The width of the image.

	Returns:
		np.ndarray: A numpy array of the stretched lines. Each line is a 4-element array [x1, y1, x2, y2].
	"""
	stretched_lines = list()
	for x_a, y_a, x_b, y_b in lines:
		if x_a == x_b:
			continue
		m = (y_b - y_a) / (x_b - x_a)
		b = y_a - m * x_a

		stretched_lines.append(
			[0, b, width, m * width + b]
			if m != 0 else [0, y_a, width, y_b]
		)

	return np.array(stretched_lines).astype(int)


def smooth_line_horizontal(line_matrix, test=False):
	"""
	Smoothens the horizontal lines in the given image.

	This function applies the Canny edge detection algorithm to the input image and then uses the Hough Line Transform
	to detect lines in the image. The detected lines are then grouped based on their y1 distance. If the y1 distance is
	less than a specified level, the lines are grouped together. The function then merges the lines in each group into a
	single line and stretches the lines to the width of the image.

	Args:
		line_matrix (np.ndarray): The input image.
		test (bool, optional): If True, the function will display the original image, the detected lines, and the
							   smoothened lines. Defaults to False.

	Returns:
		tuple: A tuple containing the smoothened lines and the image with the smoothened lines.
	"""
	height, width = line_matrix.shape[:2]
	dst = cv2.Canny(line_matrix, 50, 200, None, 3)

	# Copy edges to the images that will display the results in BGR
	bg_dark = np.zeros((height, width), np.uint8)
	line_detected = bg_dark.copy()
	cdst_p_stretch = bg_dark.copy()

	# Apply Hough Line Transform to detect lines in the image
	lines_p = cv2.HoughLinesP(dst, 1, np.pi / 180, 50, None, 50, width)
	if lines_p is None:
		return cdst_p_stretch, np.array([])
	probabilistic_lines = [l[0] for l in lines_p]

	# sort probabilistic_lines by y1, then group them and each group combine to 1 line
	probabilistic_lines.sort(key=lambda x: x[1])
	probabilistic_lines = np.array(probabilistic_lines)
	probabilistic_lines_cp = probabilistic_lines.copy()

	# Merge lines temporarily, calculate lengths, filter data, and delete temporary lines.
	temp_grouped_lines = group_horizontal_lines(lines=probabilistic_lines, unify=False)
	temp_merge_lines = merger_horizontal_lines_groups_into_one(
		temp_grouped_lines
	)
	temp_merge_lines_length = [
		helper.length_of_line(line) for line in
		temp_merge_lines
	]
	analyze_data = helper.analyze_data_to_find_outliers(
		temp_merge_lines_length
	)
	outlier_index = analyze_data['outlier_index']
	median = analyze_data['median']
	if median is not None and median != -1:
		ratios = np.array(
			[
				temp_merge_lines_length[outlier_index_value] / median
				for outlier_index_value in outlier_index
			]
		)
		outlier_index = outlier_index[~((0.7 < ratios) & (ratios <= 1))]
	temp_filter_grouped_lines = temp_grouped_lines[outlier_index]
	temp_filter_grouped_lines_flatten = (
		np.concatenate(temp_filter_grouped_lines)
		if temp_filter_grouped_lines.size > 0
		else np.array([])
	).reshape(-1, 4)
	formal_probabilistic_lines = np.array(
		[
			line for line in probabilistic_lines
			if line not in temp_filter_grouped_lines_flatten
		]
	)

	# Stretch the lines to the full width of the image
	formal_grouped_lines = group_horizontal_lines(formal_probabilistic_lines)
	formal_grouped_lines_stretch = stretch_horizontal_lines(formal_grouped_lines, width)
	formal_grouped_lines_stretch = group_horizontal_lines(formal_grouped_lines_stretch)

	if test:
		for line in probabilistic_lines_cp:
			cv2.line(
				line_detected,
				(line[0], line[1]),
				(line[2], line[3]),
				colors.WHITE, 3, cv2.LINE_AA
			)

		window_size = (480, 640)
		cv2.imshow("Source", cv2.resize(line_matrix, window_size))
		cv2.imshow("Detected Lines", cv2.resize(line_detected, window_size))
		cv2.imshow(
			"Detected Lines (in red) - Probabilistic Line - Stretch",
			cv2.resize(cdst_p_stretch, window_size)
		)
		cv2.waitKey(0)

	return cdst_p_stretch, formal_grouped_lines_stretch
