import re
from collections import deque

import cv2
import helper_function as helper
import numpy as np
from cell_456 import extend_image


def find_longest_increasing_subarray(arr):
    start = 0  # Vị trí bắt đầu của dãy con tăng dài nhất
    end = 0  # Vị trí kết thúc của dãy con tăng dài nhất
    longest_len = 1  # Độ dài của dãy con tăng dài nhất hiện tại
    current_start = 0  # Vị trí bắt đầu của dãy con tăng hiện tại
    current_len = 1  # Độ dài của dãy con tăng hiện tại

    for i in range(1, len(arr)):
        if arr[i] - arr[i - 1] == 1:
            current_len += 1
            if current_len > longest_len:
                longest_len = current_len
                start = current_start
                end = i
        else:
            current_start = i
            current_len = 1

    return start, end


# get grayscale image
def get_grayscale(image):
    return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)


# thresholding
def thresholding(image):
    return cv2.threshold(image, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]


def remove_ver_lines(image):
    image = cv2.resize(image, (int(image.shape[1] * 2), int(image.shape[0] * 2)), interpolation=cv2.INTER_LANCZOS4)
    w_img = image.shape[1]
    kernel = np.ones((3, 3), np.uint8)
    dilated = cv2.dilate(255 - image, kernel, iterations=1)
    edges = cv2.Canny(dilated, 50, 150)
    # plt.imshow(edges, cmap='gray')
    lines = cv2.HoughLinesP(edges, 1, np.pi / 180, 30, minLineLength=10, maxLineGap=10)
    if lines is not None:
        # angles = [helper.get_angle(line[0], False) for line in lines]
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


def remove_outliers(IMAGE, outlier_value=0):
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

    if len(densities) == 0:
        return 0, IMAGE, False

    densities = sorted(densities, key=lambda x: x['density'], reverse=True)
    max_densities = []
    for density in densities:
        dx = density['dx']
        dy = density['dy']
        x_min = min(dx)
        x_max = max(dx)
        y_min = min(dy)
        y_max = max(dy)
        w = x_max - x_min
        h = y_max - y_min
        if w / width > 0.9 or h / height > 0.9 or h < 10:
            continue
        else:
            max_densities.append({
                'density': density,
                'left': x_min,
                'right': x_max,
                'height': h,
            })
            # if len(max_density) == 3:
            #     break
    max_densities = sorted(max_densities, key=lambda x: x['left'])
    if len(max_densities) == 0:
        max_densities = [densities[0]]
    else:
        median_height = np.median([item['height'] for item in max_densities])
        max_densities = [item for item in max_densities if (10 < item['height'] <= 0.9 * height) and (
                median_height - 4 <= item['height'] <= median_height + 4)]
        status = [False] * len(max_densities)
        for idx in range(1, len(max_densities)):
            space = max_densities[idx]['left'] - max_densities[idx - 1]['right']
            if 0 < space <= 10:
                if not status[idx]:
                    status[idx] = True
                if not status[idx - 1]:
                    status[idx - 1] = True
        max_densities = [item['density'] for item, stt in zip(max_densities, status) if stt]
        if len(max_densities) > 3:
            max_densities = max_densities[:3]
        elif len(max_densities) == 0:
            max_densities = [densities[0]]
    all_dx = []
    all_dy = []
    for item in max_densities:
        all_dx.extend(item['dx'])
        all_dy.extend(item['dy'])
    x_min = min(all_dx)
    x_max = max(all_dx)
    y_min = min(all_dy)
    y_max = max(all_dy)
    image = IMAGE[y_min:y_max + 1, x_min:x_max + 1]
    image = extend_image(image)

    only_one = False
    if len(max_densities) == 1:
        # create new image by concat 2 number from image1 and image2
        only_one = True
        image = np.concatenate((image, image), axis=1)

    return len(max_densities), image, only_one


def pre_process_image(IMAGE):
    gray = get_grayscale(IMAGE)
    thresh = thresholding(gray)
    thresh = remove_ver_lines(thresh)

    blurred = cv2.GaussianBlur(thresh, (3, 3), 0)
    im_bw = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 15,
                                  8)  # Nhi phan anh
    number_of_digits, im_bw_rm, only_one = remove_outliers(im_bw)

    return number_of_digits, thresh, im_bw_rm, only_one


def get_digits_only(text):
    """
    Preprocesses an image for tesseract OCR.

    Args:
        text (str): The text to be processed. (api.GetUTF8Text())

    Returns:
        str: The text with only digits.
    """
    return ''.join(re.findall(r'\d+', text))


def change_size_image(IMAGE, min_size):
    h_img = IMAGE.shape[0]
    w_img = IMAGE.shape[1]
    if h_img < w_img:
        ratio_img = min_size / h_img
    else:
        ratio_img = min_size / w_img
    img = cv2.resize(IMAGE, (int(IMAGE.shape[1] * ratio_img), int(IMAGE.shape[0] * ratio_img)),
                     interpolation=cv2.INTER_LANCZOS4)
    img = cv2.threshold(img, 50, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]
    return img


def get_cells_number_one(images):
    results = ['' for _ in range(len(images))]
    return results
