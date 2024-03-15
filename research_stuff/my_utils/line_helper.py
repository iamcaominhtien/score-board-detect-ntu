from math import atan2, degrees
from typing import Union

import numpy as np


def length_of_line(line) -> float:
	x1, y1, x2, y2 = line
	return np.sqrt(((x2 - x1) ** 2 + (y2 - y1) ** 2))


def find_intersection_of_2_lines(line1: np.ndarray, line2: np.ndarray) -> Union[np.ndarray, None]:
	"""
	This function calculates the intersection point of two lines in a 2D space.

	Args:
		line1 (np.ndarray): A numpy array representing the first line in the form (x1, y1, x2, y2),
		 where (x1, y1) and (x2, y2) are the coordinates of two points on the line.
		line2 (np.ndarray): A numpy array representing the second line in the form (x3, y3, x4, y4),
		 where (x3, y3) and (x4, y4) are the coordinates of two points on the line.

	Returns:
		np.ndarray: A numpy array [x, y] representing the intersection point of the
		two lines. If the lines are parallel or coincident (i.e., they do not intersect),
		 the function returns None.
	"""
	x1, y1, x2, y2 = line1.astype(np.float64)
	x3, y3, x4, y4 = line2.astype(np.float64)

	if (x1 == x2 and y1 == y2) or (x3 == x4 and y3 == y4):
		return None

	denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
	x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / denominator
	y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / denominator

	return np.array([x, y]).astype(int)


def line_slope_intercept(line: np.ndarray) -> tuple[Union[float, None], Union[float, None]]:
	"""
	This function calculates the slope and y-intercept of a line in a 2D space.

	Args:
		line (np.ndarray): A tuple representing the line in the form (x1, y1, x2, y2),
		 where (x1, y1) and (x2, y2) are the coordinates of two points on the line.

	Returns:
		tuple: A tuple (slope, intercept), where 'slope' is the slope of the line,
		 and 'intercept' is the y-intercept of the line. If the line is vertical
		 (x2 == x1), 'slope' is None and 'intercept' is the x-coordinate of the line.
	"""
	x1, y1, x2, y2 = line
	if x2 - x1 == 0:
		slope = None
		intercept = x1
	else:
		slope = (y2 - y1) / (x2 - x1)
		intercept = y1 - slope * x1
	return slope, intercept


def get_angle(line, rad=True) -> Union[float, None]:
	"""
	This function calculates the angle of a line in a 2D space.

	Args:
		line (tuple): A tuple representing the line in the form (x1, y1, x2, y2), where (x1, y1) and (x2, y2) are the coordinates of two points on the line.
		rad (bool, optional): A boolean value indicating whether the angle should be returned in radians. If False, the angle is returned in degrees. Defaults to True.

	Returns:
		Union[float, None]: The angle of the line in radians or degrees. If the line is vertical (x2 - x1 = 0), the function returns None.
	"""
	x1, y1, x2, y2 = line
	if x2 == x1:
		return None

	angle = atan2(y2 - y1, x2 - x1)
	return angle if rad else degrees(angle)


def crop_ver_and_hor_lines(vers, hors) -> tuple[np.ndarray, np.ndarray]:
	"""
	This function crops a set of vertical and horizontal lines to the intersection of the lines with the top, bottom,
	left, and right edges of the image.

	Args:
		vers: A list of tuples representing vertical lines. Each tuple has the form (x1, y1, x2, y2).
		hors: A list of tuples representing horizontal lines. Each tuple has the form (x1, y1, x2, y2).

	Returns: A tuple of two lists. The first list contains the cropped vertical lines, and the second list contains
	the cropped horizontal lines.
	"""
	# top, bottom = hors[0], hors[-1]
	# left, right = vers[0], vers[-1]

	cropped_ver_lines = [
		np.concatenate(
			[
				find_intersection_of_2_lines(line, hors[0]),
				find_intersection_of_2_lines(line, hors[-1]),
			],
			axis=0
		).astype(int)
		for line in vers
	] if hors.size else []

	cropped_hor_lines = [
		np.concatenate(
			[
				find_intersection_of_2_lines(line, vers[0]),
				find_intersection_of_2_lines(line, vers[-1]),
			],
			axis=0
		).astype(int)
		for line in hors
	] if vers.size else []

	return np.array(cropped_ver_lines).astype(int), np.array(cropped_hor_lines).astype(int)
