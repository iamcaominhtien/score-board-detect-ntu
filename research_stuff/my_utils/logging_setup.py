import logging


class Logger:
	__logger = logging.getLogger(name='ScoreBoardDetect')
	__logger.setLevel(logging.INFO)
	__formatter = logging.Formatter('[%(levelname)s] - %(asctime)s - %(name)s - %(message)s')
	__ch = logging.StreamHandler()
	__ch.setFormatter(__formatter)
	__logger.addHandler(__ch)

	@classmethod
	def info(cls, message):
		cls.__logger.info(message)

	@classmethod
	def error(cls, message):
		cls.__logger.error(message)

	@classmethod
	def warning(cls, message):
		cls.__logger.warning(message)
