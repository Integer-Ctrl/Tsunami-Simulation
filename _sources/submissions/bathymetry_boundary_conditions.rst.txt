.. role:: raw-html(raw)
    :format: html

.. _submissions_bathymetry_boundary_conditions:

3. Bathymetry & Boundary Conditions
===================================

3.1. Non-zero Source Term
-------------------------

1. Extended f-wave solver
^^^^^^^^^^^^^^^^^^^^^^^^^

"Bathymetry is the topography of the ocean. We use sea level as a reference which means the bathymetry of a dry cell
(onshore) is zero or positive :math:`b_i \ge 0` and a wet cell (offshore) has a negative value :math:`b_j < 0`."[1]_

The term :math:`\Delta x \Psi_{i-1/2}` stands for the effect of the bathymetry:

.. math::

    \begin{split}\Delta x \Psi_{i-1/2} := \begin{bmatrix}
                                0 \\
                                -g (b_r - b_l) \frac{h_l+h_r}{2}
                              \end{bmatrix}.\end{split}

.. code-block:: cpp

    /// File:   FWave.cpp
    /// Header: FWave.h
    /// Test:   FWave.test.cpp
    [ ... ]
    void tsunami_lab::solvers::FWave::computeBathymetryEffects( t_real i_hL, t_real i_hR,
                                                                t_real i_bL, t_real i_bR,
                                                                t_real o_bathymetryEffect[2] )
    {
        o_bathymetryEffect[0] = 0;
        o_bathymetryEffect[1] = -m_g * ( i_bR - i_bL ) * ( t_real( 0.5 ) * ( i_hL + i_hR ) );
    }
    [ ... ]

To add bathymetry into the f-wave solver we need to take these into account in our flux function:

.. math::

    \Delta f - \Delta x \Psi_{i-1/2} =  \sum_{p=1}^2 Z_p.



.. code-block:: cpp
    :emphasize-lines: 10-15

    /// File:   FWave.cpp
    /// Header: FWave.h
    /// Test:   FWave.test.cpp
    [ ... ]
    // compute delta flux
    t_real deltaFlux[2];
    computeDeltaFlux( i_hL, i_hR, l_uL, l_uR, deltaFlux );

    //compute bathymetry
    t_real bathymetry[2];
    computeBathymetryEffects( i_hL, i_hR, i_bL, i_bR, bathymetry );
    t_real bathymetryDeltaFlux[2] = {
        deltaFlux[0] + bathymetry[0],
        deltaFlux[1] + bathymetry[1]
    };

    // compute eigencoefficients
    t_real eigencoefficient1 = 0;
    t_real eigencoefficient2 = 0;
    computeEigencoefficients( eigenvalue1, eigenvalue2, bathymetryDeltaFlux, eigencoefficient1, eigencoefficient2 );
    [ ... ]

2. Illustration of the effect of bathymetry
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

First we need to set the bathymetry to our ``WavePropagation1d``. Because bathymetry is only possible in the f-wave
solver, we have an if-statement in ``WavePropagation1d`` which checks whether bathymetry is present.
The return type ``Reflection`` is `explained later <explanation_of_type_reflection_>`_.

.. code-block:: cpp
    :emphasize-lines: 15, 32, 52-53, 62-63, 72-73

    /// File:   WavePropagation1d.cpp
    /// Header: WavePropagation1d.h
    /// Test:   WavePropagation1d.test.cpp
    [ ... ]
    tsunami_lab::patches::WavePropagation1d::WavePropagation1d( t_idx i_nCells )
    {
        m_nCells = i_nCells;

        // allocate memory including a single ghost cell on each side
        for( unsigned short l_st = 0; l_st < 2; l_st++ )
        {
            m_h[l_st] = new t_real[m_nCells + 2];
            m_hu[l_st] = new t_real[m_nCells + 2];
        }
        m_bathymetry = new t_real[m_nCells + 2]{ 0 };
        m_totalHeight = new t_real[m_nCells + 2]{ 0 };

        // init to zero
        for( unsigned short l_st = 0; l_st < 2; l_st++ )
        {
            for( t_idx l_ce = 0; l_ce < m_nCells + 2; l_ce++ )
            {
                m_h[l_st][l_ce] = 0;
                m_hu[l_st][l_ce] = 0;
            }
        }
    }
    [ ... ]
    void tsunami_lab::patches::WavePropagation1d::timeStep( t_real i_scaling )
    {
        [ ... ]
        if( hasBathymetry )
        {
            // iterate over edges and update with Riemann solutions
            for( t_idx l_ed = 0; l_ed < m_nCells + 1; l_ed++ )
            {
                // determine left and right cell-id
                t_idx l_ceL = l_ed;
                t_idx l_ceR = l_ed + 1;

                // noting to compute both shore cells
                if( l_hOld[l_ceL] == 0 && l_hOld[l_ceR] == 0 )
                {
                    continue;
                }

                // compute reflection
                t_real heightLeft;
                t_real heightRight;
                t_real momentumLeft;
                t_real momentumRight;
                t_real bathymetryLeft;
                t_real bathymetryRight;

                Reflection reflection = calculateReflection( l_hOld,
                                                             l_huOld,
                                                             l_ceL,
                                                             heightLeft,
                                                             heightRight,
                                                             momentumLeft,
                                                             momentumRight,
                                                             bathymetryLeft,
                                                             bathymetryRight );

                // compute net-updates
                t_real l_netUpdates[2][2];

                tsunami_lab::solvers::FWave::netUpdates( heightLeft,
                                                         heightRight,
                                                         momentumLeft,
                                                         momentumRight,
                                                         bathymetryRight,
                                                         bathymetryLeft,
                                                         l_netUpdates[0],
                                                         l_netUpdates[1] );

                // update the cells' quantities
                l_hNew[l_ceL] -= i_scaling * l_netUpdates[0][0] * ( Reflection::RIGHT != reflection );
                l_huNew[l_ceL] -= i_scaling * l_netUpdates[0][1] * ( Reflection::RIGHT != reflection );

                l_hNew[l_ceR] -= i_scaling * l_netUpdates[1][0] * ( Reflection::LEFT != reflection );
                l_huNew[l_ceR] -= i_scaling * l_netUpdates[1][1] * ( Reflection::LEFT != reflection );
            }
        }
        else
        {
            // uses a function pointer to choose between the solvers
            void ( *netUpdates )( t_real, t_real, t_real, t_real, t_real*, t_real* ) = solvers::FWave::netUpdates;
            if( solver == Solver::ROE )
            {
                netUpdates = solvers::Roe::netUpdates;
            }
            // iterate over edges and update with Riemann solutions
            for( t_idx l_ed = 0; l_ed < m_nCells + 1; l_ed++ )
            {
                // determine left and right cell-id
                t_idx l_ceL = l_ed;
                t_idx l_ceR = l_ed + 1;

                // noting to compute both shore cells
                if( l_hOld[l_ceL] == 0 && l_hOld[l_ceR] == 0 )
                {
                    continue;
                }

                // compute reflection
                t_real heightLeft;
                t_real heightRight;
                t_real momentumLeft;
                t_real momentumRight;

                Reflection reflection = calculateReflection( l_hOld,
                                                             l_huOld,
                                                             l_ceL,
                                                             heightLeft,
                                                             heightRight,
                                                             momentumLeft,
                                                             momentumRight );

                // compute net-updates
                t_real l_netUpdates[2][2];

                netUpdates( heightLeft,
                            heightRight,
                            momentumLeft,
                            momentumRight,
                            l_netUpdates[0],
                            l_netUpdates[1] );

                // update the cells' quantities
                l_hNew[l_ceL] -= i_scaling * l_netUpdates[0][0] * ( Reflection::RIGHT != reflection );
                l_huNew[l_ceL] -= i_scaling * l_netUpdates[0][1] * ( Reflection::RIGHT != reflection );

                l_hNew[l_ceR] -= i_scaling * l_netUpdates[1][0] * ( Reflection::LEFT != reflection );
                l_huNew[l_ceR] -= i_scaling * l_netUpdates[1][1] * ( Reflection::LEFT != reflection );
            }
        }
    }
    [ ... ]

And set our ghost cells :math:`b_0 := b_1` and :math:`b_{n+1} := b_n`.

.. code-block:: cpp
    :emphasize-lines: 12, 17

    /// File:   WavePropagation1d.cpp
    /// Header: WavePropagation1d.h
    /// Test:   WavePropagation1d.test.cpp
    void tsunami_lab::patches::WavePropagation1d::setGhostOutflow()
    {
        t_real* l_h = m_h[m_step];
        t_real* l_hu = m_hu[m_step];

        // set left boundary
        l_h[0] = l_h[1] * !hasReflection[Side::LEFT];
        l_hu[0] = l_hu[1];
        m_bathymetry[0] = m_bathymetry[1];

        // set right boundary
        l_h[m_nCells + 1] = l_h[m_nCells] * !hasReflection[Side::RIGHT];
        l_hu[m_nCells + 1] = l_hu[m_nCells];
        m_bathymetry[m_nCells + 1] = m_bathymetry[m_nCells];
    }
    [ ... ]

.. raw:: html

    <center>
        <video width="700" controls>
            <source src="../_static/videos/task_3_1_2.mp4" type="video/mp4">
        </video>
    </center>


3.2 Reflecting Boundary Conditions
----------------------------------

1. Implementation
^^^^^^^^^^^^^^^^^

The reflecting boundary condition is given for a wet cell :math:`\mathcal{C}_{i-1}` and dry cell :math:`\mathcal{C}_i` as:

.. math::

    h_{i} &:= h_{i-1} \\
    (hu)_{i} &:= -(hu)_{i-1} \\
    b_{i} &:= b_{i-1}

For the implementation, the case that :math:`\mathcal{C}_{i-1}` is dry and :math:`\mathcal{C}_i` is wet should also be taken into account.
Therefore the following implementation is provided.
For simulations without bathymetry, a similar implementation is provided that does not take bathymetry into account.

.. code-block:: cpp
    :emphasize-lines: 16-19, 21-24

    /// File:   WavePropagation1d.cpp
    /// Header: WavePropagation1d.h
    /// Test:   WavePropagation1d.test.cpp

    tsunami_lab::patches::WavePropagation1d::Reflection tsunami_lab::patches::WavePropagation1d::calculateReflection( t_real* i_h,
                                                                                                                      t_real* i_hu,
                                                                                                                      t_idx i_ceL,
                                                                                                                      t_real& o_heightLeft,
                                                                                                                      t_real& o_heightRight,
                                                                                                                      t_real& o_momentumLeft,
                                                                                                                      t_real& o_momentumRight,
                                                                                                                      t_real& o_bathymetryLeft,
                                                                                                                      t_real& o_bathymetryRight )
    {
        t_idx l_ceR = i_ceL + 1;
        bool leftReflection = ( i_h[l_ceR] == t_real( 0.0 ) );
        o_heightRight = leftReflection ? i_h[i_ceL] : i_h[l_ceR];
        o_momentumRight = leftReflection ? -i_hu[i_ceL] : i_hu[l_ceR];
        o_bathymetryRight = leftReflection ? m_bathymetry[i_ceL] : m_bathymetry[l_ceR];
    
        bool rightReflection = ( i_h[i_ceL] == t_real( 0.0 ) );
        o_heightLeft = rightReflection ? i_h[l_ceR] : i_h[i_ceL];
        o_momentumLeft = rightReflection ? -i_hu[l_ceR] : i_hu[i_ceL];
        o_bathymetryLeft = rightReflection ? m_bathymetry[l_ceR] : m_bathymetry[i_ceL];
    
        return static_cast<Reflection>( leftReflection * Reflection::LEFT + rightReflection * Reflection::RIGHT );
    }

.. _explanation_of_type_reflection:

The return of the reflection is provided by an enumeration where ``LEFT`` and ``RIGHT`` can be summed to return ``BOTH``.
If both cells are dry, the reflection and netUpdates do not need to be computed, i.e. there is no water to simulate with.
Therefore, a condition checks whether both cells are dry before calculating the reflection and netUpdate and skips this iteration if fulfilled.
This also leads to a better simulation time, as large blocks with dry cells are skipped completely.
The implementation of reflection is private inside ``WavePropagation1d`` as it is only used internally.

.. code-block:: cpp

    enum Reflection
    {
        NONE = 0,
        LEFT = 1,
        RIGHT = 2,
        BOTH = 3
    };


If a reflection occurs on one side of a cell, the height and momentum of the dry cell do not change, i.e.

.. code-block:: cpp

    l_hNew[l_ceL] -= i_scaling * l_netUpdates[0][0] * ( Reflection::RIGHT != reflection );
    l_huNew[l_ceL] -= i_scaling * l_netUpdates[0][1] * ( Reflection::RIGHT != reflection );

    l_hNew[l_ceR] -= i_scaling * l_netUpdates[1][0] * ( Reflection::LEFT != reflection );
    l_huNew[l_ceR] -= i_scaling * l_netUpdates[1][1] * ( Reflection::LEFT != reflection );

The reflection value indicates where the reflection would occur on the cell.
For example, the left cell is wet and the right cell is dry.
Then the reflection occurs on the left side of the dry cell and the reflection is set to ``LEFT``.

The reflection of the ghost cells is achieved by setting the water height to zero i.e. ``l_h[0] = l_h[1] * !hasReflection[Side::LEFT]``.

2. Visualization of right Boundary Reflection
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The water is initialized to the same height and momentum in all cells, as can be seen at the beginning of the video. 
When the video is played back, an increase of the water and a decrease in momentum can be seen on the right-hand side, as the water is reflected on the right-hand side of the boundary.
The outgoing momentum and the incoming momentum cancel each other out so that the momentum becomes zero.

.. raw:: html
    
    <center>
        <video width="700" controls>
            <source src="../_static/videos/task_3_2_2.mp4" type="video/mp4">
        </video>
    </center>


3.3. Hydraulic Jumps
--------------------

Hydraulic jumps behavior in shallow water theory can be characterized by the Froude number.

.. math::

    F := \frac{u}{\sqrt{gh}}


"We call regions with :math:`F < 1` subcritical, :math:`F \approx 1` critical and :math:`F > 1` supercritical."[2]_

1. Maximum Froude number
^^^^^^^^^^^^^^^^^^^^^^^^

**Subcritical flow**

The velocity can be calculated with the momentum and height as follows:

.. math::

    \begin{aligned}

        u(x) &= \frac{hu(x)}{h(x)}\\
        &=
        \begin{cases}
            \frac{4.42}{1.8 + 0.05 (x-10)^2} \quad   &\text{if } x \in (8,12) \\
            \frac{4.42}{2} \quad &\text{else}
        \end{cases}\\

    \end{aligned}

Using the conditional velocity the Froude number can be calculated in the range of (8, 12) and outside that range:

.. math::

    \begin{aligned}

        \text{For } x\in (8, 12): &\\
        F(x) &= \frac{4.42}{(1.8 + 0.05 (x - 10)^2) \cdot \sqrt{9.80665 \cdot (1.8 + 0.05 (x - 10)^2)}}\\
        &= \frac{1.41144}{(0.05 (x-10)^2 + 1.8)^{3/2}}\\

    \end{aligned}

The Froude number within the range (8, 12) has a quadratic equation with a positive gradient in the denominator, so that the maximum can be found by derivation:

.. math::

    \begin{aligned}

        F'(x) &= \frac{0.211716 (x - 10)}{(0.05 (x - 10)^2 + 1.8)^{5/2}}\\
        F'(x_1) &= 0 \\
        x_1 &= 10 \\
        F(10) &\approx 0.58445782

    \end{aligned}

The Froude number outside the range (8, 12) is calculated by:

.. math::

    \begin{aligned}

        \text{For } x\notin (8, 12): &\\
        F(x) &= \frac{4.42}{2 \sqrt{9.80665 \cdot 2}} \approx 0.49901884

    \end{aligned}


Therefore, the maximum Froude number of the subcritical flow is 0.58445782.


**Supercritical flow**

The velocity can again be calculated with momentum and height as follows:

.. math::

    \begin{aligned}

        u(x) &= \frac{hu(x)}{h(x)}\\
        &=
        \begin{cases}
            \frac{0.18}{0.13 + 0.05 (x-10)^2} \quad   &\text{if } x \in (8,12) \\
            \frac{0.18}{0.33} \quad &\text{else}
        \end{cases}\\

    \end{aligned}

Using the conditional velocity the Froude number can be calculated in the range of (8, 12) and outside that range:

.. math::

    \begin{aligned}

        \text{For } x\in (8, 12): &\\
        F(x) &= \frac{0.18}{(0.13 + 0.05 (x - 10)^2) \sqrt{9.80665 \cdot (0.13 + 0.05 (x - 10)^2)}}\\
        &= \frac{0.0574794}{(0.05 (x-10)^2 + 0.13)^{3/2}}\\

    \end{aligned}

Again the Froude number within the range (8, 12) has a quadratic equation with a positive gradient in the denominator, so that the maximum can be found by derivation:

.. math::

    \begin{aligned}

        F'(x) &= \frac{0.00862191 (x - 10)}{(0.05 (x - 10)^2 + 0.13)^{5/2}}\\
        F'(x_1) &= 0\\
        x_1 = 10\\
        F(10) &\approx 1.2263012

    \end{aligned}

The Froude number outside the range (8, 12) is calculated by:

.. math::

    \begin{aligned}

        \text{For } x\notin (8, 12): &\\
        F(x) &= \frac{0.18}{0.33 \sqrt{9.80665 \cdot 0.33}} \approx 0.30320842

    \end{aligned}


Therefore, the maximum Froude number of the subcritical flow is 1.2263012.

2. Implementation into Setups
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The implementation in setups is done using a subclass of ``setup::Setup.h`` where the default constructor setups the initial **supercritical** and **subcritical** flow examples.

+-------------------------------------------------------------------------------+----------------------------------------------------------------------------+
|:raw-html:`<center>Subcritical Flow</center>`                                  |:raw-html:`<center>Supercritical Flow</center>`                             |
+===============================================================================+============================================================================+
|                                                                               |                                                                            |
|   .. math::                                                                   | .. math::                                                                  |
|       \begin{split}\begin{aligned}                                            |    \begin{split}\begin{aligned}                                            |
|           b(x) &=                                                             |       b(x) &=                                                              |
|               \begin{cases}                                                   |           \begin{cases}                                                    |
|                   -1.8 - 0.05 (x-10)^2 \quad   &\text{if } x \in (8,12) \\    |               -0.13 - 0.05 (x-10)^2 \quad   &\text{if } x \in (8,12) \\    |
|                   -2 \quad &\text{else}                                       |               -0.33 \quad &\text{else}                                     |
|               \end{cases}\\                                                   |           \end{cases}\\                                                    |
|           h(x, 0) &= -b(x) \quad \text{if } x \in [0,25] \\                   |       h(x, 0) &= -b(x) \quad \text{if } x \in [0,25] \\                    |
|           hu(x, 0) &= 4.42 \quad \text{if } x \in [0,25].                     |       hu(x, 0) &= 0.18 \quad \text{if } x \in [0,25].                      |
|       \end{aligned}\end{split}                                                |    \end{aligned}\end{split}                                                |
|                                                                               |                                                                            |
+-------------------------------------------------------------------------------+----------------------------------------------------------------------------+

The implementation is similar in both cases, for the subcritical flow the code is shown below.
To calculate the bathymetry as a function of the x-coordinate, a function pointer is used to which a lambda is assigned.

.. code-block:: cpp
    :emphasize-lines: 8-11
    
    /// File:   SubcriticalFlow1d.cpp
    /// Header: SubcriticalFlow1d.h
    /// Test:   SubcriticalFlow1d.test.cpp

    tsunami_lab::setups::SubcriticalFlow1d::SubcriticalFlow1d()
        : momentum( 4.42 ), range{ 8, 12 }, bathymetryOutRange( -2 )
    {
        bathymetryInRange = []( t_real x ) -> t_real
            {
                return -1.8 - 0.05 * ( x - 10 ) * ( x - 10 );
            };
    }

Also an extra constructor is provided with four argument (``t_real momentum``, ``t_real range``, ``t_real bathymetryOutRange``, ``t_real( *bathymetryInRange )( t_real )``) to provide an interface for custom supercritical & subcritical flow setups.
Therefore, the function pointer is needed to calculate the bathymetry and water height depending on the x-coordinate.

The bathymetry is returned based on the range with its stored bathymetry i.e.

.. code-block:: cpp
    :emphasize-lines: 4-8

    tsunami_lab::t_real tsunami_lab::setups::SubcriticalFlow1d::getBathymetry( t_real i_x,
                                                                               t_real ) const
    {
        if( range[0] < i_x && i_x < range[1] )
        {
            return bathymetryInRange( i_x );
        }
        return bathymetryOutRange;
    }


The Output of both are visualized below:

**Subcritical Flow**

At about 2 seconds at 2000 a small dent can be seen in the total height.

.. raw:: html
    
    <center>
        <video width="700" controls>
            <source src="../_static/videos/subcritical_flow.mp4" type="video/mp4">
        </video>
    </center>

**Supercritical Flow**

Between 1 and 5 seconds at about 2350, a large gap forms in the total height and the momentum begins to oscillate.

.. raw:: html

    <center>
        <video width="700" controls>
            <source src="../_static/videos/supercritical_flow.mp4" type="video/mp4">
        </video>
    </center>

3. Hydraulic Jump
^^^^^^^^^^^^^^^^^

The hydraulic jump in the supercritical solution can be seen around 2350, but the f-wave solver fails to converge to a constant momentum.
Therefore, a peak in momentum can be seen around 2350.

3.4. 1D Tsunami Simulation
--------------------------

1. Extracting bathymetry data for the 1D domain
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1. Download `GEBCO_2021 <https://www.gebco.net/data_and_products/historical_data_sets/>`_ grid.

2. Reduce grid size with :raw-html:`</br>`
   :code:`gmt grdcut -R138/147/35/39 path/to/GEBCO_2021.nc -Gpath/to/GEBCO_2021_cut.nc`

3. Create datapoints with :raw-html:`</br>`
   :code:`gmt grdtrack -Gdpath/to/GEBCO_2021_cut.nc -E141.024949/37.316569/146/37.316569+i250e+d -Ar > bathymetry_profile.out`

4. Add commas to create comma-separated values file with :raw-html:`</br>`
   :code:`cat bathymetry_profile.out | tr -s '[:blank:]' ',' > bathymetry_profile.csv`

The ``bathymetry_profile.csv`` is located in: ``.../Tsunami-Simulation/resources/bathymetry_profile.csv``.


2. Extend **tsunami_lab::io::Csv** to read bathymetry_profile.csv
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: cpp
    :emphasize-lines: 26-29, 32

    /// File:   Csv.cpp
    /// Header: Csv.h
    /// Test:   Csv.test.cpp
    bool tsunami_lab::io::Csv::readBathymetry( std::ifstream& stream,
                                               t_real& o_hBathymetry)
    {
        std::string line;

        // read next complete line
        while( std::getline( stream, line ) )
        {
            // skip commented lines
            if( line[0] == '#' )
            {
                continue;
            }

            // parse lines divided by ',' to single values
            std::istringstream lineStream( line );
            std::string longitude;
            std::getline( lineStream, longitude, ',' );
            std::string latitude;
            std::getline( lineStream, latitude, ',' );
            std::string location;
            std::getline( lineStream, location, ',' );
            std::string h_bathymetry;
            std::getline( lineStream, h_bathymetry, ',' );
            o_hBathymetry = atof( h_bathymetry.c_str() );
            return true;
        }
        // no lines left to read
        return false;
    }

This implementation offers scope for reading further data from the file in the future.


3. New setup **setups::TsunamiEvent1d**
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In the first highlighted block we initialize a vector with the bathymetry height entries of the bathymetry_profile.csv.
In total, we then have the values of :code:`m_bathymetry.size()` many data points and a maximum index of ``m_csvDataPoint``.

If the x-coordinate of the queried point is not exactly at the same position as a bathymetry value, a more suitable
bathymetry is calculated for this x-coordinate by linear interpolation. This is done in the second and third highlighted
code-block.

The mathematical formulas

.. math::

    \begin{split}\begin{split}
        h  &= \begin{cases}
                \max( -b_\text{in}, \delta), &\text{if } b_\text{in} < 0 \\
                0, &\text{else}
              \end{cases}\\
        hu &= 0\\
        b  &= \begin{cases}
                \min(b_\text{in}, -\delta) + d, & \text{ if } b_\text{in} < 0\\
                \max(b_\text{in}, \delta) + d, & \text{ else}.
              \end{cases}
    \end{split}\end{split}

can be easily transferred to code.

:math:`b_\text{in}(x) \in \mathbb{R}` is the bathymetry axtracted from the DEM and :math:`d(x) \in \mathbb{R}` is the
vertical displacement. The constant :math:`\delta \in \mathbb{R}^+` avoids running into numerical issues due to missing
support for wetting and drying in our solver.

.. code-block:: cpp
    :emphasize-lines: 13-17, 24-29, 54-59

    /// File:   TsunamiEvent1d.cpp
    /// Header: TsunamiEvent1d.h
    /// Test:   TsunamiEvent1d.test.cpp
    tsunami_lab::setups::TsunamiEvent1d::TsunamiEvent1d( std::string filePath,
                                                         tsunami_lab::t_real i_delta,
                                                         tsunami_lab::t_real i_scale )
    {
        m_delta = i_delta;
        m_scale = i_scale;

        t_real o_hBathymetry = 0;
        std::ifstream bathymetry_profile( filePath );
        while( tsunami_lab::io::Csv::readBathymetry( bathymetry_profile, o_hBathymetry ) )
        {
            m_bathymetry.push_back( o_hBathymetry );
        }
        m_csvDataPoint = m_bathymetry.size() - 1;
    }

    tsunami_lab::t_real tsunami_lab::setups::TsunamiEvent1d::getHeight( tsunami_lab::t_real i_x,
                                                                        tsunami_lab::t_real ) const
    {
        // linear interpolation between two bathymetries
        t_real l_x = ( i_x / m_scale ) * m_csvDataPoint;
        t_idx indexL = std::floor( l_x );
        t_idx indexR = std::ceil( l_x );
        t_real l_bathymetryL = m_bathymetry[indexL];
        t_real l_bathymetryR = m_bathymetry[indexR];
        t_real l_bathymetry = ( l_bathymetryR - l_bathymetryL ) * ( l_x - indexL ) + l_bathymetryL;

        if( l_bathymetry < 0 )
        {
            return -l_bathymetry < m_delta ? m_delta : -l_bathymetry;
        }
        return 0;
    }

    tsunami_lab::t_real tsunami_lab::setups::TsunamiEvent1d::getMomentumX( tsunami_lab::t_real,
                                                                           tsunami_lab::t_real ) const
    {
        return m_momentum;
    }

    tsunami_lab::t_real tsunami_lab::setups::TsunamiEvent1d::getMomentumY( tsunami_lab::t_real,
                                                                           tsunami_lab::t_real ) const
    {
        return 0;
    }

    tsunami_lab::t_real tsunami_lab::setups::TsunamiEvent1d::getBathymetry( tsunami_lab::t_real i_x,
                                                                            tsunami_lab::t_real ) const
    {
        // linear interpolation between two bathymetries
        t_real l_x = ( i_x / m_scale ) * m_csvDataPoint;
        t_idx indexL = std::floor( l_x );
        t_idx indexR = std::ceil( l_x );
        t_real l_bathymetryL = m_bathymetry[indexL];
        t_real l_bathymetryR = m_bathymetry[indexR];
        t_real l_bathymetry = ( l_bathymetryR - l_bathymetryL ) * ( l_x - indexL ) + l_bathymetryL;
        t_real verticalDisplacement = getVerticalDisplacement( i_x, 0 );

        if( l_bathymetry < 0 )
        {
            return l_bathymetry < -m_delta ? l_bathymetry + verticalDisplacement : -m_delta + verticalDisplacement;
        }
        return l_bathymetry < m_delta ? m_delta + verticalDisplacement : l_bathymetry + verticalDisplacement;
    }

    tsunami_lab::t_real tsunami_lab::setups::TsunamiEvent1d::getVerticalDisplacement( tsunami_lab::t_real i_x,
                                                                                      tsunami_lab::t_real ) const
    {
        if( 175000 < i_x && i_x < 250000 )
        {
            return 1000 * std::sin( ( ( i_x - 175000 ) / 37500 * M_PI ) + M_PI );
        }
        return 0;
    }


4. Visualization of the TsunamiEvent1d setup
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

l_endTime...time to simulate = 2000 :raw-html:`</br>`
l_scale...length of the x-axis on which the simulation runs = 440000

Result with 10000 cells. To achieve a better visualization, the vertical displacement is scaled with 1000 instead of 10.

.. math::

    \begin{split}d(x) = \begin{cases}
         1000\cdot\sin(\frac{x-175000}{37500} \pi + \pi), & \text{ if } 175000 < x < 250000 \\
         0, &\text{else}.
       \end{cases}\end{split}


.. raw:: html

    <center>
        <video width="700" controls>
            <source src="../_static/videos/task_3_4_4.mp4" type="video/mp4">
        </video>
    </center>



Contribution
------------

All team members contributed equally to the tasks.

.. [1] From https://scalable.uni-jena.de/opt/tsunami/chapters/assignment_3.html#non-zero-source-term (17.11.2023)

.. [2] From https://scalable.uni-jena.de/opt/tsunami/chapters/assignment_3.html#hydraulic-jumps (10.11.2023)