import cv2
import numpy as np

import module.helper_function as helper
from module import detect_table


def get_lines_table(image_pil):
    IMAGE = np.array(image_pil, dtype=np.uint8)
    H_DESTINATION = 1631
    W_DESTINATION = 1199

    h_raw, w_raw = IMAGE.shape[:2]
    if h_raw > 1500:
        IMAGE = cv2.resize(IMAGE, (W_DESTINATION, H_DESTINATION), interpolation=cv2.INTER_LANCZOS4)

    img_bin = helper.preprocess(IMAGE, 5)
    my_detect_table = detect_table.DetectTable(img_bin, IMAGE)

    horizontal_lines_filtered = my_detect_table.horizontal_lines.copy()
    if len(horizontal_lines_filtered) > 0:
        horizontal_lines_filtered = detect_table.filter_horizontal_lines(
            my_detect_table.horizontal_lines)

    vertical_lines_filtered = my_detect_table.vertical_lines.copy()
    if len(vertical_lines_filtered) > 0 and len(horizontal_lines_filtered) > 0:
        vertical_lines_filtered = detect_table.filter_vertical_lines(my_detect_table.vertical_lines,
                                                                     horizontal_lines_filtered)
    points = detect_table.cut_table_row_by_row(horizontal_lines_filtered, vertical_lines_filtered,
                                               IMAGE, img_bin,
                                               index_of_image=1)

    total_results = 5
    if points is not None:
        cropped_vertical_lines, cropped_horizontal_lines = helper.crop_ver_and_hor_lines(
            vertical_lines_filtered,
            horizontal_lines_filtered)

        total_results = total_results + (
                    cropped_horizontal_lines.size + cropped_vertical_lines.size)
        results = [total_results, IMAGE.shape[1], IMAGE.shape[0], cropped_vertical_lines.size,
                   cropped_horizontal_lines.size]

        results.extend(cropped_vertical_lines.flatten())
        results.extend(cropped_horizontal_lines.flatten())
        return results

    return [total_results, IMAGE.shape[1], IMAGE.shape[0], 0, 0]
