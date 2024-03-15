import math
import os
import re
from collections import deque

import cv2
import numpy as np
import tflite_runtime.interpreter as tflite

import module.cell_456 as cell_456
# import matplotlib.pyplot as plt
import module.detect_table as dt
import module.helper_function as helper


# get grayscale image
def get_grayscale(image):
    return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)


# thresholding
def thresholding(image):
    return cv2.threshold(image, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]


def remove_outliers(IMAGE, outlier_value=0):
    """
    Removes outliers from an image.

    Args:
        IMAGE (numpy.ndarray()): The image to remove outliers from.
        outlier_value (int): The value to replace outliers with.

    Returns:
        numpy.ndarray(): The image with outliers removed.
    """
    height, width = IMAGE.shape
    matrix = IMAGE.copy()
    densities = []
    directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]

    for idx_y in range(height):
        for idx_x in range(width):
            if matrix[idx_y, idx_x] == outlier_value:
                continue
            path_x, path_y = [idx_x], [idx_y]
            queue = deque([(idx_y, idx_x)])

            while queue:
                y, x = queue.popleft()
                if matrix[y, x] != outlier_value:
                    matrix[y, x] = outlier_value
                    for dy, dx in directions:
                        new_x = x + dx
                        new_y = y + dy

                        if 0 <= new_y < height and 0 <= new_x < width:
                            if matrix[new_y, new_x] != outlier_value:
                                queue.append((new_y, new_x))
                                path_x.append(x)
                                path_y.append(y)

            if len(path_x) > 20:
                densities.append({
                    'dx': path_x,
                    'dy': path_y,
                    'density': len(path_x)
                })
            else:
                IMAGE[path_y, path_x] = outlier_value

    new_density = []
    for _dict in densities:
        path_x, path_y = _dict['dx'], _dict['dy']
        x_min, x_max = min(path_x), max(path_x)
        y_min, y_max = min(path_y), max(path_y)

        # check if height of zone is too small, with of zone is too small or too large
        if ((y_max - y_min) < 0.1 * height) or ((y_max - y_min) > 0.8 * height) or ((y_max - y_min) < 10) or (
                x_max - x_min) > 0.5 * width:
            IMAGE[path_y, path_x] = outlier_value
        else:
            _dict['height'] = y_max - y_min
            new_density.append(_dict)

    height_of_zones = [_dict['height'] for _dict in new_density]
    if len(height_of_zones) <= 8:
        return IMAGE

    space = 3
    for _ in range(100):
        median_height = np.median(height_of_zones)
        outlier_index = np.where((height_of_zones > median_height + space) | (height_of_zones < median_height - space))[
            0]
        if len(outlier_index) > 0 and (len(height_of_zones) - len(outlier_index) > 8):
            space -= 1
            if space > 0:
                continue
        if len(outlier_index) > 0 and (len(height_of_zones) - len(outlier_index) < 8):
            space += 1
            if space < 6:
                continue
        break

    for idx in outlier_index:
        _dict = new_density[idx]
        path_x, path_y = _dict['dx'], _dict['dy']
        IMAGE[path_y, path_x] = outlier_value

    return IMAGE


def remove_ver_lines(image):
    """
    Removes outliers from an image.

    Args:
        image (numpy.ndarray()): The image to remove outliers from.

    Returns:
        numpy.ndarray(): The image with outliers removed.
    """
    image = cv2.resize(image, (int(image.shape[1] * 2), int(image.shape[0] * 2)), interpolation=cv2.INTER_LANCZOS4)
    w_img = image.shape[1]
    kernel = np.ones((3, 3), np.uint8)
    dilated = cv2.dilate(255 - image, kernel, iterations=1)
    edges = cv2.Canny(dilated, 50, 150)
    # plt.imshow(edges, cmap='gray')
    lines = cv2.HoughLinesP(edges, 1, np.pi / 180, 30, minLineLength=10, maxLineGap=10)
    if lines is not None:
        angles = []
        for line in lines:
            angle = helper.get_angle(line[0], False)
            if angle is not None and abs(angle) > 90:
                angle = 180 - abs(angle)
            angles.append(angle)
        ver_lines = [line[0] for line, angle in zip(lines, angles) if angle is None or abs(angle) >= 80]

        for x1, y1, x2, y2 in ver_lines:
            if (0.3 * w_img < x1 < 0.7 * w_img) or (0.3 * w_img < x2 < 0.7 * w_img):
                continue
            cv2.line(image, (x1, y1), (x2, y2), (255, 255, 255), 3)
    image = cv2.resize(image, (int(image.shape[1] / 2), int(image.shape[0] / 2)), interpolation=cv2.INTER_LANCZOS4)
    return image


def preprocess_image(IMAGE):
    """
    Preprocesses an image for tesseract OCR.

    Args:
        IMAGE (numpy.ndarray()): The image to be processed.

    Returns:
        pil_image (PIL.Image()): The processed image.
    """
    gray2 = get_grayscale(IMAGE)
    thresh2 = thresholding(gray2)
    thresh2 = remove_ver_lines(thresh2)
    myDetectTable = dt.DetectTable(thresh2, IMAGE)

    # remove horizontal lines from image
    h_thresh, w_thresh = thresh2.shape
    for x1, y1, x2, y2 in myDetectTable.horizontal_lines:
        angle = helper.get_angle((x1, y1, x2, y2), False)
        if angle is not None and abs(angle) > 90:
            angle = 180 - abs(angle)
        if angle is None or abs(angle) <= 10:
            if (0.4 * h_thresh < y1 < 0.6 * h_thresh) or (0.4 * h_thresh < y2 < 0.6 * h_thresh):
                continue
            cv2.line(thresh2, (x1, y1), (x2, y2), (255, 255, 255), 2)

    # remove vertical lines from image
    for x1, y1, x2, y2 in myDetectTable.vertical_lines:
        angle = helper.get_angle((x1, y1, x2, y2), False)
        if angle is not None and abs(angle) > 90:
            angle = 180 - abs(angle)
        if angle is None or abs(angle) >= 80:
            if (0.3 * w_thresh < x1 < 0.7 * w_thresh) or (0.0 * w_thresh < x2 < 0.7 * w_thresh):
                continue
            cv2.line(thresh2, (x1, y1), (x2, y2), (255, 255, 255), 2)

    blurred = cv2.GaussianBlur(thresh2, (1, 1), 0)
    im_bw = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 15,
                                  8)
    im_bw = remove_outliers(im_bw, 0)

    return im_bw


def get_digits_only(text):
    """
    Preprocesses an image for tesseract OCR.

    Args:
        text (str): The text to be processed. (api.GetUTF8Text())

    Returns:
        str: The text with only digits.
    """
    return ''.join(re.findall(r'\d+', text))


def preprocess_cell2(GRAY):
    try:
        _gray_img = GRAY.copy()
        _gray_img = ~_gray_img  # Make black background
        _gray_img = cv2.GaussianBlur(_gray_img, (3, 3), 0)
        _, _gray_img = cv2.threshold(_gray_img, 100, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        _thresh = cv2.resize(_gray_img, (700, 250), interpolation=cv2.INTER_CUBIC)
        _thresh = cv2.dilate(_thresh, np.ones((3, 3), np.uint8), iterations=1)
        _, _thresh = cv2.threshold(_thresh, 127, 255, cv2.THRESH_BINARY_INV)
        _thresh = 255 - _thresh

        _ctrs, _ = cv2.findContours(_thresh.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        _sorted_ctrs = sorted(_ctrs, key=lambda _ctr: cv2.boundingRect(_ctr)[0])
        _thresh_copy = _thresh.copy()
        _tk = []
        for _ctr in _sorted_ctrs:
            x, y, w, h = cv2.boundingRect(_ctr)
            if h > 90 and w > 37:
                _tk.append([x, y, w, h])
        _y_median = np.median([y for _, y, *_ in _tk])
        _h_median = np.median([h for *_, h in _tk])

        _bien = _y_median + _h_median
        for _idx in range(len(_tk)):
            x, y, w, h = _tk[_idx]
            if y + h > _bien:
                h = int(_bien - y)
                _tk[_idx] = [x, y, w, h]

        # remove outlier: if abs(y-y_median) > 20 or abs(h-h_median) > 20
        _tk = [t for t in _tk if abs(t[1] - _y_median) < 20 and abs(t[3] - _h_median) < 20]

        _th_x_min = [x for x, _, _, _ in _tk]
        _th_x_max = [x + w for x, _, w, _ in _tk]
        _th_y_min = [y for _, y, _, _ in _tk]
        _th_y_max = [y + h for _, y, _, h in _tk]
        _thresh_shrink = _thresh_copy[min(_th_y_min):max(_th_y_max), min(_th_x_min):max(_th_x_max)]
        _h_resized = 121
        _w_resized = int(_h_resized * _thresh_shrink.shape[1] / _thresh_shrink.shape[0])
        _thresh_shrink = cv2.resize(_thresh_shrink, (_w_resized, _h_resized))  # use for my model
        _thresh_extend = cv2.copyMakeBorder(_thresh_shrink, 50, 50, 50, 50, cv2.BORDER_CONSTANT, value=0)

        return _thresh_extend.astype(np.uint8)
    except:
        return GRAY


def get_cells_2_re_detect(indexes, images):
    results = {}
    file_path = os.path.join(os.path.dirname(__file__), 'cnn_printed_digit_model.tflite')
    model = tflite.Interpreter(model_path=file_path)
    all_numbers = []
    all_numbers_len = []
    ratios = [7.5, 6.5, 5.5, 4.5, 3.5, 2.5, 1.5]
    for idx in indexes:
        im = images[idx]

        # find contours
        contours, hierarchy = cv2.findContours(im, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

        # sort contours by x
        contours = sorted(contours, key=lambda ctr: cv2.boundingRect(ctr)[0])

        # im_contour = im.copy()
        numbers = []
        for cnt in contours:
            x, y, w, h = cv2.boundingRect(cnt)
            if w > 10 and h > 80:
                number = cell_456.shrink_image(im[y:y + h, x:x + w])
                if number.size == 0 or np.mean(number) < 60:
                    continue
                ratio = number.shape[1] / 76
                is_split = False
                for ra in ratios:
                    if ratio > ra:
                        number_of_split = math.ceil(ra)
                        width_of_split = number.shape[1] // number_of_split
                        number_split = []
                        for i in range(number_of_split):
                            number_split.append(number[:, i * width_of_split:(i + 1) * width_of_split])
                        for num in number_split:
                            num = cell_456.extend_image(num, max(num.shape[1] // 8, 3))
                            numbers.append(cv2.resize(num, (28, 28)))
                        is_split = True
                        break
                if not is_split:
                    number = cell_456.extend_image(number, max(number.shape[1] // 8, 3))
                    numbers.append(cv2.resize(number, (28, 28)))
                    # raw_numbers.append(number)

        # plt.imshow(im_contour, cmap='gray')
        if len(numbers) > 0:
            all_numbers.extend(numbers)
        all_numbers_len.append(len(numbers))

    begin = 0

    # predict
    all_values = []
    all_numbers_numpy = np.array(all_numbers, dtype=np.float32)
    for input_data in all_numbers_numpy:
        model.allocate_tensors()
        input_details = model.get_input_details()
        output_details = model.get_output_details()
        input_data_4d = input_data.reshape(-1, 28, 28, 1)
        model.set_tensor(input_details[0]['index'], input_data_4d)
        model.invoke()
        output_data = model.get_tensor(output_details[0]['index'])
        all_values.append(output_data)

    for idx, number_len in zip(indexes, all_numbers_len):
        if number_len == 0:
            results[idx] = ''
            continue
        end = begin + number_len
        values = all_values[begin:end]
        begin = end

        text = ''
        for value in values:
            text += str(np.argmax(value))
        results[idx] = text
    return results


def get_cells_2(images):
    _results = []
    gray_images = [preprocess_cell2(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)) for img in images]

    for _img in gray_images:
        _image = _img.copy()
        if _image.size == 0 or np.mean(_image) > 100:
            _results.append('')
            continue
        _subtract = 0
        optimize_text = ''
        _results.append(optimize_text)

    re_detect = [idx for idx, _result in enumerate(_results) if len(_result) < 6]
    if len(re_detect) > 0:
        _re_detect = get_cells_2_re_detect(re_detect, gray_images)
        for idx in re_detect:
            _results[idx] = _re_detect[idx]

    years = [58 + i for i in range(8)]

    try:
        for idx, _result in enumerate(_results):
            if len(_result) == 7:
                for j in [5, 6]:
                    _firstAndSecond = j * 10 + int(_result[0])
                    if _firstAndSecond in years:
                        _new_result = str(_firstAndSecond) + _result[1:]
                        _results[idx] = _new_result
                        break
            elif len(_result) == 8:
                _firstAndSecond = int(_result[:2])
                if _firstAndSecond not in years:
                    if (_firstAndSecond - 10) in years:
                        _new_result = str(_firstAndSecond - 10) + _result[2:]
                        _results[idx] = _new_result
                    elif (_firstAndSecond + 10) in years:
                        _new_result = str(_firstAndSecond + 10) + _result[2:]
                        _results[idx] = _new_result
                    else:
                        _second_number = int(_result[1])
                        isOK = False
                        for j in [5, 6]:
                            _firstAndSecond = j * 10 + _second_number
                            if _firstAndSecond in years:
                                _new_result = str(_firstAndSecond) + _result[2:]
                                _results[idx] = _new_result
                                isOK = True
                                break
                        if not isOK:
                            _results[idx] = _result[2:]
            elif len(_result) == 9:
                _first_number = int(_result[0])
                if _first_number < 5 or _first_number > 6:
                    _results[idx] = _result[1:]
                else:
                    _firstAndSecond = int(_result[:2])
                    if _firstAndSecond not in years:
                        if (_firstAndSecond - 10) in years:
                            _new_result = str(_firstAndSecond - 10) + _result[2:]
                            _results[idx] = _new_result
                        elif (_firstAndSecond + 10) in years:
                            _new_result = str(_firstAndSecond + 10) + _result[2:]
                            _results[idx] = _new_result
                        else:
                            _results[idx] = _result[2:]
                    else:
                        _results[idx] = _result[:-1]
            elif len(_result) == 10:
                _firstAndSecond = int(_result[:2])
                if _firstAndSecond in years:
                    _results[idx] = _result[:-2]
                else:
                    _results[idx] = _result[2:]
            elif len(_result) >= 11:
                _results[idx] = _result[len(_result) - 8:]
    except Exception as _:
        pass

    return _results
