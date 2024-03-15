from os import path

PROJECT_PATH = path.dirname(path.dirname(path.abspath(__file__)))


def path_test_inputs():
	return path.join(PROJECT_PATH, 'test', 'inputs')


def path_trained_models(sub_folder: str = 'hdf5'):
	assert sub_folder is not None, "Sub folder cannot be None"
	return path.join(PROJECT_PATH, 'model', 'trained_model', sub_folder)


def path_images():
	return path.join(PROJECT_PATH, 'Images')


def path_tessdata():
	return path.join(PROJECT_PATH, 'tools', 'tessdata')
