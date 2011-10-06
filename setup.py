#!/usr/bin/env python2
# -*- coding: utf-8 -*-
#
#       setup.py

import os
from setuptools import setup
from django_bfm import __version__, __author__, __email__

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

setup(
    name = "django-bfm",
    version = __version__,
    author = __author__,
    author_email = __email__,
    description = ("Basic Django File Manager with multifile uploads, live file status, and file deleting."),
    license = "Apache",
    keywords = "django file manager",
    url = "https://github.com/simukis/django-bfm",
    packages=['django_bfm'],
    classifiers=[
          'Framework :: Django',
          'Environment :: Web Environment',
          'Programming Language :: Python',
          'Development Status :: 4 - Beta',
          'Intended Audience :: Developers',
          'Operating System :: OS Independent',
          'License :: OSI Approved :: Apache Software License',
          'Topic :: Software Development :: Libraries :: Python Modules',],
    long_description = read('README.rst'),
    include_package_data=True,
)
