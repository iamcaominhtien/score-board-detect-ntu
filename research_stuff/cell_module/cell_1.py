import cv2
import numpy as np
from PIL import Image
from tesserocr import PSM, PyTessBaseAPI

from my_utils.image_helper import get_digits_only, get_grayscale, \
	mark_the_weight, remove_ver_lines, thresholding
from my_utils.path_helper import path_tessdata


def remove_outliers(image_original, outlier_value=0):
	"""
	Remove outliers from an image and return the number of detected objects, the processed image, and a flag
	indicating if only one object was detected.

	Parameters:
	image_original (numpy.ndarray): The original image.
	outlier_value (int): The value representing outliers in the image. Default is 0.

	Returns:
	tuple: A tuple containing the following elements:
		- num_objects (int): The number of detected objects.
		- processed_image (numpy.ndarray): The processed image with outliers removed.
		- only_one (bool): A flag indicating if only one object was detected.
	"""
	densities, height, width = mark_the_weight(image_original, outlier_value)

	# Sort the detected objects by density in descending order
	densities = sorted(densities, key=lambda x: x['density'], reverse=True)
	max_densities = list()
	for density in densities:
		x_min, x_max = min(density['dx']), max(density['dx'])
		y_min, y_max = min(density['dy']), max(density['dy'])
		w = x_max - x_min
		h = y_max - y_min

		# Filter out objects that are too large or too small
		if w / width > 0.9 or h / height > 0.9 or h < 10:
			continue
		else:
			max_densities.append(
				dict(
					density=density, left=x_min, right=x_max, height=h
				)
			)

	# Sort the remaining objects by their left coordinate
	max_densities = sorted(max_densities, key=lambda x: x['left'])

	# If no objects are detected, use the first density as a fallback
	if not max_densities:
		max_densities = [densities[0]]
	else:
		# Filter out objects that don't meet certain height criteria
		median_height = np.median(
			np.array([item['height'] for item in max_densities])
		)
		max_densities = [
			item for item in max_densities
			if (10 < item['height'] <= 0.9 * height)
			and (median_height - 4 <= item['height'] <= median_height + 4)
		]

		# Check for overlapping objects and keep only the non-overlapping ones
		status = [False for _ in range(len(max_densities))]
		for idx in range(1, len(max_densities)):
			space = max_densities[idx]['left'] - max_densities[idx - 1]['right']
			if 0 < space <= 10:
				status[idx] = status[idx - 1] = True

		max_densities = [
			item['density']
			for item, stt in zip(max_densities, status) if stt
		]

		# Limit the number of detected objects to at most 3
		if len(max_densities) > 3:
			max_densities = max_densities[:3]
		elif len(max_densities) == 0:
			max_densities = [densities[0]]

	# Extract the coordinates of the detected objects
	all_dx = np.concatenate([item['dx'] for item in max_densities])
	all_dy = np.concatenate([item['dy'] for item in max_densities])
	x_min, x_max = min(all_dx), max(all_dx)
	y_min, y_max = min(all_dy), max(all_dy)

	# Crop the original image to the region containing the detected objects
	image = image_original[y_min:y_max + 1, x_min:x_max + 1]

	# Extend the image by concatenating two copies if only one object is detected
	only_one = len(max_densities) == 1
	if only_one:
		image = np.concatenate((image, image), axis=1)

	return len(max_densities), image, only_one


def pre_process_image(image_original):
	gray = get_grayscale(image_original)
	thresh = thresholding(gray)
	thresh = remove_ver_lines(thresh)

	blurred = cv2.GaussianBlur(thresh, (3, 3), 0)
	im_bw = cv2.adaptiveThreshold(
		blurred,
		maxValue=255,
		adaptiveMethod=cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
		thresholdType=cv2.THRESH_BINARY_INV,
		blockSize=15,
		C=8
	)  # Nhi phan anh
	number_of_digits, im_bw_rm, only_one = remove_outliers(im_bw)

	return number_of_digits, thresh, im_bw_rm, only_one


def change_size_image(image_original, min_size):
	h_img, w_img = image_original.shape
	if h_img < w_img:
		ratio_img = min_size / h_img
	else:
		ratio_img = min_size / w_img
	img = cv2.resize(
		image_original, (int(image_original.shape[1] * ratio_img), int(image_original.shape[0] * ratio_img)),
		interpolation=cv2.INTER_LANCZOS4
	)
	img = cv2.threshold(img, 50, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]
	return img


def get_cells_number_one(images):
	results = ['' for _ in range(len(images))]
	with PyTessBaseAPI(path=path_tessdata()) as api:
		api.SetPageSegMode(PSM.SINGLE_BLOCK)
		for idx, image in enumerate(images):
			number_of_digits, thresh, im_bw_rm, only_1 = pre_process_image(image)
			im_bw_rm = cv2.threshold(im_bw_rm, 50, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]
			h_imb_bin, w_imb_bin = im_bw_rm.shape
			size = min(h_imb_bin, w_imb_bin)
			for _ in range(10):
				if 20 < size <= 100:
					pil_image = Image.fromarray(change_size_image(im_bw_rm, size))
				elif size <= 20:
					pil_image = Image.fromarray(im_bw_rm)
				else:
					for _image in [im_bw_rm, thresh]:
						api.SetImage(Image.fromarray(_image))
						text = get_digits_only(api.GetUTF8Text())
						if len(text) >= number_of_digits:
							break
					break
				api.SetImage(pil_image)
				text = get_digits_only(api.GetUTF8Text())
				if len(text) >= number_of_digits:
					if only_1:
						if len(text) == 2 and text[0] == text[1]:
							break
						else:
							size += 20
					else:
						break
				else:
					size += 20
			if only_1:
				_text = text if len(text) <= 1 else text[0]
				results[idx] = _text
			else:
				results[idx] = text

	for i in range(1, len(results) - 1):
		_prev_number = results[i - 1]
		_number = results[i]
		_next_number = results[i + 1]
		if _prev_number != '' and _next_number != '':
			_prev_number = int(_prev_number)
			_next_number = int(_next_number)
			if ((_number == '') or (int(_number) != _prev_number + 1 and int(
					_number
			) != _next_number - 1)) and (_prev_number + 2 == _next_number):
				results[i] = str(_prev_number + 1)

	return results
