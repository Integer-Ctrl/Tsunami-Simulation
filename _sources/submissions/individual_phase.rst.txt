.. role:: raw-html(raw)
    :format: html

.. _submissions_individual_phase:

10. Individual Phase
====================

10.1 Draft
---------------------------

- Tsunami Mitigation Strategies
    - simulate and assess the impact of various tsunami mitigation strategies
    - algorithms to model the effectiveness of barriers, early warning systems, and evacuation plans

- Multi-resolution Simulation
    - support multi-resolution grids

    - data structures and algorithms that efficiently handle varying resolutions in different parts
      of the simulation domain

- Grid masking
    - Optimization of the calculation by applying a mask to the changing part of the simulation 
      i.e. cells that have no influence on the wave simulation are skipped, e.g. dry cells, standing water

- Real-time Visualization
    - real-time visualization using C++ graphics libraries like (OpenGL, SFML or SDL)
    - user-friendly interface to visualize the evolving tsunami simulation

- Explore GPU acceleration using NVIDIA's CUDA toolkit
    - simulation algorithms to take advantage of parallel processing on compatible NVIDIA GPUs,
      enhancing the performance

- Friction
    - Adding a friction adjustment to the implementation to obtain more accurate simulation results

10.2 Proposal
-------------

Introduction
^^^^^^^^^^^^

Tsunami simulations require accurate and efficient numerical methods to capture complex wave propagation dynamics.
Adaptive Mesh Refinement (AMR) is a powerful technique that enhances simulation accuracy by dynamically adjusting the
mesh resolution based on the evolving wave features.
In addition, masking improves performance by only updating relevant cells.
This proposal outlines the goal of implementing AMR in our existing C++ tsunami simulation, using open-source tools, within a four-week timeframe.

Project Goals
^^^^^^^^^^^^^

The primary goal of this project is to integrate Adaptive Mesh Refinement into our existing tsunami simulation.
The objectives include:

1. Dynamic Mesh Resolution:

    Implement a hierarchical mesh structure that allows dynamic refinement and coarsening based on the local wave characteristics.

2. Error Estimation:

    Develop a method to estimate error metrics at each mesh cell, guiding the adaptive refinement process.

3. Efficient Data Handling:

    Design strategies to efficiently manage data structures for adaptive grids while minimizing computational overhead.

4. Verification and Validation:

    Ensure the accuracy of the simulation results by validating against our earlier simulations.

Approaches
^^^^^^^^^^

1. Adaptive Mesh Structure:

    Utilize the `AMReX <https://amrex-codes.github.io/amrex/>`_ library to implement adaptive mesh structures efficiently.
    AMReX is an open-source framework designed for AMR applications and is well-suited for scientific simulations.

2. Error Estimation:

    Implement error estimation algorithms to assess the accuracy of the simulation at different mesh resolutions.
    Develop interpolation methods for smooth data transfer between mesh levels.

3. Data Management:

    Utilize the AMReX data structures to efficiently handle adaptive grids.
    Explore strategies such as block-structured AMR to optimize memory usage and computational performance.

4. Visualization:

    Enhance visualization capabilities by integrating ParaView with AMReX, ensuring proper representation of refined
    meshes and visualizing adaptive grid structures.

Implementation Outline
^^^^^^^^^^^^^^^^^^^^^^^

**Week 1-2: Familiarization and Setup**

Familiarize ourself with the AMReX library, exploring its capabilities and documentation.
Integrate AMReX into our existing C++ tsunami simulation codebase.
Develop a prototype with a static adaptive mesh to verify compatibility and setup.

**Week 3: Error Estimation and Refinement**

Implement error estimation techniques to guide adaptive mesh refinement.
Integrate error estimation into the simulation loop.
Verify the correctness of error estimation by comparing results with non-adaptive simulations.

**Week 4: Optimization and Validation**

Optimize data structures and computation for efficiency and apply masking.
Validate the simulation results with established benchmarks.
Implement ParaView integration for visualization of adaptive meshes.

Conclusion
^^^^^^^^^^

The successful implementation of Adaptive Mesh Refinement will enhance the accuracy and efficiency of our tsunami simulation.
Utilizing the AMReX library and following the outlined steps, this project aims to achieve these goals within a four-week timeframe.


10.3 Status
-----------

During the first week we read a lot of the AMReX documentation to get up to speed. AMReX provides a lot of documentation
and also tutorials on first projects, so this was our main source of information as there aren't many tutorials elsewhere
on the web. Unfortunately, the API documentation is very sketchy. We were forced to study the AMReX source code and
tutorials in detail to understand the workflow of this framework.

The second week's priority was to implement AMReX into our existing project. After attempting to do so, we decided to
change our approach and integrate our logic into the AMReX framework. Our best practice strategy involved utilizing the
AMReX data structures and functions, resulting in a reduction of our ``main.cpp`` file and the creation of
``AMRCoreWavePropagation2d.cpp``, where our logic is combined with AMReX.  However, we encountered difficulties due to
insufficient documentation at certain stages, which required us to troubleshoot the issue ourselves.

In the end, we are happy to say that we reached our milestone on time!

Contribution
------------

All team members contributed equally to the tasks.
