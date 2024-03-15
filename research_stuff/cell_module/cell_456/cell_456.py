from collections import deque

import cv2
import matplotlib.pyplot as plt
import numpy as np

from cell_module.cell_456.find_number_position import Cell456FindNumberPosition
from cell_module.cell_456.remove_lines import remove_horizontal_line, remove_vertical_line
from my_utils.image_helper import extend_image, shrink_image


def remove_background(image_original: np.ndarray) -> np.ndarray:
	"""
		Function to remove the background from an image.
		Args:
			image_original (np.ndarray): The original image.
		Returns:
			np.ndarray: The image with the background removed.
	"""
	inv_image = ~image_original  # Make black background
	inv_image = cv2.GaussianBlur(inv_image, (3, 3), 0)
	_, threshold_image = cv2.threshold(inv_image, 100, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

	threshold_image = remove_vertical_line(threshold_image)
	threshold_image = remove_horizontal_line(threshold_image)
	return threshold_image


NOISE_FILTER_DIRECTIONS = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, 1), (1, -1), (-1, -1)]


def noise_filter(image_original: np.ndarray, show_result=False) -> np.ndarray:
	"""
		Function to remove noise from an image.
		Args:
			image_original: The original image.
			show_result (bool): Whether to show the result or not.
		Returns:
			The image after noise removal.
	"""
	matrix = image_original.copy()
	image = image_original.copy()
	height, width = image_original.shape[:2]

	paths_x = list()
	paths_y = list()

	for idx_y, idx_x in np.ndindex(height, width):
		if matrix[idx_y, idx_x] == 0:
			continue

		# Initialize the queue and mark the starting point
		queue = deque([(idx_y, idx_x)])
		matrix[idx_y][idx_x] = 0
		path_x, path_y = [idx_y], [idx_x]

		# Loop through the queue
		while queue:
			# Get the first point in the queue
			x, y = queue.popleft()

			# Browse neighboring points (including diagonals)
			for dx, dy in NOISE_FILTER_DIRECTIONS:
				new_x, new_y = x + dx, y + dy

				# Check if the point is in the matrix and has value != 0 or not
				# if h_img > nx >= 0 != matrix[nx][ny] and 0 <= ny < w_img:
				if 0 <= new_x < height and 0 <= new_y < width and matrix[new_x][new_y] != 0:
					# Mark the point and add it to the queue
					matrix[new_x][new_y] = 0
					queue.append((new_x, new_y))

					# Save the new position trace to the array
					path_x.append(new_x)
					path_y.append(new_y)

		if len(path_x) < 30:
			image[path_x, path_y] = 0
		else:
			paths_x.append(path_x)
			paths_y.append(path_y)

	# zoom image
	space = 2
	rows, cols = np.nonzero(image)
	if len(rows) == 0:
		rows = np.array([0, height])
	if len(cols) == 0:
		cols = np.array([0, width])
	y_min = max(np.min(rows) - space, 0)
	y_max = min(np.max(rows) + space, height)
	x_min = max(np.min(cols) - space, 0)
	x_max = min(np.max(cols) + space, width)

	image = image[y_min:y_max, x_min:x_max]

	if show_result:
		plt.imshow(image)

	return image


def cell_456_process(image_original: np.ndarray) -> list[np.ndarray]:
	"""
		Function to process an image.
		Args:
			image_original: The original image.
		Returns:
			A list of processed numbers from the image.
	"""
	image_2d = image_original.copy()
	if image_2d.ndim > 2:
		image_2d = cv2.cvtColor(image_2d, cv2.COLOR_BGR2GRAY)
	img_resized = cv2.resize(image_2d, (361, 220), interpolation=cv2.INTER_CUBIC)
	img_not_background = remove_background(img_resized)
	img_not_background = cv2.resize(
		img_not_background, (image_2d.shape[1], image_2d.shape[0]),
		interpolation=cv2.INTER_LANCZOS4
	)
	img_not_background = noise_filter(img_not_background)
	pic_frames = Cell456FindNumberPosition(img_not_background).find_numbers()
	numbers = [
		img_not_background[_y_min:_y_max, _x_min:_x_max]
		for _x_min, _x_max, _y_min, _y_max in pic_frames
	]
	numbers_beauty = [extend_image(shrink_image(number)) for number in numbers]
	numbers_threshold = [
		cv2.threshold(
			number, thresh=127, maxval=255,
			type=cv2.THRESH_BINARY + cv2.THRESH_OTSU
		)[1] for number in numbers_beauty
	]

	return numbers_threshold
