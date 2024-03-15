import json

import numpy as np


class NumpyEncoder(json.JSONEncoder):
	def default(self, obj):
		if isinstance(obj, np.integer):
			return int(obj)
		return super(NumpyEncoder, self).default(obj)


class PredictInformation:
	def __init__(self, stt=None, id=None, numbers=None, predicted=None):
		self.stt = stt
		self.id = id
		self.numbers: list = numbers
		self.predicted = predicted

	def to_dict(self):
		return {
			'stt': self.stt,
			'id': self.id,
			'numbers': self.numbers,
			'predicted': self.predicted
		}

	@classmethod
	def from_dict(cls, json_data):
		return cls(**json_data)
