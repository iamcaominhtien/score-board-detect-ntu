import logging

import cv2
import numpy as np


class Cell456FindNumberPosition:
	HEIGHT = 220
	WIDTH = 361

	def __init__(self, image_data):
		self.data = image_data
		self.inv_threshold_image = None

	@staticmethod
	def it_is_no_point_symbol(image_original, debug=False):
		image = image_original.copy()
		if np.mean(image) < 30:
			return True
		image = cv2.resize(image, (361, 361), interpolation=cv2.INTER_CUBIC)
		_, threshold_image = cv2.threshold(
			image, 127, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU
		)

		_N = threshold_image.shape[0] - (50 - 1)
		number_of_each_triangle = _N * (_N - 1) // 2

		upper_triangle = np.triu(threshold_image[:, ::-1], k=50)
		upper_mean = np.sum(upper_triangle) / number_of_each_triangle

		lower_triangle = np.tril(threshold_image[:, ::-1], k=-50)
		lower_mean = np.sum(lower_triangle) / number_of_each_triangle

		if debug:
			logging.info(f"upper_mean: {upper_mean} - lower_mean: {lower_mean}")

		return (upper_mean < 25 and lower_mean < 25) or upper_mean < 6 or lower_mean < 6

	def _process_result(self, contours):
		original_height, original_width = self.data.shape
		scale_x = original_width / self.WIDTH
		scale_y = original_height / self.HEIGHT

		contours = np.array(
			[
				[x_min * scale_x, x_max * scale_x, y_min * scale_y, y_max * scale_y]
				for x_min, x_max, y_min, y_max in contours
			]
		).astype(int)
		return contours

	def _find_num_process_for_1(self, sorted_contours):
		if not sorted_contours \
			and self.it_is_no_point_symbol(self.inv_threshold_image):
			return []

		x, y, w, h = sorted_contours[0]
		x_min, y_min, x_max, y_max = x, y, x + w, y + h

		if self.it_is_no_point_symbol(
			self.inv_threshold_image[y_min: y_max, x_min: x_max]
		):
			return []

		middle_x = (x_min + x_max) // 2
		_pos = np.argmin(
			self.inv_threshold_image.
			mean(axis=0)
			[middle_x - 20: middle_x + 20]
		)
		contours = [
			[x_min, middle_x - 20 + _pos, y_min, y_max],
			[middle_x - 20 + _pos, x_max, y_min, y_max]
		]
		return self._process_result(contours)

	def _find_num_process_for_2(self, sorted_contours):
		x1, y1, w1, h1 = sorted_contours[0]
		x2, y2, w2, h2 = sorted_contours[1]
		if w1 > 0.8 * self.WIDTH and h1 > 0.4 * self.HEIGHT:
			return self._find_num_process_for_1([sorted_contours[0]])
		if w2 > 0.8 * self.WIDTH and h2 > 0.4 * self.HEIGHT:
			return self._find_num_process_for_1([sorted_contours[1]])
		# Check for overlap
		if x1 < x2 < x1 + w1 < x2 + w2:
			sorted_contours = [[x1, y1, x2 - x1, h1], [x2, y2, w2, h2]]

		crs = [[x, x + w, y, y + h] for x, y, w, h in sorted_contours]
		return self._process_result(crs)

	def _find_numbers_case_1(self, **kwargs):
		# case 1: when the 3 frames are nearly equal in height
		min_height = min(kwargs['h1'], kwargs['h2'], kwargs['h3'])
		if not (
			abs(kwargs['h1'] - min_height) < 20
			and abs(kwargs['h2'] - min_height) < 20
			and abs(kwargs['h3'] - min_height) < 20
		):
			return None
		# If there is any frame with width < 20 -> remove
		if kwargs['w3'] < 30:
			sorted_contours = [
				cv2.boundingRect(kwargs['first_contour']),
				cv2.boundingRect(kwargs['second_contour'])
			]
			return self._find_num_process_for_2(sorted_contours)
		if kwargs['w2'] < 30:
			sorted_contours = [
				cv2.boundingRect(kwargs['first_contour']),
				cv2.boundingRect(kwargs['third_contour'])
			]
			return self._find_num_process_for_2(sorted_contours)
		if kwargs['w1'] < 30:
			sorted_contours = [
				cv2.boundingRect(kwargs['second_contour']),
				cv2.boundingRect(kwargs['third_contour'])
			]
			return self._find_num_process_for_2(sorted_contours)
		for contour in kwargs['sorted_contours']:
			x, y, w, h = cv2.boundingRect(contour)
			cv2.rectangle(self.inv_threshold_image, (x, y), (x + w, y + h), (255, 255, 255), 5)
		crs = [[x, x + w, y, y + h] for x, y, w, h in kwargs['sorted_contours']]
		return self._process_result(crs)

	def _find_numbers_case_2(self, **kwargs):
		y2, y3 = kwargs['y2'], kwargs['y3']
		x2, x3 = kwargs['x2'], kwargs['x3']
		h1, h2, h3 = kwargs['h1'], kwargs['h2'], kwargs['h3']
		w2, w3 = kwargs['w2'], kwargs['w3']
		first_contour = kwargs['first_contour']

		# case 2: 2 rear frames, 1 upper 1 lower and total height ~ equal
		# to the height of the upper frame plus or minus 20 -> combine the 2 rear frames into 1
		if ((y2 < y3 and y2 + h2 < y3 + h3) or (y2 > y3 and y2 + h2 > y3 + h3)) \
			and abs(h1 - (h2 + h3)) < 20:
			x2_min, x2_max, y2_min, y2_max = x2, x2 + w2, y2, y2 + h2
			x3_min, x3_max, y3_min, y3_max = x3, x3 + w3, y3, y3 + h3
			x_min, x_max = min(x2_min, x3_min), max(x2_max, x3_max)
			y_min, y_max = min(y2_min, y3_min), max(y2_max, y3_max)
			merger_2_vs_3 = [x_min, y_min, x_max - x_min, y_max - y_min]
			sorted_contours = [cv2.boundingRect(first_contour), np.array(merger_2_vs_3)]
			return self._find_num_process_for_2(sorted_contours)

		return None

	def _find_numbers_case_3(self, **kwargs):
		sorted_contours = kwargs['sorted_contours']

		# case 3: choose 2 frames with the most suitable or largest area
		cords = list()
		for index, contour in enumerate(sorted_contours):
			# Get bounding box
			*_, w, h = cv2.boundingRect(contour)
			if h > 70 and w > 75:
				cords.append(index)
		if len(cords) == 2:
			sorted_contours = [
				cv2.boundingRect(sorted_contours[cords[0]]),
				cv2.boundingRect(sorted_contours[cords[1]]),
			]
			# Take out 2 frames with the most suitable area
			return self._find_num_process_for_2(sorted_contours)

		# Take out the 2 frames with the largest area
		sorted_contours = [cv2.boundingRect(contour) for contour in sorted_contours]
		areas = [w * h for _, _, w, h in sorted_contours]
		min_area_index = np.argmin(areas)
		x_min, y_min, _w_min, _h_min = sorted_contours[min_area_index]
		self.inv_threshold_image[y_min:y_min + _h_min, x_min:x_min + _w_min] = 0
		sorted_contours = [
			item for index, item in enumerate(sorted_contours)
			if index != min_area_index
		]
		return self._find_num_process_for_2(sorted_contours)

	def find_numbers(self):
		try:
			image = self.data.copy()
			image = cv2.resize(image, (self.WIDTH, self.HEIGHT), interpolation=cv2.INTER_CUBIC)
			image = cv2.dilate(image, np.ones((3, 3), np.uint8), iterations=8)
			_, threshold_image = cv2.threshold(image, 127, 255, cv2.THRESH_BINARY_INV)
			self.inv_threshold_image = 255 - threshold_image
			contours, _ = cv2.findContours(self.inv_threshold_image.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
			sorted_contours = sorted(contours, key=lambda _ctr: cv2.boundingRect(_ctr)[0])
			self.inv_threshold_image = cv2.erode(self.inv_threshold_image, np.ones((3, 3), np.uint8), iterations=8)

			if len(sorted_contours) == 1:
				sorted_contours = [cv2.boundingRect(_ctr) for _ctr in sorted_contours]
				return self._find_num_process_for_1(sorted_contours)
			if len(sorted_contours) == 2:
				sorted_contours = [cv2.boundingRect(_ctr) for _ctr in sorted_contours]
				return self._find_num_process_for_2(sorted_contours)
			if len(sorted_contours) > 2:
				sorted_contours = sorted(
					sorted_contours,
					key=lambda _ctr: cv2.boundingRect(_ctr)[0]
				)[:3]
				first_contour = sorted_contours[0]
				*_, w1, h1 = cv2.boundingRect(first_contour)
				second_contour = sorted_contours[1]
				x2, y2, w2, h2 = cv2.boundingRect(second_contour)
				third_contour = sorted_contours[2]
				x3, y3, w3, h3 = cv2.boundingRect(third_contour)

				if (
					results := self._find_numbers_case_1(
						h1=h1, h2=h2, h3=h3,
						w1=w1, w2=w2, w3=w3,
						first_contour=first_contour, second_contour=second_contour,
						third_contour=third_contour, sorted_contours=sorted_contours
					)
				) is not None:
					return results

				if (
					results := self._find_numbers_case_2(
						h1=h1, h2=h2, h3=h3, w2=w2, w3=w3,
						y2=y2, y3=y3, x2=x2, x3=x3,
						first_contour=first_contour
					)
				) is not None:
					return results

				return self._find_numbers_case_3(
					sorted_contours=sorted_contours
				)

			crs = [[x, x + w, y, y + h] for x, y, w, h in sorted_contours]
			return self._process_result(crs)
		except Exception as e:
			logging.error(f"Error when find number position: {e}")
			return []
