.. role:: raw-html(raw)
    :format: html

.. _submissions_finite_volume_discretization:

2. Finite Volume Discretization
===============================


F-Wave Integration
------------------

Switching between the solvers is done by an enum, which is always included when a class is derived from ``tsunami_lab::patches::WavePropagation``.
To achieve this, the enumeration is included in the header file of ``WavePropagation``.

.. code-block:: cpp
    :emphasize-lines: 9-13, 27

    /// File: WavePropagation.h
    namespace tsunami_lab {
        namespace patches {
            class WavePropagation;

            /**
            * solver options for wave propagation.
            */
            enum Solver
            {
                FWave,
                Roe
            };
        }
    }

    class tsunami_lab::patches::WavePropagation {

    public:
        [ ... ]

        /**
        * Set the solver for the netUpdate
        * 
        * @param solver used solver
        */
        virtual void setSolver(Solver solver) = 0;
    };


The implementation for setting the solver is done via a simple set function and the solver is set to the FWave solver by default. :raw-html:`<br>`
Switching between the solvers is done via a function pointer of netUpdates to avoid calling an if statement in the for loop and to enable a more efficient calculation. 

.. code-block:: cpp
    :emphasize-lines: 6, 16-19, 26-30

    /// File: WavePropagation1d.h
    class tsunami_lab::patches::WavePropagation1d: public WavePropagation {
    private:
        [ ... ]
        //! the solver used for the netUpdates
        Solver solver = Solver::FWave;

    public:
        [ ... ]      
        /**
        * Set the solver for the netUpdate
        * Default: FWave
        * 
        * @param solver used solver
        */
        void setSolver(Solver solver)
        {
            WavePropagation1d::solver = solver;
        }
    };

    /// File: WavePropagation1d.cpp
    void tsunami_lab::patches::WavePropagation1d::timeStep( t_real i_scaling ) {
        [ ... ]
        // uses a function pointer to choose between the solvers
        void (*netUpdates)(t_real, t_real, t_real, t_real, t_real*, t_real*) = solvers::FWave::netUpdates;
        if (solver == Solver::Roe)
        {
            netUpdates = solvers::Roe::netUpdates;
        }
        [ ... ]
    }


Middle States
-------------

Setting up constants to control the middle states tests.

.. code-block:: cpp

    /// File: test_middle_states.cpp
    const tsunami_lab::t_idx numberOfCells = 10;
    const unsigned int numberOfTests = 1000000;
    const double testAccuracy = 0.99;
    const double accuracyMargin = 0.0001;
    const tsunami_lab::patches::Solver solver = tsunami_lab::patches::Solver::FWave;


Reading the middleStates.csv by implementing a new function to ``tsunami_lab::io::Csv``.
The function is using a file stream to middleStates.csv and parses a new line when called.

.. code-block:: cpp

    /// File: Csv.cpp
    bool tsunami_lab::io::Csv::next_middle_states ( std::ifstream & stream,
                                                    t_real & o_hLeft,
                                                    t_real & o_hRight,
                                                    t_real & o_huLeft,
                                                    t_real & o_huRight,
                                                    t_real & o_hStar )
    {
        std::string line; 

        // read next complete line
        while (std::getline(stream, line))
        {
            // skip commented lines
            if (line[0] == '#')
            {
            continue;
            }

            // parse lines divided by ',' to single values
            std::istringstream lineStream(line);
            std::string hLeft;
            std::getline(lineStream, hLeft, ',');
            o_hLeft = atof(hLeft.c_str());
            std::string hRight;
            std::getline(lineStream, hRight, ',');
            o_hRight = atof(hRight.c_str());
            std::string huLeft;
            std::getline(lineStream, huLeft, ',');
            o_huLeft = atof(huLeft.c_str());
            std::string huRight;
            std::getline(lineStream, huRight, ',');
            o_huRight = atof(huRight.c_str());
            std::string hStar;
            std::getline(lineStream, hStar);
            o_hStar = atof(hStar.c_str());
            return true;
        }
        // no lines left to read
        return false;
    }


Creating a new test case to run with a Catch2 session. :raw-html:`<br>`
Using the new CSV function to parse the file lines and check if the file can be read in a while loop.

.. code-block:: cpp

    /// File: test_middle_states.cpp
    TEST_CASE( "Test against the middle_states.csv", "[MiddleStates]" )
    {
        // Read the middle_states.csv
        std::ifstream middle_states( "resources/middle_states.csv" );

        unsigned int successfullTests = 0;
        unsigned int evaluatedTests = 0;

        // parese each line of the middle_states.csv and test against the simulation
        tsunami_lab::t_real hLeft, hRight, huLeft, huRight, hStar;
        while( evaluatedTests < numberOfTests
            && tsunami_lab::io::Csv::next_middle_states( middle_states,
                                                         hLeft,
                                                         hRight,
                                                         huLeft,
                                                         huRight,
                                                         hStar ) )
        {
        [ ... ]


Implementing a new setup for the middle states to return the matching height and momentum for the corresponding x-coordinate.

.. code-block:: cpp

    /// File: MiddleStates1d.cpp
    #include "../../include/setups/MiddleStates1d.h"
    #include "../../include/constants.h"

    tsunami_lab::setups::MiddleStates1d::MiddleStates1d( t_real i_heightLeft, t_real i_heightRight, t_real i_momentumLeft, t_real i_momentumRight, t_real i_location )
    {
        m_heightLeft = i_heightLeft;
        m_heightRight = i_heightRight;
        m_momentumLeft = i_momentumLeft;
        m_momentumRight = i_momentumRight;
        m_location = i_location;
    }

    tsunami_lab::t_real tsunami_lab::setups::MiddleStates1d::getHeight( t_real i_x, t_real ) const
    {
        if( i_x <= m_location )
        {
            return m_heightLeft;
        }
        else
        {
            return m_heightRight;
        }
    }

    tsunami_lab::t_real tsunami_lab::setups::MiddleStates1d::getMomentumX( t_real i_x, t_real ) const
    {
        if( i_x <= m_location )
        {
            return m_momentumLeft;
        }
        else
        {
            return m_momentumRight;
        }
    }

    tsunami_lab::t_real tsunami_lab::setups::MiddleStates1d::getMomentumY( t_real, t_real ) const
    {
        return 0;
    }


Adding the new setup to the Catch2 unit tests.

.. code-block:: cpp

    /// File: MiddleStates1d.test.cpp
    #include <catch2/catch.hpp>
    #include "../../include/setups/MiddleStates1d.h"

    TEST_CASE( "Test the one-dimensional MiddleStates setup.", "[MiddleStates1d]" )
    {
        tsunami_lab::setups::MiddleStates1d l_middleStates( 25,
                                                            12,
                                                            35,
                                                            123,
                                                            3 );

        // left side
        REQUIRE( l_middleStates.getHeight( 2, 0 ) == 25 );

        REQUIRE( l_middleStates.getMomentumX( 2, 0 ) == 35 );

        REQUIRE( l_middleStates.getMomentumY( 2, 0 ) == 0 );

        REQUIRE( l_middleStates.getHeight( 2, 5 ) == 25 );

        REQUIRE( l_middleStates.getMomentumX( 2, 5 ) == 35 );

        REQUIRE( l_middleStates.getMomentumY( 2, 2 ) == 0 );

        // right side
        REQUIRE( l_middleStates.getHeight( 4, 0 ) == 12 );

        REQUIRE( l_middleStates.getMomentumX( 4, 0 ) == 123 );

        REQUIRE( l_middleStates.getMomentumY( 4, 0 ) == 0 );

        REQUIRE( l_middleStates.getHeight( 4, 5 ) == 12 );

        REQUIRE( l_middleStates.getMomentumX( 4, 5 ) == 123 );

        REQUIRE( l_middleStates.getMomentumY( 4, 2 ) == 0 );
    }

Setting up the testing with the new setup ``MiddleStates1d`` and calculating the hStar by calculating over multiple time steps.
Printing an Error message if the deviation of the calculated hStar and the read hStar is too high.
After going through all test the number of successful tests, accuracy and cell settings are printed.
At the end Catch2 test throws an error if the accuracy is too low.

.. code-block:: cpp

        /// File: test_middle_states.cpp
        [ ... ]
		    tsunami_lab::t_real l_dxy = 10.0 / numberOfCells;
		    tsunami_lab::t_real l_location = 5.0;
		    tsunami_lab::t_real startHeightDifference = abs( hLeft - hRight );

		    // construct setup
		    tsunami_lab::setups::Setup* l_setup = new tsunami_lab::setups::MiddleStates1d( hLeft, hRight, huLeft, huRight, l_location );

		    // construct solver
		    tsunami_lab::patches::WavePropagation* l_waveProp;
		    l_waveProp = new tsunami_lab::patches::WavePropagation1d( numberOfCells );

		    // set the solver to use
		    l_waveProp->setSolver( solver );

		    // maximum observed height in the setup
		    tsunami_lab::t_real l_hMax = std::numeric_limits< tsunami_lab::t_real >::lowest();

		    // set up solver
		    for( tsunami_lab::t_idx l_cy = 0; l_cy < numberOfCells; l_cy++ )
		    {
			    tsunami_lab::t_real l_y = l_cy * l_dxy;

			    for( tsunami_lab::t_idx l_cx = 0; l_cx < numberOfCells; l_cx++ )
			    {
				    tsunami_lab::t_real l_x = l_cx * l_dxy;

				    // get initial values of the setup
				    tsunami_lab::t_real l_h = l_setup->getHeight( l_x,
															      l_y );
				    l_hMax = std::max( l_h, l_hMax );

				    tsunami_lab::t_real l_hu = l_setup->getMomentumX( l_x,
																      l_y );
				    tsunami_lab::t_real l_hv = l_setup->getMomentumY( l_x,
																      l_y );

				    // set initial values in wave propagation solver
				    l_waveProp->setHeight( l_cx,
									       l_cy,
									       l_h );

				    l_waveProp->setMomentumX( l_cx,
										      l_cy,
										      l_hu );

				    l_waveProp->setMomentumY( l_cx,
										      l_cy,
										      l_hv );

			    }
		    }

		    // derive maximum wave speed in setup; the momentum is ignored
		    tsunami_lab::t_real l_speedMax = std::sqrt( 9.81 * l_hMax );

		    // derive constant time step; changes at simulation time are ignored
		    tsunami_lab::t_real l_dt = 0.5 * l_dxy / l_speedMax;

		    // derive scaling for a time step
		    tsunami_lab::t_real l_scaling = l_dt / l_dxy;

		    // set up time and print control
		    tsunami_lab::t_idx  l_timeStep = 0;
		    tsunami_lab::t_real l_endTime = 1.25;
		    tsunami_lab::t_real l_simTime = 0;

		    // iterate over time
		    while( l_simTime < l_endTime )
		    {
			    l_waveProp->setGhostOutflow();
			    l_waveProp->timeStep( l_scaling );

			    l_timeStep++;
			    l_simTime += l_dt;
		    }

		    // test hStar against read value from middle_states.csv
		    tsunami_lab::t_idx l_iy = 1;
		    tsunami_lab::t_idx i_stride = 1;
		    tsunami_lab::t_idx l_id = l_iy * i_stride + static_cast<tsunami_lab::t_real>( l_location * l_dxy );
		    const tsunami_lab::t_real* heights = l_waveProp->getHeight();
		    tsunami_lab::t_real delta = abs( hStar - heights[l_id] );
		    tsunami_lab::t_real relativDeviation = delta / ( startHeightDifference + 1 );
		    bool isSameHeight = ( relativDeviation <= accuracyMargin );
		    successfulTests += isSameHeight;
		    nanProblems += std::isnan( delta );
		    if( !isSameHeight )
		    {
			    std::cout << "FAILED: Deviation too high from Test " << evaluatedTests << " (relativ deviation:" << relativDeviation << ")" << std::endl;
		    }

		    // free memory
		    delete l_setup;
		    delete l_waveProp;
		    ++evaluatedTests;
	    }

	    // close the file and print the results
	    middle_states.close();
	    std::cout << successfulTests << " Tests were successful of " << evaluatedTests << " with " << nanProblems << " Nan evaluations" << std::endl
		    << "Accuracy of " << successfulTests / static_cast<double>( evaluatedTests ) << " with Margin of " << accuracyMargin << " and " << numberOfCells << " Cells" << std::endl;
	    REQUIRE( successfulTests / static_cast<double>( evaluatedTests ) >= testAccuracy );
    }

Output
^^^^^^

Output of test_middle_states with 100 cells and a margin of 2%.

.. code-block:: console

    FAILED: Deviation too high from Test 999969 (relativ deviation:0.284146)
    FAILED: Deviation too high from Test 999990 (relativ deviation:0.199954)

    992814 Tests were successful of 1000000 with 17 Nan evaluations
    Accuracy of 0.992814 with Margin of 0.02 and 100 Cells
    ===============================================================================
    All tests passed (1 assertion in 1 test case)

Continuous Integration
----------------------

The continuous integration is done by a `GitHub Action <https://docs.github.com/en/actions>`_ which was provided and modified to fit the current requirements.
E.g. switching to cmake to build the project and the implemented targets.
The action runs when a commit is done to the main branch or a pull request is opened targeting the main branch and the action runs every night to ensure continuity.

.. code-block:: yaml

    name: Tsunami Lab

    on:
    push:
        branches: [ main ]
    pull_request:
        branches: [ main ]
    schedule:
        - cron: 0 0 * * *

    jobs:
    CI:
        runs-on: ubuntu-latest

        steps:
        - uses: actions/checkout@v4

        - name: Dependencies
            run: |
            sudo apt-get update
            sudo apt-get install cmake
            sudo apt-get install valgrind
            sudo apt-get install cppcheck
            git submodule init
            git submodule update

        - name: Configure the project
            uses: threeal/cmake-action@v1.3.0

        - name: Static Code Analysis
            run:
            cppcheck src/ --template=gcc --force --error-exitcode=1

        - name: Sanitize
            run: |
            cmake --build build --config Debug --target sanitize
            ./build/sanitize 25
            cmake --build build --config Debug --target sanitize_test
            ./build/sanitize_test 25
            cmake --build build --config Release --target sanitize
            ./build/sanitize 500
            cmake --build build --config Release --target sanitize_test
            ./build/sanitize_test 500

        - name: Valgrind
            run: |
            cmake --build build --config Debug --target test
            valgrind build/test
            cmake --build build --config Debug --target build
            valgrind build/build 25

        - name: Release
            run: |
            cmake --build build --config Release --target test
            ./build/test
            cmake --build build --config Release --target build
            ./build/build 500

2.1. Shock and Rarefaction Waves
--------------------------------

Implementation of shock-shock setup
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

"**Shock-Shock Problem**: Let’s use our solver to solve shock-shock Riemann problems. Imagine two streams
of water which move in opposite directions and smash into each other at some position :math:`x_\text{dis}`.
The scenario is given by the following setup"[1]_:

.. math::

    \begin{split}\begin{cases}
        Q_i = q_{l} \quad &\text{if } x_i \le x_\text{dis} \\
        Q_i = q_{r} \quad &\text{if }   x_i > x_\text{dis}
    \end{cases} \qquad q_l \in \mathbb{R}^+ \times \mathbb{R}^+, \; q_r \in \mathbb{R}^+ \times \mathbb{R}^-,\end{split}

with initial conditions:

:raw-html:`<center>(2.1.1)</center>`

.. math::

    \begin{split}q_l=
        \begin{bmatrix}
          h_l \\ (hu)_l
        \end{bmatrix}, \quad
      q_r =
        \begin{bmatrix}
          h_r \\ (hu)_r
        \end{bmatrix} =
        \begin{bmatrix}
          h_l \\ -(hu)_l
        \end{bmatrix}.
    \end{split}

.. code-block:: cpp

    tsunami_lab::setups::ShockShock1d::ShockShock1d(t_real i_heightLeft,
                                                    t_real i_momentumLeft,
                                                    t_real i_locationShock)
    {
        m_heightLeft = i_heightLeft;
        m_momentumLeft = i_momentumLeft;
        m_locationShock = i_locationShock;
    }

    t_real tsunami_lab::setups::ShockShock1d::getHeight(t_real ,
                                                        t_real ) const
    {
        return m_heightLeft;
    }

    t_real tsunami_lab::setups::ShockShock1d::getMomentumX(t_real i_x,
                                                           t_real ) const
    {
        if (i_x <= m_locationShock)
        {
            return m_momentumLeft;
        }
        else
        {
            return -m_momentumLeft;
        }
    }

    t_real tsunami_lab::setups::ShockShock1d::getMomentumY(t_real,
                                                           t_real) const
    {
        return 0;
    }

Implementation of rare-rare setup
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

"**Rare-Rare Problem**: We can setup rare-rare Riemann problems by two streams of water, which move away
from each other at some position :math:`x_\text{dis}`. The scenario is defined as"[1]_:

.. math::

    \begin{split}\begin{cases}
        Q_i = q_{r} \quad &\text{if } x_i \le x_\text{dis} \\
        Q_i = q_{l} \quad &\text{if }   x_i > x_\text{dis}
        \end{cases} \qquad q_l \in \mathbb{R}^+ \times \mathbb{R}^+, \; q_r \in \mathbb{R}^+ \times \mathbb{R}^-,\end{split}

.. code-block:: cpp

    tsunami_lab::setups::RareRare1d::RareRare1d(tsunami_lab::t_real i_heightLeft,
                                                tsunami_lab::t_real i_momentumLeft, 
                                                tsunami_lab::t_real i_locationRare) {
        m_heightLeft = i_heightLeft;
        m_momentumLeft = i_momentumLeft;
        m_locationRare = i_locationRare;
    }

    tsunami_lab::t_real tsunami_lab::setups::RareRare1d::getHeight(tsunami_lab::t_real , tsunami_lab::t_real) const {
        return m_heightLeft;
    }

    tsunami_lab::t_real tsunami_lab::setups::RareRare1d::getMomentumX(tsunami_lab::t_real i_x,
                                                                      tsunami_lab::t_real) const {
        if (i_x <= m_locationRare) {
            return -m_momentumLeft;
        } else {
            return m_momentumLeft;
        }
    }

    tsunami_lab::t_real tsunami_lab::setups::RareRare1d::getMomentumY(tsunami_lab::t_real,
                                                                      tsunami_lab::t_real) const {
        return 0;
    }

.. [1] From https://scalable.uni-jena.de/opt/tsunami/chapters/assignment_1.html#f-wave-solver (29.10.2023)

Play around
^^^^^^^^^^^

l_hl...height of left side :raw-html:`<br>`
l_hr...height of right side :raw-html:`<br>`
l_ml...momentum of left side :raw-html:`<br>`
l_location...location :raw-html:`<br>`
:math:`\lambda_1`...wave speed one :raw-html:`<br>`
:math:`\lambda_2`...wave speed two

All results with 3 cells!

+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  l_hl  | l_hul  |  l_ul  |  l_location |  Setup    |  :math:`\lambda_1`  |  :math:`\lambda_2`  |
+========+========+========+=============+===========+=====================+=====================+
|  10    |   /    |   /    |      5      | Dam-Break |      -9.90285       |       9.90285       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  10    |   8    |  0.8   |      5      | Rare-Rare |      -10.7029       |       9.10285       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  10    |   8    |  0.8   |      5      |Shock-Shock|      -9.10285       |       10.7029       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  10    |   /    |   /    |      5      | Dam-Break |      -9.90285       |       9.90285       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  10    |   0    |   0    |      5      | Rare-Rare |      -9.90285       |       9.90285       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  10    |   0    |   0    |      5      |Shock-Shock|      -9.90285       |       9.90285       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  15    |   /    |    /   |      5      | Dam-Break |      -12.1285       |       12.1285       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  15    |   5    |   1/3  |      5      | Rare-Rare |      -12.4618       |       11.7951       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  15    |   5    |   1/3  |      5      |Shock-Shock|      -11.7951       |       12.4618       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  100   |   /    |    /   |      5      | Dam-Break |      -31.3156       |       31.3156       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  100   |   5    |   0.05 |      5      | Rare-Rare |      -31.3656       |       31.2656       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  100   |   5    |   0.05 |      5      |Shock-Shock|      -31.2656       |       31.3656       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  100   |   /    |    /   |      5      | Dam-Break |      -31.3156       |       31.3156       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  100   |   2000 |   20   |      5      | Rare-Rare |      -51.3156       |       11.3156       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+
|  100   |   2000 |   20   |      5      |Shock-Shock|      -11.3156       |       51.3156       |
+--------+--------+--------+-------------+-----------+---------------------+---------------------+

What we observe
^^^^^^^^^^^^^^^

Dam-Break
    :math:`\lambda_1 = -\lambda_2` :raw-html:`<br>`
    The higher the difference between l_hl and l_hr the higher the absolute wave speeds (eigenvalues). :raw-html:`<br>`
    Wave speeds are independent of the velocity which is always zero.

Rare-Rare
    Waves speeds of Rare-Rare and Shock-Shock are swapped. :raw-html:`<br>`
    :math:`\lambda_{1/2} = u \mp \sqrt{gh}` :raw-html:`<br>`
    thus the wave speeds scale with the velocity. The higher the velocity the higher the wave speeds.

Shock-Shock
    Waves speeds of Rare-Rare and Shock-Shock are swapped. :raw-html:`<br>`
    :math:`\lambda_{1/2} = u \mp \sqrt{gh}` :raw-html:`<br>`
    thus the wave speeds scale with the velocity. The higher the velocity the higher the wave speeds.

2.2. Dam-Break
--------------

Playing around
^^^^^^^^^^^^^^

l_hl...height of left side :raw-html:`<br>`
l_hr...height of right side :raw-html:`<br>`
l_location...location :raw-html:`<br>`
l_ur...particles velocity of the right side

All results with 100 cells!

+--------+--------+------------+--------+
|  l_hl  |  l_hr  | l_location |  l_ur  |
+========+========+============+========+
|  10    |   10   |      5     |    0   |
+--------+--------+------------+--------+
|  20    |   10   |      5     | 4.1327 |
+--------+--------+------------+--------+
|  10    |   20   |      5     |-4.1356 |
+--------+--------+------------+--------+
|  200   |   10   |      5     |34.2068 |
+--------+--------+------------+--------+
|  200   |   150  |      5     | 5.9400 |
+--------+--------+------------+--------+
|  200   |   190  |      5     | 1.1214 |
+--------+--------+------------+--------+

Observation
^^^^^^^^^^^

The larger the gap between the left and right water height the bigger is the velocity.
With higher water columns but same difference between left and right water height the
velocity decreases.

Compute evacuation time
^^^^^^^^^^^^^^^^^^^^^^^

**Calculated with Simulation**

.. math::

    q_l = [14, 0]^T\\
    q_r = [3.5, 0.7]^T

Distance: :math:`25,000\,m` :raw-html:`<br>`
Wave speed: :math:`11.7120\,m/s`

Time: :math:`\frac{25,000\,m}{11.7120\,m/s} = 35,5760\,s \approx \text{35:34 min}`



**Calculated by hand**

.. math::

    q_l = [14, 0]^T, u_l = \frac{0}{14} =0\\
    q_r = [3.5, 0.7]^T, u_l = \frac{0.7}{3.5} = 0.2\\
    h^{\text{Roe}} = \frac{1}{2}\cdot(14+3.5) = 8.75\\
    u^{\text{Roe}} = \frac{0\cdot\sqrt{14}+0.2\cdot\sqrt{3.5}}{\sqrt{1}+\sqrt{3.5}} = \frac{1}{15}\\
    \sqrt{gh^{\text{Roe}}} = \sqrt{9.80665\cdot8.75} = 9.263270886\\
    \lambda_1 = \frac{1}{15}-9.263270886 = -9.196604219\\
    \lambda_2 = \frac{1}{15}+9.263270886 = 9.329937553

Distance: :math:`25,000\,m` :raw-html:`<br>`
Wave speed: :math:`9.329937553\,m/s`

Time: :math:`\frac{25,000\,m}{9.329937553\,m/s} = 2679.546\,s \approx \text{44:40 min}`

Contribution
------------

All team members contributed equally to the tasks.
