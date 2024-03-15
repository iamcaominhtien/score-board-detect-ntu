import json
import os

import cv2
import numpy as np
from PIL import Image
import tflite_runtime.interpreter as tflite

import module.cell_2 as cell_2
import module.cell_456 as cell_456
import module.detect_table as detect_table
import module.helper_function as helper_function


class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        return super(NumpyEncoder, self).default(obj)


def pre_process_image(image_downloaded):
    IMAGE = np.array(image_downloaded, dtype=np.uint8)
    h_raw, _ = IMAGE.shape[:2]
    if h_raw > 1500:
        IMAGE = cv2.resize(IMAGE, (1199, 1631), interpolation=cv2.INTER_LANCZOS4)

    img_bin = helper_function.preprocess(IMAGE, 5)
    if img_bin is None:
        return None
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
                                               IMAGE, img_bin)

    return points


# @helper.timer
def f_row(row):
    # global images_cell1, images_cell2, numbers_predict
    returns_t = []
    for col_num in range(len(row)):
        if col_num <= 1:
            returns_t.append(row[col_num]['point'])
        else:
            point = row[col_num]
            numbers = cell_456.cell_456_process(point['point'])
            returns_t.append(numbers)
    return returns_t


def process_image_api(url):
    file_path = os.path.join(os.path.dirname(__file__), 'neural_mnist_v11_hog.tflite')
    neural_model_reg = tflite.Interpreter(model_path=file_path)

    image_downloaded = Image.open(url)

    # region process image
    points = pre_process_image(image_downloaded)
    if points is None or len(points) == 0:
        return json.dumps({'error': 'Cannot detect table', 'code': 'cdt'}, cls=NumpyEncoder)
    # endregion

    # region cut table, row by row
    my_prediction = {
        idx: {
            'stt': None,
            'id': None,
            'numbers': None,  # 1d array
            'predicted': None,
            # 2d array, each value in numbers has a matched array(1d) in predicted
        }
        for idx in range(len(points))
    }

    # with concurrent.futures.ThreadPoolExecutor() as executor:
    #     executor.map(f, points)
    numbers_predict = []
    images_cell1 = []
    images_cell2 = []

    # results = []
    results = [f_row(row) for row in points]

    for idx, item in enumerate(results):
        numbers_of_row_col234 = []
        images_cell1.append(item[0])
        images_cell2.append(item[1])

        if item[2] is not None:
            numbers_predict.extend(item[2])
            # my_prediction[idx]['numbers'] = len(item[2])
            numbers_of_row_col234.append(len(item[2]))
        else:
            numbers_of_row_col234.append(None)

        if item[3] is not None:
            numbers_predict.extend(item[3])
            # my_prediction[idx]['numbers'] = len(item[3])
            numbers_of_row_col234.append(len(item[3]))
        else:
            numbers_of_row_col234.append(None)

        if item[4] is not None:
            numbers_predict.extend(item[4])
            # my_prediction[idx]['numbers'] = len(item[4])
            numbers_of_row_col234.append(len(item[4]))
        else:
            numbers_of_row_col234.append(None)
        my_prediction[idx]['numbers'] = numbers_of_row_col234

    if len(numbers_predict) == 0:
        return json.dumps({'error': 'Cannot detect table', 'code': 'cdt'}, cls=NumpyEncoder)
    # endregion

    cell_2_ocr = cell_2.get_cells_2(images_cell2)
    for idx in range(len(cell_2_ocr)):
        my_prediction[idx]['id'] = cell_2_ocr[idx]

    # predict
    data_hogs = np.array(helper_function.hog_feature_extraction(numbers_predict), dtype=np.float32)
    predicted_classes = []
    for input_data in data_hogs:
        neural_model_reg.allocate_tensors()
        input_details = neural_model_reg.get_input_details()
        output_details = neural_model_reg.get_output_details()
        input_data_2d = np.array([input_data], dtype=np.float32)
        neural_model_reg.set_tensor(input_details[0]['index'], input_data_2d)
        neural_model_reg.invoke()
        output_data = neural_model_reg.get_tensor(output_details[0]['index'])
        predicted_classes.append(np.argmax(output_data, axis=1)[0])

    predicted_iterator = iter(predicted_classes)
    try:
        for idx in range(len(points)):
            if my_prediction[idx]['numbers'] is not None:
                _my_predicted = []
                for number_of_digit in my_prediction[idx]['numbers']:
                    _my_predicted.append(list(
                        next(predicted_iterator) for _ in range(number_of_digit)))
                my_prediction[idx]['predicted'] = _my_predicted
    except StopIteration:
        pass
    # endregion

    # region prepare json
    my_prediction = {
        idx: {'id': my_prediction[idx]['id'], 'predicted': my_prediction[idx]['predicted']} for idx
        in
        range(len(my_prediction))}
    # my_prediction_list = [my_prediction[idx] for idx in range(len(my_prediction))]
    my_prediction_list = []
    for idx in range(len(my_prediction)):
        if len(my_prediction[idx]['id']) + np.array(my_prediction[idx]['predicted'],
                                                    dtype=object).size == 0:
            continue
        for jdx in range(idx, len(my_prediction)):
            my_prediction_list.append(my_prediction[jdx])
        break
    my_prediction_json = json.dumps({
        'data': my_prediction_list,
    }, cls=NumpyEncoder)
    # endregion

    return my_prediction_json
