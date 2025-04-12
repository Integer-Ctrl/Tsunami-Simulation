.. role:: raw-html(raw)
    :format: html

.. _submissions_parallelization:

9. Parallelization
==================

1. Parallelization using OpenMP
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. note::

    We are using the following OpenMP directives:

    - ``#pragma omp parallel for`` : "The **omp parallel** directive explicitly instructs the compiler to parallelize the chosen block of code"[1]_.

    - ``#pragma omp parallel for reduction( reduction-identifier:list )`` : "Performs a **reduction** on each data variable in list using the specified reduction-identifier"[1]_.

    - ``#pragma omp declare simd`` : "The **omp declare simd** directive is applied to a function to create one or more versions for being called in a SIMD loop"[2]_.

    - ``#pragma omp simd`` : "The **omp simd** directive is applied to a loop to indicate that multiple iterations of the loop can be executed concurrently by using SIMD instructions"[3]_.

In the ``main.cpp`` file we are using a reduction to determine the value of ``l_hMax``.

.. code-block:: cpp
    :emphasize-lines: 4, 16

    /// File: main.cpp
    [ ... ]
    // set up solver
    #pragma omp parallel for reduction(max: l_hMax)
    for( tsunami_lab::t_idx l_cy = 0; l_cy < l_ny; l_cy++ )
    {
        tsunami_lab::t_real l_y = l_cy * cellSize;

        for( tsunami_lab::t_idx l_cx = 0; l_cx < l_nx; l_cx++ )
        {
            tsunami_lab::t_real l_x = l_cx * cellSize;

            // get initial values of the setup
            tsunami_lab::t_real l_h = l_setup->getHeight( l_x,
                                                          l_y );
            l_hMax = std::max( l_h, l_hMax );
        [ ... ]
        }
    }

In ``NetCdf.cpp`` we parallelized the ``averageSeveral`` function to increase the performance when using coarse output.

.. code-block:: cpp
    :emphasize-lines: 5, 9

    /// File: NetCdf.cpp
    void tsunami_lab::io::NetCdf::averageSeveral( [ ... ] )
    {
        [ ... ]
    #pragma omp parallel for
        for( t_idx y = 0; y < m_ny; y++ )
        {
            t_idx singleY = y * m_k;
    #pragma omp simd
            for( t_idx x = 0; x < m_nx; x++ )
            {
                [ ... ]
            }
        }

We used the **omp declare simd directive** for our functions in the ``FWave.cpp`` to create one or more versions when
being called in a SIMD loop. These methods are called in ``WavePropagation2d.cpp``.

.. code-block:: cpp
    :emphasize-lines: 2, 8, 14, 20, 27, 40

    /// File: FWave.cpp
    #pragma omp declare simd
    void tsunami_lab::solvers::FWave::computeEigenvalues( [ ... ] )
    {
        [ ... ]
    }

    #pragma omp declare simd
    void tsunami_lab::solvers::FWave::computeDeltaFlux( [ ... ] )
    {
        [ ... ]
    }

    #pragma omp declare simd
    void tsunami_lab::solvers::FWave::computeEigencoefficients( [ ... ] )
    {
        [ ... ]
    }

    #pragma omp declare simd
    void tsunami_lab::solvers::FWave::computeBathymetryEffects( [ ... ] )
    {
        [ ... ]
    }

    // net update without bathymetry
    #pragma omp declare simd
    void tsunami_lab::solvers::FWave::netUpdates( [ ... ] )
    {
        [ ... ]
        computeEigenvalues( i_hL, i_hR, l_uL, l_uR, eigenvalue1, eigenvalue2 );
        [ ... ]
        computeDeltaFlux( i_hL, i_hR, l_uL, l_uR, i_huL, i_huR, deltaFlux );
        [ ... ]
        computeEigencoefficients( eigenvalue1, eigenvalue2, deltaFlux, eigencoefficient1, eigencoefficient2 );
        [ ... ]
    }

    // net update with bathymetry
    #pragma omp declare simd
    void tsunami_lab::solvers::FWave::netUpdates( [ ... ] )
    {
        [ ... ]
        computeEigenvalues( i_hL, i_hR, l_uL, l_uR, eigenvalue1, eigenvalue2 );
        [ ... ]
        computeDeltaFlux( i_hL, i_hR, l_uL, l_uR, i_huL, i_huR, deltaFlux );
        [ ... ]
        computeBathymetryEffects( i_hL, i_hR, i_bL, i_bR, bathymetry );
        [ ... ]
        computeEigencoefficients( eigenvalue1, eigenvalue2, bathymetryDeltaFlux, eigencoefficient1, eigencoefficient2 );
        [ ... ]
    }

However, most of the parallelization takes place in ``WavePropagation2d.cpp``.

.. code-block:: cpp
    :emphasize-lines: 3, 9, 13, 24, 28, 37, 47, 54, 66, 77, 84, 96, 108, 114, 121, 127, 137, 140, 157

    /// File: WavePropagation2d.cpp
        // init new cell quantities
    #pragma omp parallel for
        for( t_idx l_ce = 0; l_ce < totalCells; l_ce++ )
        {
            [ ... ]
        }
        [ ... ]
    #pragma omp parallel for
            for( t_idx i = 0; i < m_yCells + 1; i++ )
            {
                // iterates along the row
    #pragma omp simd
                for( t_idx j = 0; j < m_xCells + 1; j++ )
                {
                    [ ... ]
                }
            }
        }
        else
        {
            [ ... ]
            // iterates through the row
    #pragma omp parallel for
            for( t_idx i = 0; i < m_yCells + 1; i++ )
            {
                // iterates over along the row
    #pragma omp simd
                for( t_idx j = 0; j < m_xCells + 1; j++ )
                {
                    [ ... ]
                }
            }
        }
        [ ... ]
        // copy the calculated cell quantities
    #pragma omp parallel for
        for( t_idx l_ce = 0; l_ce < totalCells; l_ce++ )
        {
            [ ... ]
        }

        // only possible for f-wave solver
        if( hasBathymetry )
        {
            //  iterates over the x direction
    #pragma omp parallel for
            for( t_idx i = 1; i < full_xCells; i += ITERATIONS_CACHE )
            {
                // iterate over the rows i.e. y-coordinates
                for( t_idx j = 0; j < m_yCells + 1; j++ )
                {
                    // iterations for more efficient cache usage
    #pragma omp simd
                    for( t_idx k = 0; k < ITERATIONS_CACHE; k++ )
                    {
                        [ ... ]
                    }
                }
            }

            // iterate over the rows i.e. y-coordinates
            for( t_idx j = 0; j < m_yCells + 1; j++ )
            {
                // remaining iterations for more efficient cache usage
    #pragma omp simd
                for( t_idx k = 0; k < remaining_xCells; k++ )
                {
                    [ ... ]
                }
            }
        }
        else
        {
            [ ... ]
            //  iterates over the x direction
    #pragma omp parallel for
            for( t_idx i = 1; i < full_xCells; i += ITERATIONS_CACHE )
            {
                // iterate over the rows i.e. y-coordinates
                for( t_idx j = 1; j < m_yCells + 1; j++ )
                {
                    // iterations for more efficient cache usage
    #pragma omp simd
                    for( t_idx k = 0; k < ITERATIONS_CACHE; k++ )
                    {
                        [ ... ]
                    }
                }
            }

            // iterate over the rows i.e. y-coordinates
            for( t_idx j = 1; j < m_yCells + 1; j++ )
            {
                // remaining iterations for more efficient cache usage
    #pragma omp simd
                for( t_idx k = 0; k < remaining_xCells; k++ )
                {
                    [ ... ]
                }
            }
        }
    }

    void tsunami_lab::patches::WavePropagation2d::setGhostOutflow()
    {
        [ ... ]
    #pragma omp parallel for
        for( t_idx i = 1; i < m_yCells + 1; i++ )
        {
            [ ... ]
        }

    #pragma omp parallel for
        for( size_t i = 0; i < stride; i++ )
        {
            [ ... ]
        }
    }

    #pragma omp declare simd
    tsunami_lab::patches::WavePropagation2d::Reflection tsunami_lab::patches::WavePropagation2d::calculateReflection( [ ... ] )
    {
        [ ... ]
    }

    #pragma omp declare simd
    tsunami_lab::patches::WavePropagation2d::Reflection tsunami_lab::patches::WavePropagation2d::calculateReflection( [ ... ] )
    {
        [ ... ]
    }

    const tsunami_lab::t_real* tsunami_lab::patches::WavePropagation2d::getTotalHeight()
    {
        if( isDirtyTotalHeight )
        {
    #pragma omp parallel for
            for( t_idx i = 1; i < m_yCells + 1; i++ )
            {
    #pragma omp simd
                for( t_idx j = 1; j < m_xCells + 1; j++ )
                {
                    [ ... ]
                }
            }
        }
        [ ... ]
    }

    void tsunami_lab::patches::WavePropagation2d::updateWaterHeight()
    {
        if( !hasBathymetry )
        {
            return;
        }

    #pragma omp parallel for
        for( t_idx i = 1; i < m_yCells + 1; i++ )
        {
            [ ... ]
        }

2. Comparison serial and parallelized solver
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Without parallelization**

.. code-block:: bash
    :emphasize-lines: 27-29

    Start executing 'simulation 2700 1500 -B -w 60 -t 13000 -c 5':
    #####################################################
    ###                  Tsunami Lab                  ###
    ###                                               ###
    ### https://scalable.uni-jena.de                  ###
    ### https://rivinhd.github.io/Tsunami-Simulation/ ###
    #####################################################
    Checking for Checkpoints: File IO is disabled!
    Simulation is set to 2D
    Bathymetry is Enabled
    Set Solver: FWave
    Activated Reflection on None side
    Output format is set to netCDF
    Writing the X-/Y-Axis in format meters
    Simulation Time is set to 13000 seconds
    Writing to the disk every 60 seconds of simulation time
    Checkpointing every 5 minutes
    runtime configuration
      number of cells in x-direction:       2700
      number of cells in y-direction:       1500
      cell size:                            1000
      number of cells combined to one cell: 1
    Max speed 307.668
    entering time loop
    finished time loop
    freeing memory
    The Simulation took 1 h 28 min 28 sec to finish.
    Time per iteration: 597 milliseconds.
    Time per cell:      147 nanoseconds.
    finished, exiting

**With parallelization**

.. code-block:: bash
    :emphasize-lines: 3-5

    start executing 'MP_NUM_THREADS=72 ./simulation 2700 1500 -B -w 60 -t 13000 -c 5':
    finished writing to 'solutions/simulation/solution.nc'. Use ncdump to view its contents.
    The Simulation took 0 h 3 min 39 sec to finish.
    Time per iteration: 24 milliseconds.
    Time per cell:      6 nanoseconds.
    finished, exiting

You can see that we have a run time of around 1 h 28 min **without parallelization and disabled file io** and a run time
of just 3 min 39 sec **with parallelization and enabled file io**. This results in a speedup of
:math:`S_{72} = \frac{5308 \text{ sec}}{219 \text{ sec}} \approx 24.237`.


3. Parallelization of the outer vs. the inner loops
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The **outer loop** can be easily parallelized, as there are no dependencies between the individual cells.
An X sweep is parallelized in the Y direction and a Y sweep in the X direction, so the direction of parallelism remains independent of each other.
It is also more advantageous for the X sweep as the data locality is utilized.

When the **inner loop** is parallelized, there are dependencies when updating the cells, as the current and the next iteration access the same cell.
For this, critical sections [4]_ must be introduced, which significantly slows down the calculation, as processes have to wait.

In **conclusion**, the parallelization of the outer loop is better, as no dependencies arise, data locality is utilized and deadlocks are completely excluded.
The parallelization of the outer loop is also sufficient as there are significantly more cells in x and y direction than processors.
The parallelization of the two loops would reintroduce the cell dependency which slows down the computation.

4. Different scheduling and pinning strategies
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**All threads**

.. code-block:: bash
    :emphasize-lines: 3-5

    Start executing 'MP_NUM_THREADS=72 ./simulation 2700 1500 -B -w 60 -t 13000 -c 5':
    finished writing to 'solutions/simulation/solution.nc'. Use ncdump to view its contents.
    The Simulation took 0 h 3 min 39 sec to finish.
    Time per iteration: 24 milliseconds.
    Time per cell:      6 nanoseconds.
    finished, exiting

**Every core without their second thread**

.. code-block:: bash
    :emphasize-lines: 3-5

    Start executing 'OMP_NUM_THREADS=36 OMP_PLACES={0}:36:1 ./simulation 2700 1500 -B -w 60 -t 13000 -c 5':
    finished writing to 'solutions/simulation/solution.nc'. Use ncdump to view its contents.
    The Simulation took 0 h 2 min 45 sec to finish.
    Time per iteration: 18 milliseconds.
    Time per cell:      4 nanoseconds.
    finished, exiting

**Only half of the cores with their second thread**

.. code-block:: bash
    :emphasize-lines: 3-5

    Start executing 'OMP_NUM_THREADS=36 OMP_PLACES={0}:36:2 ./simulation 2700 1500 -B -w 60 -t 13000 -c 5':
    finished writing to 'solutions/simulation/solution.nc'. Use ncdump to view its contents.
    The Simulation took 0 h 3 min 24 sec to finish.
    Time per iteration: 22 milliseconds.
    Time per cell:      5 nanoseconds.
    finished, exiting

**Only half of the cores without their second thread**

.. code-block:: bash
    :emphasize-lines: 3-5

    Start executing 'OMP_NUM_THREADS=18 OMP_PLACES={0}:18:1 ./simulation 2700 1500 -B -w 60 -t 13000 -c 5':
    finished writing to 'solutions/simulation/solution.nc'. Use ncdump to view its contents.
    The Simulation took 0 h 4 min 9 sec to finish.
    Time per iteration: 28 milliseconds.
    Time per cell:      6 nanoseconds.
    finished, exiting

You can see that the second strategy is the best in terms of runtime. It also makes sense that the simulation
simulation time increases the fewer cores and threads are used.
The reason for the faster runtime of the second run compared to the
first run is not easy to clarify.
It could be that when using both threads, switching between them causes an overhead, and since the simulation requires much more computing power than loading data, the time deteriorates.
It is very unlikely but possible that when using both threads, one thread overwrites the cached data of the other thread.
Communication only takes place when writing to the file system.
This could explain why the third pass is faster than the first, where one more socket is used.
Therefore, some communication must take place via NUMA during the first run when writing to a file.
In the fourth configuration, half of the cores are used, which reduces the parallel performance and increases the runtime.

Contribution
------------

All team members contributed equally to the tasks.

.. [1] From https://www.ibm.com/docs/en/xl-c-and-cpp-linux/16.1.1?topic=parallelization-pragma-omp-parallel (07.01.2024)

.. [2] From https://www.ibm.com/docs/it/xl-c-and-cpp-linux/16.1.0?topic=parallelization-pragma-omp-declare-simd (07.01.2024)

.. [3] From https://www.ibm.com/docs/en/xl-c-and-cpp-linux/16.1.0?topic=pdop-pragma-omp-simd (07.01.2024)

.. [4] From https://www.ibm.com/docs/en/xl-c-and-cpp-linux/16.1.0?topic=parallelization-pragma-omp-critical (07.01.2024)