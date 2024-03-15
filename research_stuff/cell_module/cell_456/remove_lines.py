from collections import defaultdict

import cv2
import numpy as np

from cell_module.detect_table.detect_table import DetectTable

PARAM_ROW_WHITENESS_THRESHOLD = 150
RULES = [
	{'top_kernel': 10, 'bot_kernel': 0, 'lateral_kernel': 2, 'threshold': 250, 'punish': 1},
	{'top_kernel': 0, 'bot_kernel': 10, 'lateral_kernel': 2, 'threshold': 250, 'punish': 1},
	{'top_kernel': 0, 'bot_kernel': 5, 'lateral_kernel': 0, 'threshold': 250, 'punish': 1.5},
	{'top_kernel': 5, 'bot_kernel': 0, 'lateral_kernel': 0, 'threshold': 250, 'punish': 1.5},
	{'top_kernel': 2, 'bot_kernel': 2, 'lateral_kernel': 2, 'threshold': 250, 'punish': 1.5}
]
MAX_LATERAL_KERNEL = max([rule['lateral_kernel'] for rule in RULES])
PARAM_VIOLATING_THRESHOLD = 2  # ! MUST BE UPDATED ALONG WITH 'rules'
PARAM_N_LOCAL_DEFENDERS = 3
PARAM_DEFENDING_SUCCESS_THRESHOLD = 2
PARAM_ERASE_KERNEL = {'top': 5, 'bot': 5, 'left': 0, 'right': 0}


def remove_horizontal_line(image_original: np.ndarray) -> np.ndarray:
	h, w = image_original.shape
	erode_kernel = np.ones((3, 3), np.uint8)
	image = image_original.copy()
	is_eroded = 0
	for index in range(3):
		# h_line_top_row = h_line_bottom_row = -1
		row_whiteness = image.mean(axis=1)
		row_whiteness_needed = np.nonzero(row_whiteness > PARAM_ROW_WHITENESS_THRESHOLD)[0]
		if len(row_whiteness_needed) == 0:
			break
		run_count = 0
		if index == 2:
			# im[h_line_top_row:h_line_bottom_row, :] = 0
			for _ in range(2):
				detect_table_instance = DetectTable(image, image)
				if len(detect_table_instance.horizontal_lines) == 0:
					break
				for x_min, y_min, x_max, y_max in detect_table_instance.horizontal_lines:
					y_min = max(0, y_min - 3)
					y_max = min(h, y_max + 3)
					image[y_min:y_max, x_min:x_max] = 0
			break
		while run_count < len(row_whiteness_needed) - 1:
			h_line_top_row = h_line_bottom_row = row_whiteness_needed[run_count]
			for run_count in range(run_count, len(row_whiteness_needed)):
				if row_whiteness_needed[run_count] - h_line_top_row > 20:
					break
				h_line_bottom_row = row_whiteness_needed[run_count]
			h_line_mid_row = int((h_line_bottom_row + h_line_top_row) / 2)
			if h_line_mid_row < 0:
				break

			image = cv2.morphologyEx(image, cv2.MORPH_ERODE, iterations=2, kernel=erode_kernel)
			is_eroded += 1
			image_temp = image.copy()
			violate_count_dict = defaultdict(int)
			for i in range(MAX_LATERAL_KERNEL, w - MAX_LATERAL_KERNEL):
				violate_count_dict[i] = 0
				# temp = list()
				for rule in RULES:
					lat_k = rule['lateral_kernel']
					top_k = rule['top_kernel']
					bot_k = rule['bot_kernel']
					threshold = rule['threshold']
					punish = rule['punish']
					y_min = h_line_mid_row - top_k
					y_max = h_line_mid_row + bot_k + 1
					x_min = i - lat_k
					x_max = i + lat_k + 1
					cropped_image = image_temp[y_min:y_max, x_min:x_max]
					window_mean = cropped_image.mean() if cropped_image.size else 0
					# temp.append(window_mean)
					if window_mean < threshold:
						violate_count_dict[i] += punish

			defender_low_bound = MAX_LATERAL_KERNEL
			defender_up_bound = w - 1 - MAX_LATERAL_KERNEL
			for i, cnt in violate_count_dict.items():
				if cnt >= PARAM_VIOLATING_THRESHOLD:
					defense_count = 0
					leftmost_defender = max(defender_low_bound, i - PARAM_N_LOCAL_DEFENDERS)
					rightmost_defender = min(defender_up_bound, i + PARAM_N_LOCAL_DEFENDERS)
					for j in range(leftmost_defender, rightmost_defender + 1):
						if violate_count_dict[j] < PARAM_VIOLATING_THRESHOLD:
							defense_count += 1
					if defense_count < PARAM_DEFENDING_SUCCESS_THRESHOLD:
						y_min = h_line_mid_row - PARAM_ERASE_KERNEL['top']
						y_max = h_line_mid_row + PARAM_ERASE_KERNEL['bot'] + 1
						x_min = i - PARAM_ERASE_KERNEL['left']
						x_max = i + PARAM_ERASE_KERNEL['right'] + 1
						image[y_min:y_max, x_min:x_max] = 0

	if is_eroded:
		for _ in range(is_eroded):
			image = cv2.morphologyEx(image, cv2.MORPH_DILATE, iterations=2, kernel=erode_kernel)
	return image


def remove_vertical_line(im: np.ndarray) -> np.ndarray:
	PARAM_LEFTMOST = 40
	return im[:, PARAM_LEFTMOST:]

