.. role:: raw-html(raw)
    :format: html

.. _submissions_large_data_input_output:

5. Large Data Input and Output
==============================


5.1 NetCDF Output
-----------------

1. Installation of netCDF
^^^^^^^^^^^^^^^^^^^^^^^^^

.. note::

    ``netCDF`` can be installed OS specific

        **Windows**

            1. `Download <https://docs.unidata.ucar.edu/netcdf-c/current/winbin.html>`_ and install the netCDF-C library and utilities

            2. Install as usual and make sure to ``add netCDF`` to the system ``PATH`` for all users

        **Linux and MAC**

            The easiest way to install netCDF is via `Homebrew <https://brew.sh/>`_. Run the following command in the terminal:

            .. code-block:: bash

                brew install netcdf

To use netCDF we have to include the directories and link the library to the whole project in the ``CMakeLists.txt``.
With ``find_package(netCDF REQUIRED)`` CMake will find the existing path and use it as reference.

    .. code-block:: bash

        find_package(netCDF REQUIRED)
        include_directories(${netCDF_INCLUDE_DIRS})
        link_libraries(${netCDF_LIBRARIES})

    Now we can use netCDF files in out project.


2. tsunami_lab::io::NetCdf::write
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

With the NetCdf constructor we set up our netCDF file. First we define our required dimensions.

The ``useSpherical`` boolean decides if we are using degrees or meters in our netCDF file as unit. The default value is
set to **true**. If the user wants to use meters he can set it with the ``-M`` flag at the beginning. The boolean is then
used in various ternary operators to set the value to the right one.

.. code-block:: cpp
    :emphasize-lines: 24-46

    // Header: NetCdf.h
    // File:   NetCdf.cpp
    // Test:   NetCdf.test.cpp

    tsunami_lab::io::NetCdf::NetCdf( std::string filePath,
                                     t_idx l_nx,
                                     t_idx l_ny,
                                     t_real l_scaleX,
                                     t_real l_scaleY,
                                     t_idx l_stride,
                                     bool useSpherical )
        : isReadMode( false )
    {
        m_filePath = filePath;
        m_nx = l_nx;
        m_ny = l_ny;
        m_scaleX = l_scaleX;
        m_scaleY = l_scaleY;
        m_stride = l_stride;
        int l_err;
        int m_dimIds[3];

        // set up netCDF-file
        l_err = nc_create( filePath.c_str(), // path
                           NC_CLOBBER,       // cmode
                           &m_ncId );        // ncidp
        checkNcErr( l_err, "create" );

        // define dimensions
        l_err = nc_def_dim( m_ncId,         // ncid
                            "time",         // name
                            NC_UNLIMITED,   // len
                            &m_dimTimeId ); // idp
        checkNcErr( l_err, "dimTime" );

        l_err = nc_def_dim( m_ncId,                           // ncid
                            useSpherical ? "longitude" : "X", // name
                            m_nx,                             // len
                            &m_dimXId );                      // idp
        checkNcErr( l_err, "dimX" );

        l_err = nc_def_dim( m_ncId,                           // ncid
                            useSpherical ? "latitude" : "Y",  // name
                            m_ny,                             // len
                            &m_dimYId );                      // idp
        checkNcErr( l_err, "dimY" );

        m_dimIds[0] = m_dimTimeId;
        m_dimIds[1] = m_dimYId;
        m_dimIds[2] = m_dimXId;
        [ ... ]


Next, we declare our variables:

.. code-block:: cpp

    [ ... ]
    l_err = nc_def_var( m_ncId,                            // ncid
                        useSpherical ? "longitude" : "X",  // name
                        NC_FLOAT,                          // xtype
                        1,                                 // ndims
                        &m_dimXId,                         // dimidsp
                        &m_xId );                          // varidp
    checkNcErr( l_err, "longitude" );

    l_err = nc_def_var( m_ncId,                           // ncid
                        useSpherical ? "latitude" : "Y",  // name
                        NC_FLOAT,                         // xtype
                        1,                                // ndims
                        &m_dimYId,                        // dimidsp
                        &m_yId );                         // varidp
    checkNcErr( l_err, "latitude" );

    l_err = nc_def_var( m_ncId,             // ncid
                        "time",             // name
                        NC_FLOAT,           // xtype
                        1,                  // ndims
                        &m_dimTimeId,       // dimidsp
                        &m_timeId );        // varidp
    checkNcErr( l_err, "timeId" );

    l_err = nc_def_var( m_ncId,             // ncid
                        "totalHeight",      // name
                        NC_FLOAT,           // xtype
                        3,                  // ndims
                        m_dimIds,           // dimidsp
                        &m_totalHeightId ); // varidp
    checkNcErr( l_err, "totalHeight" );

    l_err = nc_def_var( m_ncId,             // ncid
                        "bathymetry",       // name
                        NC_FLOAT,           // xtype
                        2,                  // ndims
                        m_dimIds + 1,       // dimidsp
                        &m_bathymetryId );  // varidp
    checkNcErr( l_err, "bathymetry" );

    l_err = nc_def_var( m_ncId,             // ncid
                        "momentumX",        // name
                        NC_FLOAT,           // xtype
                        3,                  // ndims
                        m_dimIds,           // dimidsp
                        &m_momentumXId );   // varidp
    checkNcErr( l_err, "momentumX" );

    l_err = nc_def_var( m_ncId,             // ncid
                        "momentumY",        // name
                        NC_FLOAT,           // xtype
                        3,                  // ndims
                        m_dimIds,           // dimidsp
                        &m_momentumYId );   // varidp
    checkNcErr( l_err, "momentumY" );
    [ ... ]


Now we have to define the global attributes and the units for a number of variables:

.. code-block:: cpp
    :emphasize-lines: 5, 12, 26, 33, 40, 47, 54

    [ ... ]
    // global attribute
    l_err = nc_put_att_text( m_ncId,
                             NC_GLOBAL,
                             "Conventions",
                             6,
                             "COARDS" );
    checkNcErr( l_err, "coards" );

    // Add units attribute to the variable
    l_err = nc_put_att_text( m_ncId,
                             m_timeId,
                             "units",
                             7,
                             "seconds" );
    checkNcErr( l_err, "seconds" );

    l_err = nc_put_att_text( m_ncId,
                             m_xId,
                             "units",
                             useSpherical ? 12 : 6,
                             useSpherical ? "degrees_east" : "meters" );
    checkNcErr( l_err, "degrees_east" );

    l_err = nc_put_att_text( m_ncId,
                             m_yId,
                             "units",
                             useSpherical ? 13 : 6,
                             useSpherical ? "degrees_north" : "meters" );
    checkNcErr( l_err, "degrees_north" );

    l_err = nc_put_att_text( m_ncId,
                             m_totalHeightId,
                             "units",
                             6,
                             "meters" );
    checkNcErr( l_err, "metersTotalHeight" );

    l_err = nc_put_att_text( m_ncId,
                             m_bathymetryId,
                             "units",
                             6,
                             "meters" );
    checkNcErr( l_err, "metersBathymetry" );

    l_err = nc_put_att_text( m_ncId,
                             m_momentumXId,
                             "units",
                             6,
                             "meters" );
    checkNcErr( l_err, "metersMomentumX" );

    l_err = nc_put_att_text( m_ncId,
                             m_momentumYId,
                             "units",
                             6,
                             "meters" );
    checkNcErr( l_err, "metersMomentumY" );

    l_err = nc_enddef( m_ncId ); // ncid
    checkNcErr( l_err, "enddef" );
    [ ... ]


Finally, in accordance with convention, we calculate the latitude and longitude values by converting metres to degrees
and write them to our netCDF file if we are using degrees as our unit:

.. code-block:: cpp

        [ ... ]
        // write longitude and latitude
        t_real stepLat = m_scaleY / ( l_ny - 1 );
        t_real stepLon = m_scaleX / ( l_nx - 1 );
        if( useSpherical )
        {
            t_real maxLat = m_scaleY / t_real( 110574 );
            t_real maxLon = m_scaleX / ( 111320 * std::cos( maxLat * M_PI / 180 ) );
            stepLat = maxLat / ( l_ny - 1 );
            stepLon = maxLon / ( l_nx - 1 );
        }
        t_real* lat = new t_real[l_ny];
        t_real* lon = new t_real[l_nx];

        for( size_t i = 0; i < l_ny; i++ )
        {
            lat[i] = i * stepLat;
        }
        for( size_t i = 0; i < l_nx; i++ )
        {
            lon[i] = i * stepLon;
        }

        l_err = nc_put_var_float( m_ncId,          // ncid
                                  m_yId,    // varid
                                  lat );           // op
        checkNcErr( l_err, "putLatitude" );

        l_err = nc_put_var_float( m_ncId,         // ncid
                                  m_xId,  // varid
                                  lon );          // op
        checkNcErr( l_err, "putLongitude" );

        delete[] lat;
        delete[] lon;
    }


The create file will now look like this (only example):

.. code-block:: bash

    netcdf WriteNetCDF.test {
    dimensions:
        time = UNLIMITED ; // (20 currently)
        longitude = 10 ;
        latitude = 10 ;
    variables:
        float longitude(longitude) ;
            longitude:units = "degrees_east" ;
        float latitude(latitude) ;
            latitude:units = "degrees_north" ;
        float time(time) ;
            time:units = "seconds" ;
        float totalHeight(time, latitude, longitude) ;
        float bathymetry(time, latitude, longitude) ;
        float momentumX(time, latitude, longitude) ;
        float momentumY(time, latitude, longitude) ;

    // global attributes:
            :Conventions = "COARDS" ;
    data:

     longitude = 0, 0.009981249, 0.0199625, 0.02994375, 0.03992499, 0.04990624,
        0.05988749, 0.06986874, 0.07984999, 0.08983123 ;

     latitude = 0, 0.01004857, 0.02009715, 0.03014572, 0.0401943, 0.05024287,
        0.06029145, 0.07034002, 0.0803886, 0.09043717 ;


Now we are implementing a function which allows to **write** the current time step to the created netCDF file.
The function gets the current simulation time and the following values of the cells: total height, bathymetry,
momentum in x direction and momentum in y direction. The check ``isReadMode`` ensures that we are using a netCDF
writer and not a reader (netCDF reader constructor is empty).

.. code-block:: cpp
    :emphasize-lines: 11, 25-65

    // Header: NetCdf.h
    // File:   NetCdf.cpp
    // Test:   NetCdf.test.cpp

    void tsunami_lab::io::NetCdf::write( const t_real simulationTime,
                                         const t_real* totalHeight,
                                         const t_real* bathymetry,
                                         const t_real* momentumX,
                                         const t_real* momentumY )
    {
        if( isReadMode )
        {
            std::cerr << "This netCdf object is not initialized in write mode. Read mode can only be used to read from files." << std::endl;
            exit( 2 );
        }

        int l_err;
        size_t start[3] = { m_time, 0, 0 };
        size_t count[3] = { 1, m_ny, m_nx };
        ptrdiff_t stride[3] = { 1, 1, 1 };
        ptrdiff_t map[3] = { 1, static_cast<ptrdiff_t>( m_stride ), 1 };
        size_t index[1] = { m_time }; // index should be same as current time dimension

        // write data
        l_err = nc_put_var1_float( m_ncId,              // ncid
                                   m_timeId,            // varid
                                   index,               // indexp
                                   &simulationTime );   // op
        checkNcErr( l_err, "putTime" );

        l_err = nc_put_varm_float( m_ncId,          // ncid
                                   m_totalHeightId, // varid
                                   start,           // startp
                                   count,           // countp
                                   stride,          // stridep
                                   map,             // imap
                                   totalHeight );   // op
        checkNcErr( l_err, "putTotalHeight" );

        l_err = nc_put_varm_float( m_ncId,          // ncid
                                   m_bathymetryId,  // varid
                                   start,           // startp
                                   count,           // countp
                                   stride,          // stridep
                                   map,             // imap
                                   bathymetry );    // op
        checkNcErr( l_err, "putBathymetry" );

        l_err = nc_put_varm_float( m_ncId,          // ncid
                                   m_momentumXId,   // varid
                                   start,           // startp
                                   count,           // countp
                                   stride,          // stridep
                                   map,             // imap
                                   momentumX );     // op
        checkNcErr( l_err, "putMomentumX" );

        l_err = nc_put_varm_float( m_ncId,          // ncid
                                   m_momentumYId,   // varid
                                   start,           // startp
                                   count,           // countp
                                   stride,          // stridep
                                   map,             // imap
                                   momentumY );     // op
        checkNcErr( l_err, "putMomentumY" );

        std::cout << " writing to '" << m_filePath << "'" << std::endl;

        ++m_time;
    }


5.2 NetCDF Input
-----------------

1. Artificial Tsunami 2D
^^^^^^^^^^^^^^^^^^^^^^^^

The class ``setups::ArtificialTsunami2d`` provides a hard-coded implementation of the Equation shown below.

.. math::

    \begin{aligned}
    \text{d}(x, y) & = & 5 \cdot f(x)g(y) \\
    \text{f}(x) & = & \sin\left(\left(\frac{x}{500}+1\right) \cdot \pi\right) \\
    \text{g}(y) & = & -\left(\frac{y}{500}\right)^2 + 1
    \end{aligned}

Therefore some basic settings are set in the constructor of the class.

.. code-block:: cpp
    :emphasize-lines: 5

    /// Header: ArtificialTsunami2d.h
    /// File:   ArtificialTsunami2d.cpp
    /// Test:   ArtificialTsunami2d.test.cpp
    tsunami_lab::setups::ArtificialTsunami2d::ArtificialTsunami2d()
        : bathymetryHeight( -100 ), centerOffset( 5000 )
    {
    }

The implementation of the equation is completely done in the ``getBathymetry`` function.
Where an if statement is used to check if the displacement needs to be applied.

.. code-block:: cpp
    :emphasize-lines: 5-12

    /// File: ArtificialTsunami2d.cpp
    tsunami_lab::t_real tsunami_lab::setups::ArtificialTsunami2d::getBathymetry( t_real i_x,
                                                                                 t_real i_y ) const
    {
        i_x -= centerOffset;
        i_y -= centerOffset;
        if( -500 <= i_x && i_x <= 500 && -500 <= i_y && i_y <= 500 )
        {
            t_real f = std::sin( ( i_x / 500 + 1 ) * M_PI );
            t_real g = -std::pow( i_y / 500, 2 ) + 1;
            return bathymetryHeight + 5 * f * g;
        }
        return bathymetryHeight;
    }


.. raw:: html

    <center>
        <video width="700" controls>
            <source src="../_static/videos/task_5_3_1.mp4" type="video/mp4">
        </video>
    </center>

2. Reading a netCDF
^^^^^^^^^^^^^^^^^^^

The reading is done by using the methods provided by the library ``netCDF``.
To provided a friendlier use the NetCdf class contains two read methods.

1. Reading one variable from the file:

    An input for a file path, a variable, a data output of the type ``NetCdf::VarArray`` and an optional timeStep are provided.
    The timeStep is used when data is read with a time dimension and the data set is to be read at a different time.
    The implementation forwards the input to an internally implemented read method, which is explained later.

    .. code-block:: cpp
        :emphasize-lines: 4-7

        /// Header: NetCdf.h
        /// File:   NetCdf.cpp
        /// Test:   NetCdf.test.cpp
        void tsunami_lab::io::NetCdf::read( const char* filepath,
                                            const char* variableName,
                                            VarArray& outData,
                                            size_t timeStep )
        {
            _read( filepath, &variableName, &outData, timeStep, 1 );
        }

2. Reading multiple variables from one file:

    A template is provided that forces the user to enter the same number of variables as containers are provided for the data.
    A file path and an optional timeStep are also specified here.
    The implementation forwards the input again to an internally implemented read method.

    .. code-block:: cpp
        :emphasize-lines: 1-5

        /// Header: NetCdf.h
        template <size_t N>
        void read( const char* filepath,
                   const char* ( &variableName )[N],
                   VarArray( &outData )[N],
                   size_t timeStep = 0 )
        {
            // NOTE: this function needs to be in the header because a template is used
            _read( filepath, variableName, outData, timeStep, N );
        }

**internal read method**

    First a check is done if the netCdf was created in read mode.
    Then a cleanup is done if a ``NetCdf::VarArray`` array is passed that already contains data.

    .. code-block:: cpp
        :emphasize-lines: 8, 16-19

        /// File: NetCdf.cpp
        void tsunami_lab::io::NetCdf::_read( const char* filepath,
                                            const char** variableName,
                                            VarArray* outData,
                                            size_t timeStep,
                                            size_t size )
        {
            if( !isReadMode )
            {
                std::cerr << "This netCdf object is not initialized in read mode. Write mode can only be used to write to a file." << std::endl;
                exit( 2 );
            }

            for( size_t i = 0; i < size; i++ )
            {
                if( outData[i].array != nullptr )
                {
                    outData[i].~VarArray();
                }
            }

            [...]


    Now the reading of the netCdf file can begin.
    To do this, the file is opened in non-write mode.
    And the longitude and latitude dimensions are read.
    The time dimension is only read if the timeStep is greater than zero and is therefore required to read the data at the correct location.

    Reading a dimension follows the same pattern, so it will only be explained for longitude.
    First, the variable to store the ID is created on the name that the netCdf uses as an alias for the longitude / x-axis.
    In this case, the aliases are ``lon``, ``longitude``, ``x``, ``X`` and a check is made to see if any of them are included in the file.
    If none of the alias names are contained, a corresponding netcdf error is output.
    A do-while loop is used to check the existence and the first matching dimension is used.
    The order of the alias names therefore plays a role.

    .. code-block:: cpp
        :emphasize-lines: 4-5
        
        /// File: NetCdf.cpp
        // open the file
        int ncID;
        l_err = nc_open( filepath, NC_NOWRITE, &ncID );
        checkNcErr( l_err, "readFile" );
        
        // check of lon, longitude, x, X and get the corresponding dimension size
        int lonID;
        const char* lonNames[] = { "lon", "longitude", "x", "X" };
        int lonNameSize = sizeof( lonNames ) / sizeof( char* );
        int lonNameIndex = 0;
        do
        {
            l_err = nc_inq_dimid( ncID, lonNames[lonNameIndex], &lonID );
        } while( l_err && ++lonNameIndex < lonNameSize );
        checkNcErr( l_err, "readLongitude" );
        
        size_t lonSize;
        l_err = nc_inq_dimlen( ncID, lonID, &lonSize );
        checkNcErr( l_err, "readLongitudeSize" );
        
        
        // check of lat, latitude, y, Y and get the corresponding dimension size
        int latID;
        const char* latNames[] = { "lat", "latitude", "y", "Y" };
        [...]
        
        // check of time, date, t, T and get the corresponding dimension size
        int timeID = -1;
        size_t timeSize = 1;
        if( timeStep != 0 )
        {
            const char* timeNames[] = { "time", "date", "t", "T" };
            [...]
        
            if( timeStep >= timeSize )
            {
                std::cerr << "ERROR: The Timestep can not be higher than the available time dimensions in this file (" << filepath << ")" << std::endl;
                exit( 2 );
            }
        };

    The specified variables are parsed using a for loop.
    First the ID is retrieved and the type of the variable is parsed, checked and saved.
    The nc_type ``NC_NAT`` leads to an error, as it cannot be represented by a suitable data type.
    Then the dimensions of the variable are parsed by retrieving the number of dimensions and all dimension IDs contained in the variable.
    In the next step, the length of the data array is calculated using if statements and a for loop and the timeStep for the start of the data set is saved.
    A warning is issued if the length of the data set is 1 or less.
    This is the case if a dimension is zero or the variable does not contain a longitude or latitude dimension.
    Finally, the corresponding typed array is created with a large switch statement and stored in ``NetCdf::VarArray``, which also handles the deletion of the arrays with a switch statement.
    
    .. code-block:: cpp
        :emphasize-lines: 7-8, 12-13, 15, 22, 26, 30-31, 41-42, 53-87, 90, 101
        
        /// File: NetCdf.cpp
        // get the variables with their data
        for( size_t i = 0; i < size; i++ )
        {
            // get the variable
            const char* name = variableName[i];
            int varID;
            l_err = nc_inq_varid( ncID, name, &varID );
            checkNcErr( l_err, "readVarID" );
    
            // get the variable type
            nc_type varType;
            l_err = nc_inq_vartype( ncID, varID, &varType );
            checkNcErr( l_err, "readVarType" );
            if( varType == NC_NAT )
            {
                std::cerr << "ERROR: The parsed type of the variable is NAT (Not a Type)" << variableName[i] << std::endl;
                exit( 2 );
            }
            else if( varType == NC_BYTE )
            {
                outData[i].type = VarType::CHAR;
            }
            else
            {
                outData[i].type = static_cast<VarType>( varType );
            }
    
            // get the number of dimensions included used by the variable
            int varDimCount;
            l_err = nc_inq_varndims( ncID, varID, &varDimCount );
            checkNcErr( l_err, "readVarDimCount" );
    
            if( varDimCount < 1 )
            {
                std::cerr << "The given variable (" << variableName[i] << ") does not have any dimensions" << std::endl;
                exit( 2 );
            }
    
            // get the dimensions id's from the variable
            int* varDims = new int[varDimCount];
            l_err = nc_inq_vardimid( ncID, varID, varDims );
            checkNcErr( l_err, "readVarDimCount" );
    
    
            // parse the dimensions and calculate length, count and start
            size_t length = 1;
            size_t stride = 1;
            size_t* start = new size_t[varDimCount]{ 0 };
            size_t* count = new size_t[varDimCount];
            std::fill_n( count, varDimCount, 1 );
    
            if( varDimCount >= 2 )
            {
                // COARDS standard require the dimension order T, Z, Y, X
                int i = varDimCount - 4;
                i *= ( i >= 0 );
    
                while( i < varDimCount )
                {
                    if( varDims[i] == timeID )
                    {
                        start[i] = timeStep;
                        break;
                    }
                    i++;
                }
    
                if( varDims[varDimCount - 2] == latID )
                {
                    count[varDimCount - 2] = latSize;
                    length *= latSize;
                }
            }
    
            if( varDims[varDimCount - 1] == latID )
            {
                count[varDimCount - 1] = latSize;
                length *= latSize;
                stride = latSize;
            }
            else if( varDims[varDimCount - 1] == lonID )
            {
                count[varDimCount - 1] = lonSize;
                length *= lonSize;
                stride = lonSize;
            }
    
            // Warning for small size
            if( length <= 1 )
            {
                const char* reset = "\033[0m";
                const char* yellow = "\033[33;49m";
    
                std::cout << yellow << "WARNING: one or less values were read from the variable " << variableName[i] << reset << std::endl;
            }
    
            // initialize the data storage for the variable
            outData[i].length = length;
            outData[i].stride = stride;
            switch( outData[i].type )
            {
                case VarType::CHAR:
                    outData[i].array = new char[length];
                    break;
                case VarType::SHORT:
                    outData[i].array = new short[length];
                    break;
                case VarType::INT:
                    outData[i].array = new int[length];
                    break;
                case VarType::FLOAT:
                    outData[i].array = new float[length];
                    break;
                case VarType::DOUBLE:
                    outData[i].array = new double[length];
                    break;
                case VarType::UCHAR:
                    outData[i].array = new unsigned char[length];
                    break;
                case VarType::USHORT:
                    outData[i].array = new unsigned short[length];
                    break;
                case VarType::UINT:
                    outData[i].array = new unsigned int[length];
                    break;
                case VarType::INT64:
                    outData[i].array = new int64_t[length];
                    break;
                case VarType::UINT64:
                    outData[i].array = new uint64_t[length];
                    break;
                case VarType::STRING:
                    outData[i].array = new std::string[length];
                    break;
            }
            l_err = nc_get_vara( ncID, varID, start, count, outData[i].array );
    
            // free memory
            delete[] varDims;
            delete[] start;
            delete[] count;
        }

    At last the netCdf file is closed and the read of the file is finished.

3. Tsunami Event 2d
^^^^^^^^^^^^^^^^^^^

.. _tsunami_event_2s_equation:

The ``TsunamiEvent2d`` class use two files to get the bathymetry and the displacement.
The following equation shows a quick overview which values the ``TsunamiEvent2d`` class returns.

.. math::

    \begin{split}\begin{split}
        h  &= \begin{cases}
                \max( -b_\text{in}, \delta), &\text{if } b_\text{in} < 0 \\
                0, &\text{else}
            \end{cases}\\
        hu &= 0\\
        hv &= 0\\
        b  &= \begin{cases}
                \min(b_\text{in}, -\delta) + d, & \text{ if } b_\text{in} < 0\\
                \max(b_\text{in}, \delta) + d, & \text{ else}.
            \end{cases}
    \end{split}\end{split}

The constructor loads the data from the bathymetry and displacement netcdf files using the discussed read method from the class ``tsunami_lab::io::NetCdf``.
Then the type of the data set is check, which should always be float and stored into the ``TsunamiEvent2d`` properties.

.. code-block:: cpp
    :emphasize-lines: 16, 18-20, 27, 29-31, 40-43

    /// Header: TsunamiEvent2d.h
    /// File:   TsunamiEvent2d.cpp
    /// Test:   TsunamiEvent2d.test.cpp
    tsunami_lab::setups::TsunamiEvent2d::TsunamiEvent2d( const char* bathymetryFilePath,
                                                        const char* ( &bathymetryVariable )[3],
                                                        const char* displacementFilePath,
                                                        const char* ( &displacementVariable )[3],
                                                        t_real scaleX,
                                                        t_real scaleY,
                                                        t_real delta )
        : scaleX( scaleX ), scaleY( scaleY ), delta( delta )
    {
        tsunami_lab::io::NetCdf reader = tsunami_lab::io::NetCdf();

        // read & check the bathymetry data
        reader.read( bathymetryFilePath, bathymetryVariable, bathymetryData );

        if( bathymetryData[0].type != tsunami_lab::io::NetCdf::FLOAT
            && bathymetryData[1].type != tsunami_lab::io::NetCdf::FLOAT
            && bathymetryData[2].type != tsunami_lab::io::NetCdf::FLOAT )
        {
            std::cerr << "The read data for bathymetry is not of type float" << std::endl;
            exit( 2 );
        }

        // read & check the displacement data
        reader.read( displacementFilePath, displacementVariable, displacementData );

        if( displacementData[0].type != tsunami_lab::io::NetCdf::FLOAT
            && displacementData[1].type != tsunami_lab::io::NetCdf::FLOAT
            && displacementData[2].type != tsunami_lab::io::NetCdf::FLOAT )
        {
            std::cerr << "The read data for displacement is not of type float" << std::endl;
            exit( 2 );
        }

        // assign the data to bathymetry and displacement
        for( size_t i = 0; i < 3; i++ )
        {
            bathymetry[i] = static_cast<float*>( bathymetryData[i].array );
            bathymetrySize[i] = bathymetryData[i].length;
            displacement[i] = static_cast<float*>( displacementData[i].array );
            displacementSize[i] = displacementData[i].length;
        }
    }

The ``getBathymetry`` function determines the cell closest to the passed coordinates and returns the bathymetry of the cell, with an additional displacement if applicable.
First the coordinate are scaled to fit on the bathymetry coordinate system.
Then the value of the closest bathymetry cell is retrieved using the function ``getValueAscending`` which will be explained later.
If the coordinates are inside the displacement area also value of the closest displacement cell is retrieved.
At least the the bathymetry with displacement is returned as stated in the `equation above <tsunami_event_2s_equation_>`_.

.. code-block:: cpp
    :emphasize-lines: 6-7, 10, 12-13, 15, 18

    /// File: TsunamiEvent2d.cpp
    tsunami_lab::t_real tsunami_lab::setups::TsunamiEvent2d::getBathymetry( t_real i_x,
                                                                            t_real i_y ) const
    {
        // calculate the x coordinate scaled to the bathymetry coordinate system.
        t_real x = i_x / scaleX * std::abs( bathymetry[0][0] - bathymetry[0][bathymetrySize[0] - 1] ) + bathymetry[0][0];
        t_real y = i_y / scaleY * std::abs( bathymetry[1][0] - bathymetry[1][bathymetrySize[1] - 1] ) + bathymetry[1][0];

        // obtain the closest value
        t_real b = getValueAscending( bathymetry, bathymetrySize, bathymetryData[2].stride, x, y );
        t_real d = 0;
        if( displacement[0][0] <= x && x <= displacement[0][displacementSize[0] - 1]
            && displacement[1][0] <= y && y <= displacement[1][displacementSize[1] - 1] )
        {
            d = getValueAscending( displacement, displacementSize, displacementData[2].stride, x, y );
        }

        return ( b < 0 ? std::min( b, delta ) : std::max( b, delta ) ) + d;
    }

The ``getHeight`` implementation is similar except that the displacement is not calculated and the `equation above <tsunami_event_2s_equation_>`_ states that as follows:

.. code-block:: cpp

    return ( b < 0 ) * std::max( -b, delta );


Let's take a look at the ``getValueAscending`` function, which has the task of finding the nearest cell.
First, the start and end pointers of the array are calculated.
Then we use the ``lower_bound`` function to find the position where we should place our element without changing the order of the array.
For example, the array ``{-1, 1, 2, 3, 5}`` with the value ``0.5``. The function ``lower_limit`` returns the pointer that currently contains the value ``1``.
Therefore, our value is between the address returned by lower_bound and the element before it, i.e. ``elementAddress`` and ``elementAddress - 1``.
Then we check if the function ``lower_bound`` was returned successfully.
Now we can retrieve the index by checking which of the two values is closer and performing a corresponding pointer arithmetic.
I.e. ``xIndex = ( std::abs( ( *xLower ) - x ) < std::abs( ( *xHigh ) - x ) ? xLower : xHigh ) - xBegin;`` where the part before the question mark compares the distance and then the index is calculated by subtracting the address begin.
This is done for the x and y direction.
Finally, we can calculate the index using the ``zStride`` and return the value found.


.. important::
    
    The array entered must be sorted in ascending order!

**getValueAscending**

    .. code-block:: cpp

        tsunami_lab::t_real tsunami_lab::setups::TsunamiEvent2d::getValueAscending( const t_real* const data[3],
                                                                                    const t_idx size[3],
                                                                                    const t_idx zStride,
                                                                                    const t_real x,
                                                                                    const t_real y ) const
        {
            // Because the x dimension and y dimension are sorted (ascending) the current x and y position can be found using a binary search (lower bound)
            const t_real* xBegin = data[0];
            const t_real* xEnd = xBegin + size[0];
            const t_real* yBegin = data[1];
            const t_real* yEnd = yBegin + size[1];
            const t_real* xHigh = std::lower_bound( xBegin, xEnd, x );
            const t_real* yHigh = std::lower_bound( yBegin, yEnd, y );
            const t_real* xLower = xHigh - 1; // can be done because array is sorted ascending
            const t_real* yLower = yHigh - 1;
        
            if( xHigh == xEnd || yHigh == yEnd )
            {
                std::cerr << "WARNING: Could not found lower bound. Defaulting to zero" << std::endl;
                return 0;
            }
        
            // calculate the index to get the data
            t_idx xIndex;
            t_idx yIndex;
            if( xHigh >= xEnd )
            {
                xIndex = xLower - xBegin;
            }
            else if( xLower < xBegin )
            {
                xIndex = xHigh - xBegin;
            }
            else
            {
                xIndex = ( std::abs( ( *xLower ) - x ) < std::abs( ( *xHigh ) - x ) ? xLower : xHigh ) - xBegin;
            }
            if( yHigh >= yEnd )
            {
                yIndex = xLower - xBegin;
            }
            else if( yLower < yBegin )
            {
                yIndex = yHigh - yBegin;
            }
            else
            {
                yIndex = ( std::abs( ( *yLower ) - y ) < std::abs( ( *yHigh ) - y ) ? yLower : yHigh ) - yBegin;
            }
            const t_idx index = yIndex * zStride + xIndex;
        
            if( index >= size[2] )
            {
                std::cerr << "WARNING: Index out of range. Defaulting to zero" << std::endl;
                return 0;
            }
        
            return data[2][index];
        }

4. Comparison
^^^^^^^^^^^^^

**Visualization of setups::ArtificialTsunami2d**

.. raw:: html

    <center>
        <video width="700" controls>
            <source src="../_static/videos/task_5_3_1.mp4" type="video/mp4">
        </video>
    </center>

**Visualization of setups::TsunamiEvent2d**

.. raw:: html

    <center>
        <video width="700" controls>
            <source src="../_static/videos/task_5_3_3.mp4" type="video/mp4">
        </video>
    </center>

Both are visualized with 1000x1000 cells over a simulation time of 300 seconds.

Contribution
------------

All team members contributed equally to the tasks.

