# python setup.py build_ext --inplace
from distutils.core import setup

import numpy
from Cython.Build import cythonize

setup(
    ext_modules=cythonize(
        ["cell_module/build/colors.pyx", "cell_module/build/helper_function.pyx", "cell_module/build/smooth_line.pyx", "cell_module/build/detect_table.pyx",
         "cell_module/build/cell_456.pyx", "cell_module/build/my_api.pyx", "cell_module/build/cell_2.pyx", "cell_module/build/cell_1.pyx"],
        compiler_directives={'language_level': "3"}),
    include_dirs=[numpy.get_include()]
)
