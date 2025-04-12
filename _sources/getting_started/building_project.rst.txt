.. _getting_started_building_project:

.. role:: raw-html(raw)
    :format: html

Building the Project
====================


Requirements
------------

To use this project ``CMake`` is required.
You can check if CMake is installed by running

.. code-block:: bash

    cmake --version

.. note::
    ``CMake`` can be `downloaded <https://cmake.org/download/#latest>`_ or installed OS specific through other methods

    *Windows*
        There are several ways to install ``CMake`` on Windows.

        Using `Windows Package Manager <https://learn.microsoft.com/de-de/training/modules/explore-windows-package-manager-tool/>`_
            ``CMake`` can be installed using the following command

            .. code-block:: bash

                winget install kitware.cmake

        Using `Chocolatey <https://chocolatey.org>`_
            ``CMake`` can be installed using the following command

            .. code-block:: bash

                choco install cmake

        Using `Visual Studio <https://visualstudio.microsoft.com>`_
            `Official Installation Guid <https://learn.microsoft.com/en-us/cpp/build/cmake-projects-in-visual-studio?view=msvc-170#installation>`_

            .. image:: ../_static/photos/VisualStudio_CMake_Installation.png
                :align: right
                :scale: 75%

            1. Therefore you need to `download Visual Studio <https://visualstudio.microsoft.com/de/downloads/>`_. The Community Edition is free.

            2. Starting the Visual Studio Installer

            3. Select ``Desktop development with C++`` and make sure that ``C++-CMake-Tools für Windows`` is checked on the right side of the installer.

            4. Press Install


    *Linux*
        A simple way is using ``apt-get`` by running the command

        .. code-block:: bash

            sudo apt-get install cmake

    
    *MacOS*
        A simple way is using ``brew`` by running the command

        .. code-block:: bash

            brew install cmake


As the project also uses ``netCDF``, this must also be installed on the PC.
You can check if netCDF is installed by running

.. code-block:: bash

    nc-config --version

.. note::
    ``netCDF`` can be installed OS specific

    **Windows**

        1. `Download <https://docs.unidata.ucar.edu/netcdf-c/current/winbin.html>`_ and install the netCDF-C library and utilities

        2. Install as usual and make sure to ``add netCDF`` to the system ``PATH`` for all users

    **Linux and MAC**

        The easiest way to install netCDF is via `Homebrew <https://brew.sh/>`_. Run the following command in the terminal:

        .. code-block:: bash

            brew install netcdf


Building
--------

1. Download the `git repository <https://github.com/RivinHD/Tsunami-Simulation>`_ with git

    HTTPS

    .. code-block:: bash

        git clone https://github.com/RivinHD/Tsunami-Simulation.git

    SSH

    .. code-block:: bash

        git clone git@github.com:RivinHD/Tsunami-Simulation.git

2. Go into the project folder. Your current path should look like this ``../Tsunami-Simulation``.

3. Install submodules with git

    .. code-block:: bash

        git submodule init
        git submodule update

4. Now create a new folder called ``build`` with

    .. code-block:: bash

        mkdir build

5. Go into this directory. Your current path should look like this ``../Tsunami-Simulation/build``.

6. Now we can start with CMake. Run the following command

    .. code-block:: bash

        cmake .. -DCMAKE_BUILD_TYPE=<Type>

    Supported values for ``<Type>`` are **Release** and **Debug**.
    If only ``cmake ..`` is used the Release build is selected.

    The most desired command might be:

    .. code-block:: bash

        cmake .. -DCMAKE_BUILD_TYPE=Release

    .. note::

        With the Option ``-G`` a Generator can be defined used to create the make files and compile the Code.
        All available Generators can be found at the bottom of the :raw-html:`<br/>` ``cmake --help`` text.
        An Example could look like this

        .. code-block:: bash

            cmake .. -G "MinGW Makefiles"

        
    .. important::

        When using a multi-config Generator, i.e. Ninja Multi-Config, Visual Studio Generators, Xcode, 
        ``-DCMAKE_BUILD_TYPE=<Type>`` is not needed, and the build type is configured on compilation.
        
        Therefore, this cmake build command is used:

        .. code-block:: 

            cmake cmake --build . --config Release --target simulation

        Options for ``--config`` are **Release** and **Debug**. :raw-html:`</br>`
        Options for ``--target`` are **simulation**, **sanitize**, **test**, **sanitize_test** and **test_middle_states**.

    .. note::

        With the Option ``-D`` toggle options can be activated supported only by this ``CMakeLists.txt``.
        Available options are:

        +--------------------+--------------------------------------------------------------------------------------------------------------------+
        | Option             |  Description                                                                                                       |
        +====================+====================================================================================================================+
        | DISABLE_IO         | Completely disable any file IO i.e. Solutions, Stations and Checkpoints                                            |
        +--------------------+--------------------------------------------------------------------------------------------------------------------+
        | REPORT             | Enables the report out for the used compiler                                                                       |
        +--------------------+--------------------------------------------------------------------------------------------------------------------+

        To activate an option, the following must be written:
        
        .. code-block:: bash

            cmake .. -D <Option>=ON

        For Example:

        .. code-block:: bash

            cmake .. -D DISABLE_IO=ON

    Now our make files are being build from the ``CMakeLists.txt`` that are used to build the project.

7. Now we can build the project. The most desired command might be

    .. code-block:: bash

        cmake --build . --target simulation

    Options for ``--target`` are **simulation**, **sanitize**, **test**, **sanitize_test** and **test_middle_states**.

    +--------------------+--------------------------------------------------------------------------------------------------------------------+
    | Option             |  Description                                                                                                       |
    +====================+====================================================================================================================+
    | simulation         | Is the Option to build the project with default flags                                                              |
    +--------------------+--------------------------------------------------------------------------------------------------------------------+
    | sanitize           | Same as Option *simulation* but with sanitizers                                                                    |
    +--------------------+--------------------------------------------------------------------------------------------------------------------+
    | test               | Builds the unit test executable                                                                                    |
    +--------------------+--------------------------------------------------------------------------------------------------------------------+
    | sanitize_test      | Builds the unit test executable with sanitizer                                                                     |
    +--------------------+--------------------------------------------------------------------------------------------------------------------+
    | test_middle_states | Build the test against the middle_states.csv. :raw-html:`<br>`                                                     |
    |                    | Configuration can be edited at the top of the test_middle_states.cpp                                               |
    +--------------------+--------------------------------------------------------------------------------------------------------------------+

Running the Simulation & Tests
------------------------------

The executables have been build in to the ``../Tsunami-Simulation/build`` directory with their corresponding name.
E.g. If ``test`` is built than the executable name is ``test`` (or ``test.exe`` on Windows),
for ``simulation`` the executable name would be ``simulation`` (or ``simulation.exe`` on Windows), etc.

All the executables can be found in ``../Tsunami-Simulation/build``.
The available executables are ``simulation``, ``sanitize``, ``test``, ``sanitize_test`` and ``test_middle_states``.

.. note::
    They are only available when build with their respective ``--target``

E.g. the ``simulation`` executable can be run with the following command:

.. code-block::

    ./simulation

Or on Windows with

.. code-block::

    ./simulation.exe

.. tip::

    Running the ``simulation`` executable without arguments will give you the help text on how to use it.

Simulation Output
-----------------

The output of the simulation consists of one netCDF file if nothing else is specified. If you define the output format
as CSV several CSV files named ``solution_<number>.csv`` will be created. The files are stored in a separate
``solutions/simulation/`` folder, which is located in the working directory of the executable.

Extracting bathymetry data for the 1D domain
--------------------------------------------

1. Download `GEBCO_2021 <https://www.gebco.net/data_and_products/historical_data_sets/>`_ grid.

2. Reduce grid size with :raw-html:`</br>`
   :code:`gmt grdcut -R138/147/35/39 path/to/GEBCO_2021.nc -Gpath/to/GEBCO_2021_cut.nc`

3. Create datapoints with :raw-html:`</br>`
   :code:`gmt grdtrack -Gdpath/to/GEBCO_2021_cut.nc -E141.024949/37.316569/146/37.316569+i250e+d -Ar > bathy_profile.out`

4. Add commas to create comma-separated values file with :raw-html:`</br>`
   :code:`cat bathy_profile.out | tr -s '[:blank:]' ',' > bathy_profile.csv`

The ``bathy_profile.csv`` is located in: ``.../Tsunami-Simulation/resources/bathy_profile.csv``.