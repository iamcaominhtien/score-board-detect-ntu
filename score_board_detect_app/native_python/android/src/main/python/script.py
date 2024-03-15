import module.my_api as my_api
import json
import os
import traceback
import base64
from PIL import Image
import io
import module.get_lines_table as glt

def process_image_api(path):
    try:
        result = my_api.process_image_api(path)
    except Exception as e:
        result = json.dumps({'error': str(e), 'traceback': traceback.format_exc()})
    return result

def get_lines_table(encodedImage):
    try:
        decoded_image = base64.b64decode(encodedImage)
        img = Image.open(io.BytesIO(decoded_image))
        return glt.get_lines_table(img)
    except:
        return [5, 1199, 1631, 0, 0]