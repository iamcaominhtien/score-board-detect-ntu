import numpy as np

from cell_module import helper_function as helper, smooth_line
from cell_module.smooth_line.smooth_vetical_lines import stretch_vertical_lines


def filter_vertical_lines(ver_lines: np.ndarray, horizontal_lines: np.ndarray) -> np.ndarray:
	"""
	Filters vertical lines from a given list of vertical and horizontal lines.

	Args:
		ver_lines: A list of vertical lines represented as (x1, y1, x2, y2) tuples.
		horizontal_lines: A list of horizontal lines represented as (x1, y1, x2, y2) tuples.

	Returns:
		numpy.ndarray: An array of filtered vertical lines.
	"""
	# Define the left and right lines
	left_line, right_line = ver_lines[0], ver_lines[-1]

	# Calculate the center line
	center_line = (left_line + right_line) / 2  # only interested in the value of x

	# Calculate the quarter line
	quarter_line = (left_line + center_line) / 4  # only interested in the value of x

	# Initialize a list to store column spaces
	col_spaces = list()

	# Iterate over the vertical lines to calculate column spaces
	for i in range(2, len(ver_lines)):
		x1, y1, x11, y11 = ver_lines[i - 2]
		x2, y2, x22, y22 = ver_lines[i - 1]
		x3, y3, x33, y33 = ver_lines[i]

		# Calculate the average length of the lines
		d1 = np.average(
			[
				helper.length_of_line([x1, y1, x2, y2]),
				helper.length_of_line([x11, y11, x22, y22])
			]
		)
		d2 = np.average(
			[
				helper.length_of_line([x2, y2, x3, y3]),
				helper.length_of_line([x22, y22, x33, y33])]
		)

		# Append the absolute value of the ratio of d2 to d1 to the column spaces
		col_spaces.append(abs(d2 / d1))

	# Find cell 1 & 2 (line1, line2, line3)
	lines_1_2_3_6_7_8_9 = _find_cell_1_and_2(
		center_line=center_line,
		col_spaces=col_spaces,
		horizontal_lines=horizontal_lines,
		left_line=left_line,
		ver_lines=ver_lines,
		quarter_line=quarter_line
	)

	# Find cell 6, 7, 8 (line6, line7, line8, line9)
	lines_1_2_3_6_7_8_9 = _find_cel_6_and_7_and_8(
		col_spaces=col_spaces,
		center_line=center_line,
		ver_lines=ver_lines,
		lines_1_2_3_6_7_8_9=lines_1_2_3_6_7_8_9,
		horizontal_lines=horizontal_lines,
		left_line=left_line
	)

	# Return the filtered vertical lines
	return lines_1_2_3_6_7_8_9.astype(int)


def _find_cel_6_and_7_and_8(
		col_spaces, center_line, ver_lines: np.ndarray,
		lines_1_2_3_6_7_8_9: np.ndarray, horizontal_lines, left_line
) -> np.ndarray:
	"""
	Finds the cells 6, 7, and 8 from a given list of vertical lines and column spaces.

	Args:
		col_spaces (list): A list of column spaces.
		center_line: The center line.
		ver_lines: A list of vertical lines.
		lines_1_2_3_6_7_8_9: A list of lines for cells 1, 2, 3, 6, 7, 8, and 9.
		horizontal_lines: A list of horizontal lines.
		left_line: The left line.

	Returns:
		numpy.ndarray: An array of lines for cells 6, 7, and 8.
	"""
	# Iterate over the column spaces
	for i, value in enumerate(col_spaces):
		# If the value is not between 0.8 and 1.3 or the x-coordinate of the vertical line
		# is less than or equal to the x-coordinate of the center line, continue to the next iteration
		if not 0.8 < value < 1.3 or ver_lines[i][0] <= center_line[0]:
			continue

		# If the next column space is between 0.8 and 1.3, add the current and the next
		# three vertical lines to the array of lines for cells 1, 2, 3, 6, 7, 8, and 9
		if i + 4 < len(col_spaces) and 0.8 < col_spaces[i + 1] < 1.3:
			if len(lines_1_2_3_6_7_8_9) == 0:
				lines_1_2_3_6_7_8_9 = ver_lines[i:i + 4][:]
			else:
				lines_1_2_3_6_7_8_9 = np.append(
					lines_1_2_3_6_7_8_9, ver_lines[i:i + 4][:],
					axis=0
				)
			break

	# If the array of lines for cells 1, 2, 3, 6, 7, 8, and 9 contains less than 7 lines,
	# calculate the sixth, seventh, eighth, and ninth lines
	if len(lines_1_2_3_6_7_8_9) < 7:
		sixth_line = None
		for i, value in enumerate(col_spaces):
			if 0.8 < value < 1.3 and ver_lines[i][0] > center_line[0]:
				sixth_line = ver_lines[i]
				break

		if sixth_line is not None:
			seventh_line = list()
			eighth_line = list()
			ninth_line = list()
			x1 = sixth_line[0]

			for line in [horizontal_lines[0], horizontal_lines[-1]]:
				m, b = helper.line_slope_intercept(line)
				line_length = helper.length_of_line(line)
				delta_x_seventh = x1 + line_length * 0.0502
				delta_x_eighth = delta_x_seventh + line_length * 0.0502
				delta_x_ninth = delta_x_eighth + line_length * 0.0502
				seventh_line.extend([delta_x_seventh, (m * delta_x_seventh + b)])
				eighth_line.extend([delta_x_eighth, (m * delta_x_eighth + b)])
				ninth_line.extend([delta_x_ninth, (m * delta_x_ninth + b)])

			for line in ver_lines:
				if abs(line[0] - seventh_line[0]) < 10:
					seventh_line = line.copy()
					continue

				if abs(line[0] - eighth_line[0]) < 10:
					eighth_line = line.copy()
					continue

				if abs(line[0] - ninth_line[0]) < 10:
					ninth_line = line.copy()

			lines_6_7_8_9 = np.array([sixth_line, seventh_line, eighth_line, ninth_line])
			lines_6_7_8_9 = stretch_vertical_lines(lines_6_7_8_9, left_line[-1])
			lines_1_2_3_6_7_8_9 = np.append(lines_1_2_3_6_7_8_9, lines_6_7_8_9, axis=0)

	# If the array of lines for cells 1, 2, 3, 6, 7, 8, and 9 contains less than 7 lines, return an empty array
	if len(lines_1_2_3_6_7_8_9) < 7:
		return np.array([], dtype=int)

	# Return the array of lines for cells 6, 7, and 8
	return lines_1_2_3_6_7_8_9


def _find_cell_1_and_2(
		center_line, col_spaces, horizontal_lines: np.ndarray,
		left_line: np.ndarray, ver_lines: np.ndarray, quarter_line
) -> np.ndarray:
	"""
	Finds the cells 1 and 2 from a given list of vertical lines and column spaces.

	Args:
		center_line (numpy.ndarray): The center line.
		col_spaces (list): A list of column spaces.
		horizontal_lines: A list of horizontal lines.
		left_line: The left line.
		ver_lines: A list of vertical lines.
		quarter_line (numpy.ndarray): The quarter line.

	Returns:
		numpy.ndarray: An array of lines for cells 1 and 2.
	"""
	# Initialize an empty array to store the lines for cells 1, 2, 3, 6, 7, 8, and 9
	lines_1_2_3_6_7_8_9 = np.array([])

	# Iterate over the column spaces
	for i, value in enumerate(col_spaces):
		# If the value is not between 1.5 and 2.3 or the x-coordinate of the
		# vertical line is greater than or equal to the x-coordinate of the
		# center line, continue to the next iteration
		if (not 1.5 < value < 2.3) or ver_lines[i][0] >= center_line[0]:
			continue

		# If the x-coordinate of the next vertical line is less than the x-coordinate
		# of the quarter line --> add the current and the next two vertical lines to
		# the array of lines for cells 1, 2, 3, 6, 7, 8, and 9
		if i + 1 < len(col_spaces) and ver_lines[i + 1][0] < quarter_line[0]:
			lines_1_2_3_6_7_8_9 = ver_lines[i:i + 3][:]
			break

	# If the array of lines for cells 1, 2, 3, 6, 7, 8, and 9 contains less than 3 lines,
	# calculate the second and third lines
	if len(lines_1_2_3_6_7_8_9) < 3:
		# Initialize lists to store the second and third lines
		second_line = list()
		third_line = list()

		# Get the x-coordinate of the left line
		x1 = left_line[0]

		# Iterate over the first and last horizontal lines
		for line in [horizontal_lines[0], horizontal_lines[-1]]:
			# Calculate the slope and y-intercept of the line
			m, b = helper.line_slope_intercept(line)

			# Calculate the length of the line
			line_length = helper.length_of_line(line)

			# Calculate the x-coordinates of the second and third lines
			delta_x_second = x1 + line_length * 0.048
			delta_x_third = x1 + line_length * 0.1409

			# Add the x-coordinate and corresponding y-coordinate to the second and third lines
			second_line.extend([delta_x_second, (m * delta_x_second + b)])
			third_line.extend([delta_x_third, (m * delta_x_third + b)])

		# Iterate over the vertical lines
		for line in ver_lines:
			# If the absolute difference between the x-coordinate of the line and the
			# x-coordinate of the second line is less than 15, copy the line to the second line
			if abs(line[0] - second_line[0]) < 15:
				second_line = line.copy()
				continue

			# If the absolute difference between the x-coordinate of the line and the
			# x-coordinate of the third line is less than 15, copy the line to the third line
			if abs(line[0] - third_line[0]) < 15:
				third_line = line.copy()

		# Stretch the vertical lines and add them to the array of lines for cells 1, 2, 3, 6, 7, 8, and 9
		lines_1_2_3_6_7_8_9 = stretch_vertical_lines(
			np.array([left_line, second_line, third_line]), left_line[-1]
		)

	# Return the array of lines for cells 1 and 2
	return lines_1_2_3_6_7_8_9
