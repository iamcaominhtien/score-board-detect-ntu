import logging

import cv2
import numpy as np
from PIL import Image

from tesserocr import PyTessBaseAPI

import cell_module.detect_table as dt
# import cell_module.helper_function as helper
from cell_module.detect_table.detect_table import DetectTable
from my_utils.image_helper import get_digits_only, get_grayscale, \
	mark_the_weight, remove_ver_lines, thresholding
from my_utils.line_helper import get_angle
from my_utils.path_helper import path_tessdata


def remove_outliers(image_original: np.ndarray, outlier_value=0) -> np.ndarray:
	"""
	Removes outliers from an image.

	Args:
		image_original (numpy.ndarray()): The image to remove outliers from.
		outlier_value (int): The value to replace outliers with.

	Returns:
		numpy.ndarray(): The image with outliers removed.
	"""
	densities, height, width = mark_the_weight(image_original, outlier_value)

	new_density = list()
	for dict_item in densities:
		path_x, path_y = dict_item['dx'], dict_item['dy']
		x_min, x_max = min(path_x), max(path_x)
		y_min, y_max = min(path_y), max(path_y)

		# check if the height of zone is too small, with of zone is too small or too large
		if (
				(y_max - y_min) < 0.1 * height
				or (y_max - y_min) > 0.8 * height
				or (y_max - y_min) < 10
				or (x_max - x_min) > 0.5 * width
		):
			image_original[path_y, path_x] = outlier_value
		else:
			dict_item['height'] = y_max - y_min
			new_density.append(dict_item)

	height_of_zones = [dict_item['height'] for dict_item in new_density]
	if len(height_of_zones) <= 8:
		return image_original

	space = 3
	outlier_index = None
	for _ in range(100):
		median_height = np.median(height_of_zones)
		outlier_index = np.nonzero(
			(height_of_zones > median_height + space) | (height_of_zones < median_height - space)
		)[0]
		if len(outlier_index) > 0 and (len(height_of_zones) - len(outlier_index) > 8):
			space -= 1
			if space > 0:
				continue
		if len(outlier_index) > 0 and (len(height_of_zones) - len(outlier_index) < 8):
			space += 1
			if space < 6:
				continue

	if outlier_index:
		for idx in outlier_index:
			dict_item: dict = new_density[idx]
			path_x, path_y = dict_item['dx'], dict_item['dy']
			image_original[path_y, path_x] = outlier_value

	return image_original


def preprocess_image(image_original: np.ndarray) -> np.ndarray:
	"""
	Preprocesses an image for tesseract OCR.

	Args:
		image_original (numpy.ndarray()): The image to be processed.

	Returns:
		pil_image (PIL.Image()): The processed image.
	"""
	gray2 = get_grayscale(image_original)
	thresh2 = thresholding(gray2)
	thresh2 = remove_ver_lines(thresh2)
	detect_table_instance = DetectTable(thresh2, image_original)

	# remove horizontal lines from image
	h_thresh, w_thresh = thresh2.shape
	for x1, y1, x2, y2 in detect_table_instance.horizontal_lines:
		angle = get_angle((x1, y1, x2, y2), False)
		if angle is not None and abs(angle) > 90:
			angle = 180 - abs(angle)
		if (angle is None or abs(angle) <= 10) \
				and ((0.4 * h_thresh < y1 < 0.6 * h_thresh) or (0.4 * h_thresh < y2 < 0.6 * h_thresh)):
			cv2.line(thresh2, (x1, y1), (x2, y2), (255, 255, 255), 2)

	# remove vertical lines from image
	for x1, y1, x2, y2 in detect_table_instance.vertical_lines:
		angle = get_angle((x1, y1, x2, y2), False)
		if angle is not None and abs(angle) > 90:
			angle = 180 - abs(angle)
		if (angle is None or abs(angle) >= 80) \
				and ((0.3 * w_thresh < x1 < 0.7 * w_thresh) or (0.0 * w_thresh < x2 < 0.7 * w_thresh)):
			cv2.line(thresh2, (x1, y1), (x2, y2), (255, 255, 255), 2)

	blurred = cv2.GaussianBlur(thresh2, (1, 1), 0)
	im_bw = cv2.adaptiveThreshold(
		blurred,
		maxValue=255,
		adaptiveMethod=cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
		thresholdType=cv2.THRESH_BINARY_INV,
		blockSize=15, C=8
	)
	im_bw = remove_outliers(im_bw, 0)

	return im_bw


def get_cells_2_old(images_list: list[np.ndarray]) -> list[str]:
	student_ids_ocr = ['' for _ in images_list]
	with PyTessBaseAPI(path=path_tessdata()) as api:
		for img_idx, image_original in enumerate(images_list):
			im_bw = preprocess_image(image_original)
			min_size = 20
			temp_text_detections = ['']
			while min_size <= 80:
				pil_image = Image.fromarray(
					cv2.resize(
						im_bw,
						dsize=(min_size * 3, min_size),
						interpolation=cv2.INTER_LANCZOS4
					)
				)
				api.SetImage(pil_image)
				text_detection = get_digits_only(api.GetUTF8Text())
				if len(text_detection) == 8:
					temp_text_detections = [text_detection]
					break
				else:
					min_size += 10
					if text_detection:
						temp_text_detections.append(text_detection)
			text = max(temp_text_detections, key=len)
			student_ids_ocr[img_idx] = text
	return student_ids_ocr


def preprocess_cell2(gray_image_original: np.ndarray) -> np.ndarray:
	try:
		gray_image = gray_image_original.copy()
		gray_image = ~gray_image  # Make black background
		gray_image = cv2.GaussianBlur(gray_image, (3, 3), 0)
		_, threshold_image = cv2.threshold(gray_image, 100, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

		threshold_image = cv2.resize(threshold_image, (700, 250), interpolation=cv2.INTER_CUBIC)
		threshold_image = cv2.dilate(threshold_image, np.ones((3, 3), np.uint8), iterations=1)
		_, threshold_image = cv2.threshold(threshold_image, 127, 255, cv2.THRESH_BINARY_INV)
		inv_threshold_image = 255 - threshold_image

		contours, _ = cv2.findContours(inv_threshold_image.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
		sorted_contours = sorted(contours, key=lambda _ctr: cv2.boundingRect(_ctr)[0])
		inv_threshold_image_cp = inv_threshold_image.copy()

		_tk = []
		for _ctr in sorted_contours:
			x, y, w, h = cv2.boundingRect(_ctr)
			if h > 90 and w > 37:
				_tk.append([x, y, w, h])
		y_median = np.median([y for _, y, *_ in _tk])
		h_median = np.median([h for *_, h in _tk])

		_bien = y_median + h_median
		_tk = [
			[x, y, w, int(_bien - y)] if y + h > _bien
			else [x, y, w, h]
			for x, y, w, h in _tk
		]

		# remove outlier: if abs(y-y_median) > 20 or abs(h-h_median) > 20
		_tk = [
			t for t in _tk
			if abs(t[1] - y_median) < 20 and abs(t[3] - h_median) < 20
		]

		th_x_min = min([x for x, *_ in _tk])
		th_x_max = max([x + w for x, _, w, _ in _tk])
		th_y_min = min([y for _, y, *_ in _tk])
		th_y_max = max([y + h for _, y, _, h in _tk])
		thresh_shrink = inv_threshold_image_cp[th_y_min:th_y_max, th_x_min:th_x_max]
		thresh_extend = cv2.copyMakeBorder(
			thresh_shrink,
			top=50, bottom=50, left=50, right=50,
			borderType=int(cv2.BORDER_CONSTANT),
			value=(0, 0, 0)
		).astype(np.uint8)

		return thresh_extend
	except Exception as e:
		logging.error(f'Error in preprocess_cell2: {e}')
		return gray_image_original


def get_cells_2(images: list[np.ndarray]) -> list[str]:
	text_detections = list()
	gray_images = [
		preprocess_cell2(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY))
		for img in images
	]
	with PyTessBaseAPI(path=path_tessdata()) as api:
		for gray_image in gray_images:
			subtract_val = 0
			optimize_text = ''
			h, w = gray_image.shape

			while h - subtract_val > 0 and w - subtract_val > 20:
				if subtract_val > 0:
					h -= subtract_val
					w -= subtract_val
					gray_image = cv2.resize(gray_image, (w, h), interpolation=cv2.INTER_LANCZOS4)
				pil_image = Image.fromarray(gray_image)
				api.SetImage(pil_image)
				text_detection = ''.join(get_digits_only(api.GetUTF8Text()))
				if len(text_detection) >= 8:
					optimize_text = text_detection
					break
				if len(text_detection) > len(optimize_text):
					optimize_text = text_detection
				subtract_val += 20
			text_detections.append(optimize_text)
	return text_detections
