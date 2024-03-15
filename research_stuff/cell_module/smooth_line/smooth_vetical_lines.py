import cv2
import numpy as np

from cell_module import colors


def smooth_line_vertical(line_matrix, test=False):
	"""
	This function smooths vertical lines in an image.

	It first applies the Canny edge detection algorithm to the input image to detect edges.
	It then uses the Hough Line Transform to detect lines in the image.
	The detected lines are grouped and each group is merged into a single line.
	The lines are then stretched to the full height of the image and grouped again.
	The function draws the final lines on a copy of the input image.

	If the test parameter is True, the function also draws the initial detected lines on a copy of the input image
	and displays the input image, the image with the initial detected lines, and the image with the final lines.

	The function returns the image with the final lines and a numpy array of the final lines.

	Args:
		line_matrix (np.ndarray): The input image.
		test (bool, optional): Whether to draw the initial detected lines and display the images. Defaults to False.

	Returns:
		np.ndarray, np.ndarray: The image with the final lines and a numpy array of the final lines.
								Each line is represented as a 4-element array [x1, y1, x2, y2].
	"""
	height = line_matrix.shape[0]
	width = line_matrix.shape[1]
	dst = cv2.Canny(line_matrix, 50, 200, None, 3)

	# Copy edges to the images that will display the results in BGR
	bg_dark = np.zeros((height, width), np.uint8)
	line_detected = bg_dark.copy()
	cdst_p_stretch = bg_dark.copy()
	lines_p = cv2.HoughLinesP(dst, 1, np.pi / 180, 50, None, 50, height)

	if lines_p is None:
		return cdst_p_stretch, np.array([])
	probabilistic_lines = [l[0] for l in lines_p]

	# sort probabilistic_lines by y1, then group them and each group combine to 1 line
	probabilistic_lines.sort(key=lambda x: x[0])
	probabilistic_lines = np.array(probabilistic_lines)

	probabilistic_lines_cp = probabilistic_lines.copy()
	grouped_lines = group_vertical_lines(probabilistic_lines)
	probabilistic_lines_stretch = stretch_vertical_lines(grouped_lines, height)
	probabilistic_lines_stretch = group_vertical_lines(probabilistic_lines_stretch)
	for line in probabilistic_lines_stretch:
		cv2.line(cdst_p_stretch, (line[0], line[1]), (line[2], line[3]), colors.WHITE, 3, cv2.LINE_AA)

	if test:
		for line in probabilistic_lines_cp:
			cv2.line(line_detected, (line[0], line[1]), (line[2], line[3]), colors.WHITE, 3, cv2.LINE_AA)

		cv2.imshow("Source", cv2.resize(line_matrix, (480, 640)))
		cv2.imshow("Detected Lines", cv2.resize(line_detected, (480, 640)))
		cv2.imshow(
			"Detected Lines (in red) - Probabilistic Line - Stretch",
			cv2.resize(cdst_p_stretch, (480, 640))
		)
		cv2.waitKey(0)

	return cdst_p_stretch, probabilistic_lines_stretch


def group_vertical_lines(lines: np.ndarray, level: int = 15, unify: bool = True) -> np.ndarray:
	"""
	This function groups lines whose x1 distance is less than a specified level.

	It iterates over the provided lines and checks if the absolute difference between the x1 coordinate of each line
	and the x1 coordinate of each line in the current group is less than the specified level. If it is, the line is
	added to the current group. If it is not, a new group is created with the line.

	If the unify parameter is True, the function merges all the lines in each group into a single line by calling
	the merge_vertical_lines function.

	The function returns a numpy array of the grouped (and possibly merged) lines.

	Args:
		lines (np.ndarray): A numpy array of lines to group. Each line is represented as a 4-element array [x1, y1, x2, y2].
		level (int, optional): The maximum absolute difference in the x1 coordinate for lines to be considered part of the same group. Defaults to 15.
		unify (bool, optional): Whether to merge all the lines in each group into a single line. Defaults to True.

	Returns:
		np.ndarray: A numpy array of the grouped (and possibly merged) lines. Each line is represented as a 4-element array [x1, y1, x2, y2].
	"""
	if lines.size == 0:
		return np.array([], dtype=object)

	groups = [np.array([lines[0]])]
	for line_index in range(1, lines.shape[0]):
		line = lines[line_index]
		for index, group in enumerate(groups):
			if np.any(np.abs(group[:, 0] - line[0]) < level):
				groups[index] = np.append(group, [line], axis=0)
				break
		else:
			groups.append(np.array([line]))

	if unify:
		return merge_vertical_lines(np.array(groups, dtype=object))

	return np.array(groups, dtype=object)


def merge_vertical_lines(groups: np.ndarray) -> np.ndarray:
	"""
	This function merges groups of vertical lines into a single line per group.

	It calculates the slope (m) of each line in the group and averages them. If the average slope is negative,
	the function assumes the lines are decreasing and the start point of the merged line is the leftmost point
	(smallest x-coordinate) and the end point is the rightmost point (largest x-coordinate).
	If the average slope is non-negative, the start point is the rightmost point and the end point is the leftmost point.

	The function returns a numpy array of the merged lines, sorted by the x-coordinate of the start point.

	Args:
		groups (np.ndarray): A numpy array of groups of lines. Each group is a numpy array of lines,
							 and each line is a 4-element array [x1, y1, x2, y2].

	Returns:
		np.ndarray: A numpy array of the merged lines. Each line is a 4-element array [x1, y1, x2, y2].
	"""
	return_groups = list()
	for group in groups:
		y = np.sort(np.concatenate((group[:, 1], group[:, 3])))

		subtract_x = np.array([line[0] - line[2] for line in group])
		subtract_y = np.array([line[1] - line[3] for line in group])
		m = [
			subtract_y[i] / subtract_x[i]
			for i in range(len(subtract_x))
			if subtract_x[i] != 0
		]
		m_avg = np.average(m) if m else 0.0
		x = sorted(
			[
				np.average([line[0] for line in group]),
				np.average([line[2] for line in group])
			]
		)
		return_groups.append(
			[x[-1], y[0], x[0], y[-1]]
			if len(m) > 0 > m_avg
			else [x[0], y[0], x[-1], y[-1]]
		)
	return_groups.sort(key=lambda x: x[0])

	return np.array(return_groups).astype(int)


def stretch_vertical_lines(lines: np.ndarray, height: int) -> np.ndarray:
	"""
	This function stretches vertical lines to the full height of the image.

	It iterates over the provided lines and calculates the slope (m) and y-intercept (b) of each line. If the
	x-coordinates or the y-coordinates of the start and end points of the line are the same (indicating a horizontal
	or vertical line), the line is stretched vertically from y=0 to y=height, keeping the x-coordinate constant. For
	non-horizontal and non-vertical lines, the function calculates the x-coordinates of the start and end points of
	the stretched line using the equation of the line (x = (y - b) / m), where y is 0 for the start point and the
	height of the image for the end point.

	The function returns a numpy array of the stretched lines, each represented as a 4-element array [x1, y1, x2, y2].

	Args:
		lines (np.ndarray): A list of lines to stretch. Each line is represented as a 4-element array [x1, y1, x2, y2].
		height (int): The height of the image.

	Returns:
		np.ndarray: A numpy array of the stretched lines. Each line is a 4-element array [x1, y1, x2, y2].
	"""
	stretched_lines = list()
	for x_a, y_a, x_b, y_b in lines:
		if x_b != x_a and y_b != y_a:
			m = (y_b - y_a) / (x_b - x_a)
			b = y_a - m * x_a
			stretched_lines.append([-b / m, 0, (height - b) / m, height])
		else:
			stretched_lines.append([x_a, 0, x_b, height])

	return np.array(stretched_lines).astype(int)
