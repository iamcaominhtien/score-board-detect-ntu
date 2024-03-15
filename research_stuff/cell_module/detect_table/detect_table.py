import math

import cv2
import numpy as np
import cell_module.smooth_line.smooth_all_line as sl
import cell_module.helper_function as helper
from cell_module import colors


class DetectTable:
	"""
	A class used to detect tables in an image.

	...

	Attributes
	----------
	kernel_length : int
		the length of the kernel used for morphological operations
	vertical_kernel : numpy.ndarray
		a vertical kernel used to detect vertical lines in the image
	horizontal_kernel : numpy.ndarray
		a horizontal kernel used to detect horizontal lines in the image
	kernel : numpy.ndarray
		a 3x3 kernel used for morphological operations
	vertical_lines_img : numpy.ndarray
		an image of the detected vertical lines
	vertical_lines : numpy.ndarray
		the detected vertical lines
	horizontal_lines_img : numpy.ndarray
		an image of the detected horizontal lines
	horizontal_lines : numpy.ndarray
		the detected horizontal lines
	alpha : float
		the weight of the vertical lines in the final image
	beta : float
		the weight of the horizontal lines in the final image
	img_final_bin : numpy.ndarray
		the final binary image
	raw_img : numpy.ndarray
		the original image
	bin_image : numpy.ndarray
		the binary image
	iterations : int
		the number of iterations for the morphological operations
	"""

	def __init__(self, bin_image, raw_img, iterations=3):
		"""
		Initializes the DetectTable object with the given binary image, raw image, and number of iterations.

		Args:
			bin_image (np.ndarray): The binary image.
			raw_img (np.ndarray): The original image.
			iterations (int, optional): The number of iterations for the morphological operations. Default to 3.
		"""
		# The length of the kernel used for morphological operations
		self.kernel_length = None

		# A vertical kernel of (1 X kernel_length), which will detect all the vertical lines from the image.
		self.vertical_kernel = None

		# A horizontal kernel of (kernel_length X 1), which will help to detect all the horizontal line from the image.
		self.horizontal_kernel = None

		# A kernel of (3 X 3) ones.
		self.kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))

		# An image of the detected vertical lines
		self.vertical_lines_img = None

		# The detected vertical lines
		self.vertical_lines = None

		# An image of the detected horizontal lines
		self.horizontal_lines_img = None

		# The detected horizontal lines
		self.horizontal_lines = None

		# Weighting parameters, this will decide the quantity of an image to be added to make a new image.
		self.alpha = 0.5
		self.beta = 1.0 - self.alpha

		# The final binary image
		self.img_final_bin = None

		# The original image
		self.raw_img = raw_img

		# The binary image
		self.bin_image = bin_image

		# The length of the kernel is determined by the width of the binary image divided by 80
		self.kernel_length = np.array(bin_image).shape[1] // 80

		# A vertical kernel of (1 X kernel_length), which will detect all the vertical lines from the image.
		self.vertical_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, self.kernel_length))

		# A horizontal kernel of (kernel_length X 1), which will help to detect all the horizontal line from the image.
		self.horizontal_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (self.kernel_length, 1))

		# The number of iterations for the morphological operations
		self.iterations = iterations

		# Detect the table in the image
		self._detect_table()

	def _detect_vertical_lines(self):
		"""
		Detects the vertical lines in the image by performing morphological operations.

		The method first erodes the binary image with the vertical kernel, then dilates the eroded image with the same kernel.
		The resulting image is then smoothed to get the final image of vertical lines and the vertical lines themselves.
		"""
		# Erode the binary image with the vertical kernel
		img_temp1 = cv2.erode(self.bin_image, self.vertical_kernel, iterations=self.iterations)

		# Dilate the eroded image with the vertical kernel
		_vertical_lines_img = cv2.dilate(img_temp1, self.vertical_kernel, iterations=self.iterations)

		# Smooth the image to get the final image of vertical lines and the vertical lines themselves
		self.vertical_lines_img, self.vertical_lines = sl.smooth_line(
			_vertical_lines_img, horizontal=False,
			test=0
		)

	def _detect_horizontal_lines(self):
		"""
		Detects the horizontal lines in the image by performing morphological operations.

		The method first erodes the binary image with the horizontal kernel, then dilates the eroded image with the same kernel.
		The resulting image is then smoothed to get the final image of horizontal lines and the horizontal lines themselves.
		"""
		# Erode the binary image with the horizontal kernel
		img_temp2 = cv2.erode(self.bin_image, self.horizontal_kernel, iterations=self.iterations)

		# Dilate the eroded image with the horizontal kernel
		horizontal_lines_img = cv2.dilate(img_temp2, self.horizontal_kernel, iterations=self.iterations)

		# Smooth the image to get the final image of horizontal lines and the horizontal lines themselves
		self.horizontal_lines_img, self.horizontal_lines = sl.smooth_line(
			horizontal_lines_img,
			horizontal=True, test=0
		)

	def count_vertical_lines(self):
		"""
		Counts the number of vertical lines in the image.

		This method uses the OpenCV function findContours to find contours in the image of vertical lines.
		The contours are then counted and the count is returned.

		Returns:
			int: The number of vertical lines in the image.
		"""
		contours_ver, _ = cv2.findContours(
			self.vertical_lines_img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
		)
		return len(contours_ver)

	# Count the number of horizontal lines
	def count_horizontal_lines(self):
		"""
		Counts the number of horizontal lines in the image.

		This method uses the OpenCV function findContours to find contours in the image of horizontal lines.
		The contours are then counted and the count is returned.

		Returns:
			int: The number of horizontal lines in the image.
		"""
		contours_ho, _ = cv2.findContours(
			self.horizontal_lines_img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
		)
		return len(contours_ho)

	def _detect_table(self):
		"""
		Detects the table in the image by combining the detected vertical and horizontal lines.

		This method first calls the methods to detect vertical and horizontal lines.
		It then combines the images of vertical and horizontal lines into a new image with both having the same weight.
		The combined image is then eroded and threshold to get the final binary image of the table.

		The final binary image is stored in the attribute img_final_bin.
		"""
		# Detect the vertical lines in the image
		self._detect_vertical_lines()

		# Detect the horizontal lines in the image
		self._detect_horizontal_lines()

		# Combine horizontal and vertical lines in a new third image, with both having same weight.
		img_final_bin = cv2.addWeighted(
			self.vertical_lines_img, self.alpha, self.horizontal_lines_img, self.beta, 0.0
		)

		# Erode the combined image
		img_final_bin = cv2.erode(~img_final_bin, self.kernel, iterations=self.iterations)

		# Threshold the eroded image to get the final binary image
		(thresh, _img_final_bin) = cv2.threshold(
			img_final_bin, 128, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU
		)

		# Store the final binary image in the attribute img_final_bin
		self.img_final_bin = _img_final_bin
