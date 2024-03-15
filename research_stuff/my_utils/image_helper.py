import re
from collections import deque

import cv2
import numpy as np

from cell_module import helper_function as helper


def get_grayscale(image):
	return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)


def thresholding(image: np.ndarray) -> np.ndarray:
	return cv2.threshold(image, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]


def mark_the_weight(image_original: np.ndarray, outlier_value: int) -> tuple[list, int, int]:
	"""
	This function marks the weight of the image by identifying and analyzing connected components in the image.
	It uses a breadth-first search algorithm to find connected components and considers a component as an object if it is large enough.

	Parameters:
	image_original (numpy.ndarray): The original image.
	outlier_value (int): The value representing outliers in the image.

	Returns:
	tuple: A tuple containing the following elements:
	- densities (list): A list of dictionaries. Each dictionary represents an object and contains the x and y coordinates of the object's pixels and the object's density (number of pixels).
	- height (int): The height of the image.
	- width (int): The width of the image.
	"""
	height, width = image_original.shape
	matrix = image_original.copy()
	densities = list()
	directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
	# Iterate over each pixel in the image
	for idx_y, idx_x in np.ndindex(height, width):
		if matrix[idx_y, idx_x] == outlier_value:
			continue
		path_x, path_y = [idx_x], [idx_y]
		queue = deque([(idx_y, idx_x)])

		# Perform a breadth-first search to find connected components
		while queue:
			y, x = queue.popleft()
			if matrix[y, x] == outlier_value:
				continue
			matrix[y, x] = outlier_value
			for dy, dx in directions:
				new_x, new_y = x + dx, y + dy
				if not (0 <= new_y < height and 0 <= new_x < width):
					continue
				if matrix[new_y, new_x] != outlier_value:
					queue.append((new_y, new_x))
					path_x.append(x)
					path_y.append(y)

		# Check if the connected component is large enough to be considered an object
		if len(path_x) > 20:
			densities.append(
				dict(
					dx=path_x, dy=path_y, density=len(path_x)
				)
			)
		else:
			image_original[path_y, path_x] = outlier_value
	return densities, height, width


def remove_ver_lines(image_original):
	"""
	This function removes vertical lines from an image.

	Parameters:
	image_original (numpy.ndarray): The input image from which vertical lines are to be removed.

	Returns:
	numpy.ndarray: The processed image with vertical lines removed.

	"""
	# Resize the image to twice its original size using Lanczos resampling.
	image = cv2.resize(
		src=image_original,
		dsize=(image_original.shape[1] * 2, image_original.shape[0] * 2),
		interpolation=cv2.INTER_LANCZOS4
	)
	# Get the width of the resized image.
	w_img = image.shape[1]
	# Create a 3x3 kernel of ones.
	kernel = np.ones((3, 3), np.uint8)
	# Dilate the inverted image using the kernel.
	dilated = cv2.dilate(255 - image, kernel, iterations=1)
	# Apply the Canny edge detection algorithm to the dilated image.
	edges = cv2.Canny(dilated, 50, 150)
	# Detect lines in the edge image using the Probabilistic Hough Line Transform.
	lines = cv2.HoughLinesP(
		image=edges, rho=1, theta=np.pi / 180,
		threshold=30, minLineLength=10, maxLineGap=10
	)

	# If lines are detected, process them.
	if lines is not None:
		angles = list()
		for line in lines:
			# Get the angle of the line.
			angle = helper.get_angle(line[0], False)
			if angle and abs(angle) > 90:
				angle = 180 - abs(angle)
			angles.append(angle)

		# Filter out the lines that are not vertical.
		ver_lines = [
			line[0] for line, angle in zip(lines, angles)
			if angle is None or abs(angle) >= 80
		]

		# Draw the vertical lines on the image.
		for x1, y1, x2, y2 in ver_lines:
			if (0.3 * w_img < x1 < 0.7 * w_img) or (0.3 * w_img < x2 < 0.7 * w_img):
				continue
			cv2.line(image, (x1, y1), (x2, y2), (255, 255, 255), 3)

	# Resize the image back to its original size using Lanczos resampling.
	image = cv2.resize(
		image,
		dsize=(int(image.shape[1] / 2), int(image.shape[0] / 2)),
		interpolation=cv2.INTER_LANCZOS4
	)

	return image


def get_digits_only(text):
	"""
	Preprocesses an image for tesseract OCR.

	Args:
		text (str): The text to be processed. (api.GetUTF8Text())

	Returns:
		str: The text with only digits.
	"""
	return ''.join(re.findall(r'\d+', text))


def shrink_image(image: np.ndarray) -> np.ndarray:
	"""
		Function to shrink an image.
		Args:
			image: The original image data.
		Returns:
			The shrunken image data.
	"""
	rows = np.any(image, axis=1)
	cols = np.any(image, axis=0)

	first_row = np.argmax(rows)
	last_row = image.shape[0] - np.argmax(np.flip(rows))
	first_col = np.argmax(cols)
	last_col = image.shape[1] - np.argmax(np.flip(cols))

	return image[first_row:last_row, first_col:last_col]


def extend_image(image_original: np.ndarray, space=3) -> np.ndarray:
	"""
		Function to extend an image.
		Args:
			image_original: The original image.
			space (int): The space to extend the image by.
		Returns:
			The extended image if successful, otherwise the original image.
	"""
	image = image_original.copy()
	h, w = image.shape[:2]
	default_value_parameter = (0, 0, 0)
	border_type = cv2.BORDER_CONSTANT

	if h > w:
		image = cv2.copyMakeBorder(
			image,
			top=space, bottom=space, left=0, right=0,
			borderType=border_type, value=default_value_parameter
		)
		subtract = h - w
		left = right = subtract // 2
		if left < 3:
			left = right = 3
		image = cv2.copyMakeBorder(
			image,
			0, 0, left, right,
			border_type, value=default_value_parameter
		)
	elif h < w:
		image = cv2.copyMakeBorder(
			image,
			0, 0, space, space,
			border_type, value=default_value_parameter
		)
		subtract = w - h
		top = bottom = subtract // 2
		if top < 3:
			top = bottom = 3
		image = cv2.copyMakeBorder(
			image,
			top, bottom, 0, 0,
			border_type, value=default_value_parameter
		)
	else:
		image = cv2.copyMakeBorder(
			image,
			space, space, space, space,
			border_type, value=default_value_parameter
		)

	return image if (image is not None) else image_original
