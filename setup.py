#!/usr/bin/env python2
# -*- coding: utf-8 -*-
#
#       setup.py

import os
from setuptools import setup

setup(
    name = "django-bfm",
    version = "0.1",
    author = "Simonas Kazlauskas",
    author_email = "simonas@kazlauskas.me",
    description = ("Basic Django File Manager with multifile uploads, live file status, and file deleting."),
    license = "GPL",
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
          'License :: OSI Approved :: GNU Affero General Public License v3',
          'Topic :: Software Development :: Libraries :: Python Modules',],
    long_description = open('README.md').read()
)
