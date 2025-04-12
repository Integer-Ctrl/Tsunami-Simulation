.. _getting_started_building_docs:

.. role:: raw-html(raw)
    :format: html

Building the Documentation
==========================

.. note::
    A prebuild HTML of the documentation can be found at ``../Tsunami-Simulation/docs_sphinx/prebuild``.


Requirements
------------

To build the Sphinx documentation ``doxygen`` is required.
As well as ``python`` and the following packages: ``sphinx``, ``sphinx-rtd-theme``, ``breathe`` and ``sphinx-copybutton``.

You can check if ``doxygen`` is installed by running 

.. code-block:: bash

    doxygen --version

.. note::
    ``doxygen`` can be `downloaded <https://www.doxygen.nl/download.html>`_ from their website. Also precompiled binaries are available.

You can check if ``python`` is installed by running

.. code-block:: bash

    python --version

.. note::
    ``python`` can be `download <https://www.python.org/downloads/>`_ from their website.

To install the required packages we will use the recommended package manager `pip <https://pypi.org/project/pip/>`_.
If you don't have pip you can follow their `installation instructions <https://pip.pypa.io/en/stable/installation/>`_.

To install all packages we use the file ``requirements.txt`` in the directory ``../Tsunami-Simulation/docs_sphinx``.
Got to the base project base directory e.g. ``../Tsunami-Simulation`` and run the following command.

.. code-block:: bash

    pip install -r docs_sphinx/requirements.txt

Now all we can start building the documentation.

Building
--------

Building the project is easy.
Go into directory `docs_sphinx`.
Your path should look like ``../Tsunami-Simulation/docs_sphinx``.

Then we only need to run the following command.

.. code-block:: bash

    make html

.. important::
    You may need to edit the ``Makefile`` or ``make.bat`` to switch to your installed Python. The default is ``python`` and the Makefile tries to find ``python3``. :raw-html:`<br>`
    E.g. If your python is called by ``python3``.
    In the Makefile you have to change the line ``PYTHON ?= python`` to ``PYTHON ?= python3`` and in the make.bat ``set PYTHON=python`` becomes ``set PYTHON=python3``.

This builds sphinx with doxygen as an HTML page that can be viewed in your browser.
The desired HTML can be found in ``_build/html/index.html`` e.g. full path would be ``../Tsunami-Simulation/docs_sphinx/_build/html/index.html``.
This can be open in your browser and should exactly like this documentation.

.. note::
    Sometimes it is helpful to run the ``make clean`` command to delete all files from the ``_build`` directory because the HTML does not show the latest changes.