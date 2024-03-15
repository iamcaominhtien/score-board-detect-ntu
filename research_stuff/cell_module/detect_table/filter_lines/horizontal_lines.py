from math import floor

import numpy as np

from cell_module import helper_function as helper


def custom_round(number):
	value = floor(number) \
		if number - floor(number) >= 0.5 \
		else floor(number) - 1
	return value if value > 0 else 0


def filter_horizontal_lines(lines_original):
	"""
	Filters horizontal lines from a given list of lines.

	Args:
		lines_original (list): A list of lines represented as (x1, y1, x2, y2) tuples.

	Returns:
		numpy.ndarray: An array of filtered horizontal lines.
	"""
	# Convert the list of lines to a numpy array
	lines = np.array(lines_original)

	# Remove outliers from the lines based on their angles
	lines = _remove_outliers(lines)

	# Initialize lists to store row spaces and their multiples
	row_spaces_multiple = list()
	row_spaces = list()

	# Iterate over the lines to calculate row spaces and their multiples
	for i in range(1, len(lines)):
		x1, y1, x2, y2 = lines[i - 1]
		_, y3, _, y4 = lines[i]
		row_spaces_multiple.append(abs(y1 - y3) * abs(y2 - y4))
		row_spaces.append(abs(np.average([y1, y2]) - np.average([y3, y4])))

	# Analyze the row spaces multiples to find outliers
	check_outlier = helper.analyze_data_to_find_outliers(row_spaces_multiple)
	clean_index = check_outlier['clean_index']

	# Initialize a list to store the horizontal lines
	horizontal_lines = [False for _ in range(len(lines))]

	# Mark the lines in the clean index as horizontal
	for idx in clean_index:
		horizontal_lines[idx] = horizontal_lines[idx + 1] = True

	# Calculate the median of the row spaces
	median = np.percentile(row_spaces, 50)

	# Filter the horizontal lines
	filter_horizontal_lines = np.array(lines)[horizontal_lines]

	# If the median is None, return the filtered horizontal lines
	if median is None:
		return filter_horizontal_lines

	# Iterate over the filtered horizontal lines to further refine them
	for idx in range(len(filter_horizontal_lines) - 2, -1, -1):
		x1, y1, x2, y2 = filter_horizontal_lines[idx]
		_, y3, _, y4 = filter_horizontal_lines[idx + 1]
		dy1 = abs(y1 - y3)
		dy2 = abs(y2 - y4)

		if not (dy1 / median > 1.5 or dy2 / median > 1.5):
			continue

		# Calculate the number of new lines to be added
		number_of_new_lines = max(custom_round(dy1 / median), custom_round(dy2 / median))

		# Calculate the space between the y-coordinates of the lines
		space_y13 = abs(y1 - y3) / (number_of_new_lines + 1)
		space_y24 = abs(y2 - y4) / (number_of_new_lines + 1)

		# Add the new lines to the filtered horizontal lines
		for i in range(number_of_new_lines):
			filter_horizontal_lines = np.insert(
				filter_horizontal_lines,
				idx + i + 1,
				[x1, y1 + (i + 1) * space_y13, x2, y2 + (i + 1) * space_y24],
				axis=0
			)

	# Return the final filtered horizontal lines
	return filter_horizontal_lines


def _remove_outliers(lines: np.ndarray) -> np.ndarray:
	"""
	Remove outliers from a list of lines based on their angles.

	Args:
		lines (numpy.ndarray): An array of lines.

	Returns:
		numpy.ndarray: The array of lines with outliers removed.
	"""
	angles = [helper.get_angle(line, rad=False) for line in lines]
	check_outlier = helper.analyze_data_to_find_outliers(angles)
	median = check_outlier['median']
	outlier_index = check_outlier['outlier_index']

	if median is None:
		return lines

	for idx in range(len(outlier_index) - 1, -1, -1):
		if abs(angles[outlier_index[idx]] - median) > 1:
			lines = np.delete(lines, outlier_index[idx], axis=0)
	return lines
