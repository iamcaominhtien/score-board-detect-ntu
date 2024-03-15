import math

import cv2
import numpy as np

import module.helper_function as helper
import module.smooth_line as smooth_line


def custom_round(number):
    value = math.floor(number) if number - math.floor(number) >= 0.5 else math.floor(number) - 1
    return value if value > 0 else 0


def filter_horizontal_lines(LINES):
    try:
        lines = np.array(LINES)

        # region Remove outliers by angle
        angles = [helper.get_angle(line, rad=False) for line in lines]
        check_outlier = helper.analyze_data_to_find_outliers(angles)
        median = check_outlier['median']
        outlier_index = check_outlier['outlier_index']
        if median is not None:
            for idx in range(len(outlier_index) - 1, -1, -1):
                if abs(angles[outlier_index[idx]] - median) > 1:
                    lines = np.delete(lines, outlier_index[idx], axis=0)
        # endregion

        row_spaces_multiple = []
        row_spaces = []
        for i, line in enumerate(lines):
            if i == 0:
                continue
            x1, y1, x2, y2 = lines[i - 1]
            x3, y3, x4, y4 = line

            row_spaces_multiple.append(abs(y1 - y3) * abs(y2 - y4))
            row_spaces.append(abs(np.average([y1, y2]) - np.average([y3, y4])))

        check_outlier = helper.analyze_data_to_find_outliers(row_spaces_multiple)
        clean_index = check_outlier['clean_index']
        horizontal_lines = [False for _ in range(len(lines))]

        for idx in clean_index:
            horizontal_lines[idx] = True
            horizontal_lines[idx + 1] = True

        median = np.percentile(row_spaces, 50)
        filter_horizontal_lines = np.array(lines)[horizontal_lines]

        if median is not None:
            for idx in range(len(filter_horizontal_lines) - 2, -1, -1):
                x1, y1, x2, y2 = filter_horizontal_lines[idx]
                x3, y3, x4, y4 = filter_horizontal_lines[idx + 1]
                dy1 = abs(y1 - y3)
                dy2 = abs(y2 - y4)
                if dy1 / median > 1.5 or dy2 / median > 1.5:
                    number_of_new_lines = max(custom_round(dy1 / median), custom_round(dy2 / median))
                    space_y13 = abs(y1 - y3) / (number_of_new_lines + 1)
                    space_y24 = abs(y2 - y4) / (number_of_new_lines + 1)
                    for i in range(number_of_new_lines):
                        filter_horizontal_lines = np.insert(filter_horizontal_lines, idx + i + 1,
                                                            [x1, y1 + (i + 1) * space_y13, x2,
                                                             y2 + (i + 1) * space_y24],
                                                            axis=0)

        return filter_horizontal_lines
    except:
        return horizontal_lines


def filter_vertical_lines(lines, horizontal_lines):
    # find the center point (average) in lines
    left_line, right_line = lines[0], lines[-1]
    center_line = (left_line + right_line) / 2  # only interested in the value of x
    # TODO: check it again
    quarter_line = (left_line + center_line) / 4  # only interested in the value of x

    col_spaces = []
    for i, line in enumerate(lines):
        if i < 2:
            continue
        x1, y1, x11, y11 = lines[i - 2]
        x2, y2, x22, y22 = lines[i - 1]
        x3, y3, x33, y33 = line

        d1 = np.average([helper.length_of_line([x1, y1, x2, y2]), helper.length_of_line([x11, y11, x22, y22])])
        d2 = np.average([helper.length_of_line([x2, y2, x3, y3]), helper.length_of_line([x22, y22, x33, y33])])
        col_spaces.append(abs(d2 / d1))

    # find cell 1 & 2 (line1, line2, line3)
    lines_1_2_3_6_7_8_9 = np.array([])
    for i, value in enumerate(col_spaces):
        if 1.5 < value < 2.3:
            if lines[i][0] < center_line[0]:
                if i + 1 < len(col_spaces) and lines[i + 1][0] < quarter_line[0]:
                    lines_1_2_3_6_7_8_9 = lines[i:i + 3][:]
                    break

    if len(lines_1_2_3_6_7_8_9) < 3:
        second_line = []
        third_line = []
        x1, *_ = left_line
        for _line in [horizontal_lines[0], horizontal_lines[-1]]:
            m, b = helper.line_slope_intercept(_line)
            _line_length = helper.length_of_line(_line)
            denta_x_second = x1 + _line_length * 0.048
            denta_x_third = x1 + _line_length * 0.1409
            second_line.extend([denta_x_second, (m * denta_x_second + b)])
            third_line.extend([denta_x_third, (m * denta_x_third + b)])

        for line in lines:
            if abs(line[0] - second_line[0]) < 15:
                second_line = line.copy()
                continue

            if abs(line[0] - third_line[0]) < 15:
                third_line = line.copy()

        lines_1_2_3_6_7_8_9 = smooth_line.stretch_vertical_lines(
            np.array([left_line, second_line, third_line]), left_line[-1])

    # find cell 6, 7, 8 (line6, line7, line8, line9)
    for i, value in enumerate(col_spaces):
        if 0.8 < value < 1.3:
            if lines[i][0] > center_line[0]:
                if i + 4 < len(col_spaces) and 0.8 < col_spaces[i + 1] < 1.3:
                    if len(lines_1_2_3_6_7_8_9) == 0:
                        lines_1_2_3_6_7_8_9 = lines[i:i + 4][:]
                    else:
                        lines_1_2_3_6_7_8_9 = np.append(lines_1_2_3_6_7_8_9, lines[i:i + 4][:], axis=0)
                    break

    if len(lines_1_2_3_6_7_8_9) < 7:
        sixth_line = None
        for i, value in enumerate(col_spaces):
            if 0.8 < value < 1.3 and lines[i][0] > center_line[0]:
                sixth_line = lines[i]
                break

        if sixth_line is not None:
            seventh_line = []
            eighth_line = []
            ninth_line = []
            x1, *_ = sixth_line

            for _line in [horizontal_lines[0], horizontal_lines[-1]]:
                m, b = helper.line_slope_intercept(_line)
                _line_length = helper.length_of_line(_line)
                denta_x_seventh = x1 + _line_length * 0.0502
                denta_x_eighth = denta_x_seventh + _line_length * 0.0502
                denta_x_ninth = denta_x_eighth + _line_length * 0.0502
                seventh_line.extend([denta_x_seventh, (m * denta_x_seventh + b)])
                eighth_line.extend([denta_x_eighth, (m * denta_x_eighth + b)])
                ninth_line.extend([denta_x_ninth, (m * denta_x_ninth + b)])

            for line in lines:
                if abs(line[0] - seventh_line[0]) < 10:
                    seventh_line = line.copy()
                    continue

                if abs(line[0] - eighth_line[0]) < 10:
                    eighth_line = line.copy()
                    continue

                if abs(line[0] - ninth_line[0]) < 10:
                    ninth_line = line.copy()

            lines_6_7_8_9 = np.array([sixth_line, seventh_line, eighth_line, ninth_line])
            lines_6_7_8_9 = smooth_line.stretch_vertical_lines(lines_6_7_8_9, left_line[-1])
            lines_1_2_3_6_7_8_9 = np.append(lines_1_2_3_6_7_8_9, lines_6_7_8_9, axis=0)

    if len(lines_1_2_3_6_7_8_9) < 7:
        return np.array([], dtype=int)

    return lines_1_2_3_6_7_8_9.astype(int)


def cut_table_row_by_row(horizontal_lines, vertical_lines, img, img_bin, index_of_image=1):
    cells = []
    for i, h_line in enumerate(horizontal_lines):
        if i < 1:
            continue

        h_line1 = horizontal_lines[i - 1]
        h_line2 = h_line

        row = []
        for j, v_line in enumerate(vertical_lines):
            if j not in [1, 2, 4, 5, 6]:
                continue
            v_line1 = vertical_lines[j - 1]
            v_line2 = v_line

            intersections = []
            for h_l in [h_line1, h_line2]:
                for v_l in [v_line1, v_line2]:
                    intersection = helper.find_intersection_of_2_lines(h_l, v_l)
                    if intersection is not None:
                        intersections.append(intersection)
            intersections = np.array(intersections)

            if len(intersections) == 4:
                intersections[:2, 1] += 4
                intersections[-2:, 1] += 8
                _all_x = intersections[:, 0]
                _all_y = intersections[:, 1]

                # find x_min, x_max, y_min, y_max in intersections
                x_min, x_max = min(_all_x), max(_all_x)
                y_min, y_max = min(_all_y), max(_all_y)

                pts_dst = [[0, 0], [x_max - x_min, 0], [0, y_max - y_min], [x_max - x_min, y_max - y_min]]
                M = cv2.getPerspectiveTransform(np.float32(intersections), np.float32(pts_dst))
                dst = cv2.warpPerspective(img, M, (x_max - x_min, y_max - y_min))
                row.append({'name': r'Images/row_cut/Anh{}_row_{}_{}.jpg'.format(index_of_image, i, j), 'point': dst})

        if len(row) == 5:
            cells.append(row)

    return cells


def remove_outlier(points):
    ratio = []
    for row in points:
        for point in row:
            h, w, *_ = point['point'].shape
            ratio.append(w + h)

    # calculate quartile 25, 50, 75
    q25, q75 = np.percentile(ratio, [25, 75])
    iqr = q75 - q25
    # calculate min, max
    _min = q25 - (iqr * 1.5)
    _max = q75 + (iqr * 1.5)

    # # draw boxplot
    # plt.boxplot(ratio)
    # plt.show()

    points_temp = []

    for row in points:
        for point in row:
            if _min <= np.sum(point['point'].shape[:2]) <= _max:
                points_temp.append(row)
                break

    return np.array(points_temp)


def _sort_contours(cnts, method="left-to-right"):
    # initialize the reverse flag and sort index
    reverse = False
    i = 0
    # handle if we need to sort in reverse
    if method == "right-to-left" or method == "bottom-to-top":
        reverse = True
    # handle if we are sorting against the y-coordinate rather than
    # the x-coordinate of the bounding box
    if method == "top-to-bottom" or method == "bottom-to-top":
        i = 1
    # construct the list of bounding boxes and sort them from top to
    # bottom
    boundingBoxes = [cv2.boundingRect(c) for c in cnts]
    (cnts, boundingBoxes) = zip(*sorted(zip(cnts, boundingBoxes),
                                        key=lambda b: b[1][i], reverse=reverse))
    # return the list of sorted contours and bounding boxes
    return cnts, boundingBoxes


class DetectTable:
    kernel_length = None
    # A vertical kernel of (1 X kernel_length), which will detect all the vertical lines from the image.
    vertical_kernel = None
    # A horizontal kernel of (kernel_length X 1), which will help to detect all the horizontal line from the image.
    horizontal_kernel = None
    # A kernel of (3 X 3) ones.
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
    vertical_lines_img = None
    vertical_lines = None
    horizontal_lines_img = None
    horizontal_lines = None
    # Weighting parameters, this will decide the quantity of an image to be added to make a new image.
    alpha = 0.5
    beta = 1.0 - alpha
    img_final_bin = None

    def __init__(self, bin_image, raw_img, iterations=3):
        self.raw_img = raw_img
        self.bin_image = bin_image
        self.kernel_length = np.array(bin_image).shape[1] // 80
        self.vertical_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, self.kernel_length))
        self.horizontal_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (self.kernel_length, 1))
        self.iterations = iterations

        self._detect_table()
        # self._detect_boxes()

    # Morphological operation to detect vertical lines from an image
    def _detect_vertical_lines(self):
        img_temp1 = cv2.erode(self.bin_image, self.vertical_kernel, iterations=self.iterations)
        _vertical_lines_img = cv2.dilate(img_temp1, self.vertical_kernel, iterations=self.iterations)
        self.vertical_lines_img, self.vertical_lines = smooth_line.smooth_line(_vertical_lines_img, horizontal=False,
                                                                               test=0)
        # self.vertical_lines_img = _vertical_lines_img

    def _detect_horizontal_lines(self):
        img_temp2 = cv2.erode(self.bin_image, self.horizontal_kernel, iterations=self.iterations)
        _horizontal_lines_img = cv2.dilate(img_temp2, self.horizontal_kernel, iterations=self.iterations)
        self.horizontal_lines_img, self.horizontal_lines = smooth_line.smooth_line(_horizontal_lines_img,
                                                                                   horizontal=True, test=0)
        # self.horizontal_lines_img = _horizontal_lines_img

    # Count number of vertical lines
    def count_vertical_lines(self):
        _contours_ver, _ = cv2.findContours(self.vertical_lines_img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        return len(_contours_ver)

    # Count number of horizontal lines
    def count_horizontal_lines(self):
        _contours_ho, _ = cv2.findContours(self.horizontal_lines_img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        return len(_contours_ho)

    # Detect table
    def _detect_table(self):
        self._detect_vertical_lines()
        self._detect_horizontal_lines()
        # Combine horizontal and vertical lines in a new third image, with both having same weight.
        img_final_bin = cv2.addWeighted(self.vertical_lines_img, self.alpha, self.horizontal_lines_img, self.beta, 0.0)
        img_final_bin = cv2.erode(~img_final_bin, self.kernel, iterations=self.iterations)  # iterations=2
        (thresh, _img_final_bin) = cv2.threshold(img_final_bin, 128, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)
        self.img_final_bin = _img_final_bin
