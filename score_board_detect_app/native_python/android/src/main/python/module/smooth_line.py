import cv2
import module.colors as colors
import module.helper_function as helper
import numpy as np


def _smooth_line_horizontal(line_matrix, test=False):
    height = line_matrix.shape[0]
    width = line_matrix.shape[1]
    dst = cv2.Canny(line_matrix, 50, 200, None, 3)

    # Copy edges to the images that will display the results in BGR
    bg_dark = np.zeros((height, width), np.uint8)
    cdstP_stretch = bg_dark.copy()
    probabilistic_lines = []

    linesP = cv2.HoughLinesP(dst, 1, np.pi / 180, 50, None, 50, width)
    if linesP is not None:
        for i in range(0, len(linesP)):
            l = linesP[i][0]
            probabilistic_lines.append([l[0], l[1], l[2], l[3]])

    # sort probabilistic_lines by y1, then group them and each group combine to 1 line
    probabilistic_lines.sort(key=lambda x: x[1])

    # region Merge lines temporarily, calculate lengths, filter data, and delete temporary lines.
    group_temp_horizontal_lines = group_horizontal_lines(lines=probabilistic_lines, unify=False)
    merge_group_temp_horizontal_lines = merger_horizontal_lines_groups_into_one(
        group_temp_horizontal_lines)
    merge_group_temp_horizontal_lines_length_of_each_line = [helper.length_of_line(line) for line in
                                                             merge_group_temp_horizontal_lines]
    analyze_data = helper.analyze_data_to_find_outliers(merge_group_temp_horizontal_lines_length_of_each_line)
    outlier_index = analyze_data['outlier_index']
    median = analyze_data['median']
    if median is not None and median != -1:
        for index in range(len(outlier_index) - 1, -1, -1):
            idx = outlier_index[index]
            ratio = merge_group_temp_horizontal_lines_length_of_each_line[idx] / median
            if 0.7 < ratio <= 1:
                outlier_index = np.delete(outlier_index, index)
    filter_group_temp_horizontal_lines = group_temp_horizontal_lines[outlier_index]
    for group in filter_group_temp_horizontal_lines:
        for line in group:
            try:
                probabilistic_lines.remove(line)
            except Exception:
                pass
    # endregion

    _group_horizontal_lines = group_horizontal_lines(probabilistic_lines)
    probabilistic_lines_stretch = stretch_horizontal_lines(_group_horizontal_lines, width)
    probabilistic_lines_stretch = group_horizontal_lines(probabilistic_lines_stretch.tolist())

    return cdstP_stretch, probabilistic_lines_stretch


def _smooth_line_vertical(line_matrix, test=False):
    height = line_matrix.shape[0]
    width = line_matrix.shape[1]
    dst = cv2.Canny(line_matrix, 50, 200, None, 3)

    # Copy edges to the images that will display the results in BGR
    bg_dark = np.zeros((height, width), np.uint8)
    cdstP_stretch = bg_dark.copy()
    probabilistic_lines = []

    linesP = cv2.HoughLinesP(dst, 1, np.pi / 180, 50, None, 50, height)

    if linesP is not None:
        for i in range(0, len(linesP)):
            l = linesP[i][0]
            probabilistic_lines.append([l[0], l[1], l[2], l[3]])

    # sort probabilistic_lines by y1, then group them and each group combine to 1 line
    probabilistic_lines.sort(key=lambda x: x[0])

    _group_vertical_lines = group_vertical_lines(probabilistic_lines)
    probabilistic_lines_stretch = stretch_vertical_lines(_group_vertical_lines, height)
    probabilistic_lines_stretch = group_vertical_lines(probabilistic_lines_stretch.tolist())
    for line in probabilistic_lines_stretch:
        cv2.line(cdstP_stretch, (line[0], line[1]), (line[2], line[3]), colors.WHITE, 3, cv2.LINE_AA)

    return cdstP_stretch, probabilistic_lines_stretch


def smooth_line(line_matrix, horizontal=True, test=False):
    if horizontal:
        return _smooth_line_horizontal(line_matrix, test)
    return _smooth_line_vertical(line_matrix, test)


def merger_horizontal_lines_groups_into_one(groups):
    return_groups = []
    for group in groups:
        x = sorted([line[0] for line in group] + [line[2] for line in group])

        subtract_x = np.array([line[0] - line[2] for line in group])
        subtract_y = np.array([line[1] - line[3] for line in group])
        m = [subtract_y[i] / subtract_x[i] for i in range(len(subtract_x)) if subtract_x[i] != 0]
        if len(m) > 0:
            m_avg = np.average(m)
        else:
            m_avg = 0.0
        y = sorted([np.average([line[1] for line in group]), np.average([line[3] for line in group])])

        if len(m) > 0 > m_avg:
            return_groups.append([x[0], y[-1], x[-1], y[0]])
        else:
            return_groups.append([x[0], y[0], x[-1], y[-1]])

    return_groups.sort(key=lambda x: x[1])
    return np.array(return_groups).astype(int)


def group_horizontal_lines(lines, level=15, unify=True):
    """
    Group lines which y1 distance is less than level
    :param unify: group lines to only 1 line or not
    :param level:
    :param lines: list of lines
    :return: list of groups of lines
    """

    def check_group_ok(group):
        """
        This function checks if a group is ok.
        Parameters:
          group: A list of lines.
        Returns:
          True if the group is ok, False otherwise.
          """
        y1_min = min(line[1] for line in group)
        y1_max = max(line[1] for line in group)
        y2_min = min(line[3] for line in group)
        y2_max = max(line[3] for line in group)

        if y1_max - y1_min > level or y2_max - y2_min > level:
            return False

        return True

    groups = []
    for line in lines:
        if len(groups) == 0:
            groups.append([line])
        else:
            is_group = False
            for group in groups:
                if not check_group_ok(group):
                    continue
                founded = False
                for _, y1, *_ in group:
                    if abs(y1 - line[1]) < level:
                        founded = True
                        break

                if founded:
                    group.append(line)
                    is_group = True
                    break
            if not is_group:
                groups.append([line])

    if unify:
        # Now, in each group, combine all the lines to only 1 line
        # return_groups = [np.average(group, axis=0).astype(int) for group in groups]
        return merger_horizontal_lines_groups_into_one(np.array(groups, dtype=object))
    else:
        return np.array(groups, dtype=object)


def group_vertical_lines(lines, level=15, unify=True):
    """
    Group lines which x1 distance is less than level
    :param unify: merge lines to only 1 line or not
    :param level:
    :param lines: list of lines
    :return: list of groups of lines
    """
    groups = []
    for line in lines:
        if len(groups) == 0:
            groups.append([line])
        else:
            is_group = False
            for group in groups:
                founded = False
                for x0, *_ in group:
                    if abs(x0 - line[0]) < level:
                        founded = True
                        break

                if founded:
                    group.append(line)
                    is_group = True
                    break
            if not is_group:
                groups.append([line])

    if unify:
        # Now, in each group, combine all the lines to only 1 line
        # return_groups = [np.average(group, axis=0).astype(int) for group in groups]
        return_groups = []
        for group in groups:
            y = sorted([line[1] for line in group] + [line[3] for line in group])

            subtract_x = np.array([line[0] - line[2] for line in group])
            subtract_y = np.array([line[1] - line[3] for line in group])
            m = [subtract_y[i] / subtract_x[i] for i in range(len(subtract_x)) if subtract_x[i] != 0]
            if len(m) > 0:
                m_avg = np.average(m)
            else:
                m_avg = 0.0
            x = sorted([np.average([line[0] for line in group]), np.average([line[2] for line in group])])

            if len(m) > 0 > m_avg:
                return_groups.append([x[-1], y[0], x[0], y[-1]])
            else:
                return_groups.append([x[0], y[0], x[-1], y[-1]])

        return_groups.sort(key=lambda x: x[0])

        return np.array(return_groups).astype(int)
    else:
        return np.array(groups, dtype=object)


def stretch_horizontal_lines(lines, width):
    """
    Stretch horizontal lines to the width of image
    :param lines: list of lines
    :param width: width of image
    :return: list of stretched lines
    Example: line AB -> line CD [C(0,?)  A  B  D(width,?)]
    """

    stretched_lines = []
    for line in lines:
        # if helper.length_of_line(line) < width / 5:
        #     continue
        x_A, y_A, x_B, y_B = line
        if x_A == x_B: continue
        m = (y_B - y_A) / (x_B - x_A)
        b = y_A - m * x_A

        if m != 0:
            y_C = b
            y_D = m * width + b
            stretched_lines.append([0, y_C, width, y_D])
        else:
            stretched_lines.append([0, y_A, width, y_B])

    return np.array(stretched_lines).astype(int)


def stretch_vertical_lines(lines, height):
    """
    Stretch horizontal lines to the height of image
    :param lines: list of lines
    :param height: height of image
    :return: list of stretched lines
    Example: line AB -> line CD [C(?,0)  A  B  D(?,height)]
    """

    stretched_lines = []
    for line in lines:
        # if helper.length_of_line(line) < height / 5:
        #     continue
        x_A, y_A, x_B, y_B = line

        if x_B - x_A != 0:
            m = (y_B - y_A) / (x_B - x_A)
            if m == 0: continue
            b = y_A - m * x_A
            x_C = -b / m
            x_D = (height - b) / m
            stretched_lines.append([x_C, 0, x_D, height])
        else:
            stretched_lines.append([x_A, 0, x_B, height])

    return np.array(stretched_lines).astype(int)
