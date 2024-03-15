import json
from concurrent.futures import ThreadPoolExecutor
from os import path

import cv2
import numpy as np
import pandas as pd
import tensorflow as tf

import cell_module.helper_function as helper
from cell_module import cell_1, cell_2
from cell_module.cell_456.cell_456 import cell_456_process
from cell_module.detect_api.models import NumpyEncoder, PredictInformation
from cell_module.detect_table.cut_table_row_by_row import cut_table_row_by_row
from cell_module.detect_table.detect_table import DetectTable
from cell_module.detect_table.filter_lines.horizontal_lines import filter_horizontal_lines
from cell_module.detect_table.filter_lines.ver_lines import filter_vertical_lines
from my_utils.path_helper import path_trained_models


def pre_process_image(image_original: np.ndarray):
	"""
	This function preprocesses an image for table detection.

	It first checks the height of the image and resizes it if the height is greater than 1500.
	It then converts the image to a binary image and initializes a DetectTable object with the binary image and the original image.

	The function copies the horizontal and vertical lines detected by the DetectTable object.
	If there are any horizontal lines, it filters them.
	If there are any vertical lines and horizontal lines, it filters the vertical lines.

	The function then cuts the table in the image into rows by row using the filtered horizontal and vertical lines and returns the cells.

	Args:
		image_original (np.ndarray): The original image.

	Returns:
		list: A list of cells in the table. Each cell is represented as a dictionary with keys 'point', 'img', and 'img_bin'.
	"""
	h_raw, _ = image_original.shape[:2]
	if h_raw > 1500:
		image_original = cv2.resize(
			src=image_original,
			dsize=(1199, 1631),
			interpolation=cv2.INTER_LANCZOS4
		)

	img_bin = helper.convert_to_bin_image(image_original, 5)
	detect_table_tool = DetectTable(img_bin, image_original)

	# Copy the horizontal lines detected by the DetectTable object
	hor_lines = detect_table_tool.horizontal_lines.copy()
	if hor_lines.size:
		# Filter the horizontal lines
		hor_lines = filter_horizontal_lines(detect_table_tool.horizontal_lines)

	# Copy the vertical lines detected by the DetectTable object
	ver_lines = detect_table_tool.vertical_lines.copy()
	if ver_lines.size and hor_lines.size:
		# Filter the vertical lines using the horizontal lines
		ver_lines = filter_vertical_lines(
			detect_table_tool.vertical_lines,
			hor_lines
		)

	# Cut the table in the image into rows by row using the filtered horizontal and vertical lines
	cells = cut_table_row_by_row(hor_lines, ver_lines, image_original, img_bin)

	return cells


def load_model():
	"""
	This function loads a pre-trained model from a file.

	The function constructs the file path by joining the path to the directory of trained models and the file name.
	It then uses the load_model function from TensorFlow's Keras API to load the model from the file.

	The function returns the loaded model.

	Returns:
		tf.keras.Model: The loaded model.
	"""
	file_name = "neural_mnist_v5_hog_regularization.hdf5"
	file_path = path.join(path_trained_models(), file_name)
	model = tf.keras.models.load_model(file_path)
	return model


def detect_table_api(input_image: np.ndarray):
	"""
	This function detects a table in an input image and returns a DataFrame of predictions.

	It first loads a pre-trained model and preprocesses the input image for table detection.
	If no cells are detected in the image, it returns a JSON string with an error message.

	The function then processes each cell in the table and makes predictions for each cell.
	It uses a ThreadPoolExecutor to concurrently get the OCR results for cell 1 and cell 2.

	The function then predicts the classes of the numbers in the cells using the pre-trained model.
	It assigns the predicted classes to the corresponding cells.

	The function finally converts the predictions to a DataFrame and returns it.

	Args:
		input_image (np.ndarray): The input image.

	Returns:
		pd.DataFrame: A DataFrame of predictions. Each row represents a cell in the table and contains the following columns:
					  'stt', 'id', 'numbers', 'predicted'.
	"""
	# Load the pre-trained model
	neural_model_reg = load_model()

	# Preprocess the input image for table detection
	cells = pre_process_image(input_image)

	# If no cells are detected, return an error message
	if not cells:
		return json.dumps({'error': 'Cannot detect table', 'code': 'cdt'}, cls=NumpyEncoder)

	# Create a dictionary to store the predictions for each cell
	predictions = {
		idx: PredictInformation()
		for idx in range(len(cells))
	}

	# Get the OCR results for cell 1 and cell 2 using ThreadPoolExecutor
	numbers_predict = list()
	results = [
		[
			row_dict['point'] if col_num <= 1
			else cell_456_process(row_dict['point'])
			for col_num, row_dict in enumerate(row)
		]
		for row in cells
	]
	images_cell1 = [item[0] for item in results]
	images_cell2 = [item[1] for item in results]
	for idx, item in enumerate(results):
		numbers_of_row_col234 = [
			len(sub_item) if sub_item is not None else None
			for sub_item in item[2:5]
		]
		predictions[idx].numbers = numbers_of_row_col234
		for sub_item in item[2:5]:
			if sub_item:
				numbers_predict.extend(sub_item)

	# If no numbers are detected, return an error message
	if not numbers_predict:
		return json.dumps({'error': 'Cannot detect table', 'code': 'cdt'}, cls=NumpyEncoder)

	# Use ThreadPoolExecutor to get the OCR results for cell 1 and cell 2
	with ThreadPoolExecutor() as executor:
		cell_1_ocr, cell_2_ocr = executor.map(
			lambda func: func(), [
				lambda: cell_1.get_cells_number_one(images_cell1),
				lambda: cell_2.get_cells_2(images_cell2)
			]
		)

	# Assign the OCR results to the corresponding cells
	for idx in range(len(cell_1_ocr)):
		predictions[idx].stt = cell_1_ocr[idx]
		predictions[idx].id = cell_2_ocr[idx]

	# Predict the classes of the numbers in the cells using the pre-trained model
	predicted_classes = np.argmax(
		neural_model_reg.predict(helper.hog_feature_extraction(numbers_predict)), axis=1
	)
	predicted_iterator = iter(predicted_classes)
	for idx in range(len(cells)):
		if predictions[idx].numbers:
			predictions[idx].predicted = [
				[next(predicted_iterator) for _ in range(number_of_digit)]
				for number_of_digit in predictions[idx].numbers
			]

	# Convert the predictions to a DataFrame and return it
	final_predictions = [predict.to_dict() for predict in predictions.values()]
	return pd.DataFrame(final_predictions)
