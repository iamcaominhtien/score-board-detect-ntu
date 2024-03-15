from os import path

import tensorflow as tf

from my_utils.path_helper import path_trained_models


def load_model():
	# load tensorflow model from hdf5 file
	file_name = "neural_mnist_v4_hog_regularization.hdf5"
	file_path = path.join(path_trained_models(), file_name)
	model = tf.keras.models.load_model(file_path)
	return model


def test_detection():
	model = load_model()
	assert model is not None, "Model is not loaded"
