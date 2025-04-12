.. role:: raw-html(raw)
    :format: html

.. _submissions_riemann_solver:

1. Riemann Solver
====================

F-wave Solver
-------------

Header file: ``.../Tsunami-Simulation/include/solvers/FWave.h``

Implementation file: ``.../Tsunami-Simulation/src/solvers/FWave.cpp``

Test file: ``.../Tsunami-Simulation/src/solvers/FWave.test.cpp``

"The f-wave solver approximately solves the following Initial Value Problem (IVP) for the shallow water equations over time"[1]_ :

.. _submission_1_eq_131:

:raw-html:`<center>(1.3.1)</center>`

.. math::
    \begin{split}q(x,0) =
      \begin{cases}
        q_{l} \quad   &\text{if } x < 0 \\
        q_{r} \quad &\text{if }   x > 0
      \end{cases} \qquad q_l, q_r \in \mathbb{R}^+ \times \mathbb{R}.\end{split}

"Theory shows that the solution, arising from the discontinuity at :math:`x=0`,
consist of two waves. Each wave is either a shock or a rarefaction wave.
The f-wave solver uses two shock waves to approximate the true solution."[1]_

"First, we use the Roe eigenvalues :math:`\lambda^{\text{Roe}}_{1/2}` in terms
of the left and right quantities :math:`q_l` and :math:`q_r` with respect to
position :math:`x=0` to approximate the true wave speeds:"[1]_

.. _submission_1_eq_132:

:raw-html:`<center>(1.3.2)</center>`

.. math::
    \begin{split}\begin{aligned}
      \lambda^{\text{Roe}}_{1}(q_l, q_r) &= u^{\text{Roe}}(q_l, q_r) - \sqrt{gh^{\text{Roe}}(q_l, q_r)}, \\
      \lambda^{\text{Roe}}_{2}(q_l, q_r) &= u^{\text{Roe}}(q_l, q_r) + \sqrt{gh^{\text{Roe}}(q_l, q_r)},
    \end{aligned}\end{split}

"where the height :math:`h^{\text{Roe}}` and particle velocity :math:`u^{\text{Roe}}`
are given as:"[1]_

.. math::
    \begin{split}\begin{aligned}
      h^{\text{Roe}}(q_l, q_r) &= \frac{1}{2} (h_l + h_r), \\
      u^{\text{Roe}}(q_l, q_r) &=  \frac{u_l \sqrt{h_l} + u_r \sqrt{h_r}}{\sqrt{h_l}+\sqrt{h_r}}.
    \end{aligned}\end{split}

.. code-block:: cpp

    void tsunami_lab::solvers::FWave::computeEigenvalues(t_real   i_hL,
                                                         t_real   i_hR,
                                                         t_real   i_uL,
                                                         t_real   i_uR,
                                                         t_real & o_eigenvalue1,
                                                         t_real & o_eigenvalue2){
        // pre-compute square-root ops
        t_real l_hSqrtL = std::sqrt( i_hL );
        t_real l_hSqrtR = std::sqrt( i_hR );

        // compute averages
        t_real l_h = 0.5f * ( i_hL + i_hR );
        t_real l_u = l_hSqrtL * i_uL + l_hSqrtR * i_uR;
        l_u /= l_hSqrtL + l_hSqrtR;

        // compute eigenvalues
        t_real l_ghSqrtRoe = m_gSqrt * std::sqrt( l_h );
        o_eigenvalue1 = l_u - l_ghSqrtRoe;
        o_eigenvalue2 = l_u + l_ghSqrtRoe;
    }

.. _submission_1_eq_flux:

Compute flux function:

.. math::
    f := [hu, hu^2 + \frac{1}{2}gh^2]^T \\
    \Delta f := f(q_r) - f(q_l)

.. code-block:: cpp

    void tsunami_lab::solvers::FWave::computeDeltaFlux(t_real i_hL,
                                                       t_real i_hR,
                                                       t_real i_uL,
                                                       t_real i_uR,
                                                       t_real o_deltaFlux[2]){
        t_real i_huL = i_hL * i_uL;
        t_real i_huR = i_hR * i_uR;

        o_deltaFlux[0] = i_huR - i_huL;
        o_deltaFlux[1] = (i_hR * i_uR * i_uR + 0.5f * m_g * i_hR * i_hR)
                        -(i_hL * i_uL * i_uL + 0.5f * m_g * i_hL * i_hL);
    }

"The eigencoefficients :math:`\alpha_p` in Equation are obtained by
multiplying the inverse of the matrix of right eigenvectors :math:`R=[r_1^\text{Roe}, r_2^\text{Roe}]`
with the jump in fluxes:"[1]_

.. _submission_1_eq_eigencoefficients:

.. math::
    \begin{split}\begin{bmatrix}
      \alpha_1 \\
      \alpha_2
    \end{bmatrix} =
    \begin{bmatrix}
      1 & 1 \\
      \lambda^{\text{Roe}}_1 & \lambda^{\text{Roe}}_2
    \end{bmatrix}^{-1} \Delta f.\end{split}

.. code-block:: cpp

    void tsunami_lab::solvers::FWave::computeEigencoefficients(t_real i_eigenvalue1,
                                                               t_real i_eigenvalue2,
                                                               t_real i_deltaFlux[2],
                                                               t_real &o_eigencoefficient1,
                                                               t_real &o_eigencoefficient2) {
        // compute inverse matrix
        t_real denominator = i_eigenvalue2 - i_eigenvalue1;
        t_real invertedMatrix[2][2] = {
                {i_eigenvalue2 / denominator, -1 / denominator},
                {-i_eigenvalue1 / denominator, 1 / denominator}
        };

        // compute eigencoefficients
        o_eigencoefficient1 = invertedMatrix[0][0] * i_deltaFlux[0] + invertedMatrix[0][1] * i_deltaFlux[1];
        o_eigencoefficient2 = invertedMatrix[1][0] * i_deltaFlux[0] + invertedMatrix[1][1] * i_deltaFlux[1];
    }

.. _submission_1_eq_eigenvectors:

"Using the eigenvalues we can define corresponding eigenvectors :math:`r_{1/2}^{\text{Roe}}`"[1]_

.. math::
    \begin{split}\begin{aligned}
      r_1^{\text{Roe}} &=
        \begin{bmatrix}
          1 \\ \lambda^{\text{Roe}}_1
        \end{bmatrix}, \\
      r_2^{\text{Roe}} &=
        \begin{bmatrix}
          1 \\ \lambda^{\text{Roe}}_2
        \end{bmatrix}.
    \end{aligned}\end{split}

Using the eigenvectors and our eigencoefficients we can compute
the waves :math:`Z_{1/2}`

.. _submission_1_eq_133:

:raw-html:`<center>(1.3.3)</center>`

.. math::
    \Delta f = \sum_{p=1}^2 \alpha_p r_p \equiv  \sum_{p=1}^2 Z_p, \qquad \alpha_p \in \mathbb{R}.

"This leads to the definition of net updates which summarize the
net effect of the waves to the left and right “cell”:"[1]_

.. _submission_1_eq_effect_on_waves:
.. math::
    \begin{split}\begin{split}
      A^- \Delta Q := \sum_{p:\{ \lambda_p^\text{Roe} < 0 \}} Z_p \\
      A^+ \Delta Q := \sum_{p:\{ \lambda_p^\text{Roe} > 0 \}} Z_p
    \end{split}\end{split}

.. code-block:: cpp

    void tsunami_lab::solvers::FWave::netUpdates(t_real i_hL,
                                                 t_real i_hR,
                                                 t_real i_huL,
                                                 t_real i_huR,
                                                 t_real *o_netUpdateL,
                                                 t_real *o_netUpdateR) {

        // compute particle velocities
        t_real l_uL = i_huL / i_hL;
        t_real l_uR = i_huR / i_hR;

        // compute eigenvalues
        t_real eigenvalue1 = 0;
        t_real eigenvalue2 = 0;
        computeEigenvalues(i_hL, i_hR, l_uL, l_uR, eigenvalue1, eigenvalue2);

        // create eigenvectors
        t_real eigenvector1[2] = {1, eigenvalue1};
        t_real eigenvector2[2] = {1, eigenvalue2};

        // compute delta flux
        t_real deltaFlux[2];
        computeDeltaFlux(i_hL, i_hR, l_uL, l_uR, deltaFlux);

        // compute eigencoefficients
        t_real eigencoefficient1 = 0;
        t_real eigencoefficient2 = 0;
        computeEigencoefficients(eigenvalue1, eigenvalue2, deltaFlux, eigencoefficient1, eigencoefficient2);

        // compute waves / net updates
        for( unsigned short l_qt = 0; l_qt < 2; l_qt++ )
        {
            // init
            o_netUpdateL[l_qt] = 0;
            o_netUpdateR[l_qt] = 0;

            // 1st wave
            if( eigenvalue1 < 0 )
            {
                o_netUpdateL[l_qt] += eigencoefficient1 * eigenvector1[l_qt];
            }
            else
            {
                o_netUpdateR[l_qt] += eigencoefficient1 * eigenvector1[l_qt];
            }

            // 2nd wave
            if( eigenvalue2 < 0 )
            {
                o_netUpdateL[l_qt] += eigencoefficient2 * eigenvector2[l_qt];
            }
            else
            {
                o_netUpdateR[l_qt] += eigencoefficient2 * eigenvector2[l_qt];
            }
        }
    }



F-wave Solver Unit Testing
--------------------------

**Test the derivation of the F-Wave eigenvalues.** :raw-html:`</br>`
Using the equation stated in `(1.3.2) <submission_1_eq_132_>`_ to calculate the test cases.

.. code-block:: cpp

    TEST_CASE( "Test the derivation of the F-Wave eigenvalues.", "[FWaveEigenvalue]" )
    {
        /*
         * Test case:
         *  h: 10 | 9
         *  u: -3 | 3
         *
         *  height: 9.5
         *  velocity: (sqrt(10) * -3 + 3 * 3) / ( sqrt(10) + sqrt(9) )
         *               = -0.0790021169691720
         * eigenvalue: s1 = -0.079002116969172024 - sqrt(9.80665 * 9.5) = -9.7311093998375095
         *             s2 = -0.079002116969172024 + sqrt(9.80665 * 9.5) =  9.5731051658991654
         */
        t_real l_eigenvalue1 = 0;
        t_real l_eigenvalue2 = 0;
        tsunami_lab::solvers::FWave::computeEigenvalues( 10,
                                               9,
                                               -3,
                                               3,
                                               l_eigenvalue1,
                                               l_eigenvalue2 );

        REQUIRE( l_eigenvalue1 == Approx( -9.7311093998375095 ) );
        REQUIRE( l_eigenvalue2 == Approx(  9.5731051658991654 ) );
    }

**Test the computation of the delta flux.** :raw-html:`</br>`
Using the equation `flux function <submission_1_eq_flux_>`_ to calculate these test cases.

.. code-block:: cpp

    TEST_CASE( "Test the computation of the delta flux.", "[FWaveDeltaFlux]")
    {
        /*
         * Test case:
         *  h: 10 | 9
         *  u: -3 | 3
         *
         * height: 9.5
         * delta f: {9 * 3, 9 * 3 * 3 + 0.5 * m_g * 9 * 9} - {10 * -3, 10 * -3 * -3 + 0.5 * m_g * 10 * 10}
         * delta f: {57, -102.163175}
         */
        t_real l_deltaFlux[2] = {0};
        tsunami_lab::solvers::FWave::computeDeltaFlux(10,
                                                      9,
                                                      -3,
                                                      3,
                                                      l_deltaFlux);
        REQUIRE( l_deltaFlux[0] == Approx(57) );
        REQUIRE( l_deltaFlux[1] == Approx(-102.163175) );
    }

**Test the computation of the eigencoefficients.** :raw-html:`</br>`
Using the equation for the `eigencoefficients <submission_1_eq_eigencoefficients_>`_ to calculate the following cases.

.. code-block:: cpp

    TEST_CASE( "Test the computation of the eigencoefficients.", "[FWaveEigencoefficients]")
    {
        /*
         * Test case:
         *  eigenvalue1: 4
         *  eigenvalue2: 5
         *  delta flux: {10, 2}
         *
         *    Matrix of right eigenvectors:
         *
         *      | 1   1 |
         *  R = |       |
         *      | 4   5 |
         *
         * inverted = {{5, -1}, {-4, 1}}
         *
         * inverted * {10, 2} = {48, -38}
         */
        t_real l_eigencoefficient1 = 0;
        t_real l_eigencoefficient2 = 0;
        t_real l_deltaFlux[2] = {10, 2};
        tsunami_lab::solvers::FWave::computeEigencoefficients(4,
                                                              5,
                                                              l_deltaFlux,
                                                              l_eigencoefficient1,
                                                              l_eigencoefficient2);
        REQUIRE( l_eigencoefficient1 == Approx(48) );
        REQUIRE( l_eigencoefficient2 == Approx(-38) );
    }

**Test the derivation of the F-Wave net-updates.** :raw-html:`</br>`
Finally the test cases for the net update combine all calculations above and using the `eigenvector <submission_1_eq_eigenvectors_>`_, the equation `(1.3.3) <submission_1_eq_133_>`_ and the `effect on the left and right waves <submission_1_eq_effect_on_waves_>`_.

.. code-block:: cpp

    TEST_CASE( "Test the derivation of the F-Wave net-updates.", "[FWaveUpdate]" )
    {
        /*
        * Test case:
        *
        *      left | right
        *  h:    10 | 9
        *  u:    -3 | 3
        *  hu:  -30 | 27
        *
        * The derivation of the eigenvalues (s1, s2) and eigencoefficient (a1, a1) is given above.
        *
        * The net-updates are given through the scaled eigenvectors.
        *
        *                      |  1 |   | 33.5590017014261447899292 |
        * update #1: s1 * a1 * |    | = |                           |
        *                      | s1 |   | -326.56631690591093200508 |
        *
        *                      |  1 |   | 23.4409982985738561366777 |
        * update #2: s2 * a2 * |    | = |                           |
        *                      | s2 |   | 224.403141905910928927533 |
        */
        float l_netUpdatesL[2] = { -5, 3 };
        float l_netUpdatesR[2] = {  4, 7 };

        tsunami_lab::solvers::FWave::netUpdates( 10,
                                                 9,
                                                 -30,
                                                 27,
                                                 l_netUpdatesL,
                                                 l_netUpdatesR );

        REQUIRE( l_netUpdatesL[0] == Approx( 33.5590017014261447899292 ) );
        REQUIRE( l_netUpdatesL[1] == Approx( -326.56631690591093200508 ) );

        REQUIRE( l_netUpdatesR[0] == Approx( 23.4409982985738561366777 ) );
        REQUIRE( l_netUpdatesR[1] == Approx( 224.403141905910928927533 ) );

        /*
        * Test case (dam break):
        *
        *     left | right
        *   h:  10 | 8
        *   hu:  0 | 0
        *
        * eigenvalues are given as:
        *
        *   s1 = -sqrt(9.80665 * 9)
        *   s2 =  sqrt(9.80665 * 9)
        *
        * Inversion of the matrix of right Eigenvectors:
        *
        *   wolframalpha.com query: invert {{1, 1}, {-sqrt(9.80665 * 9), sqrt(9.80665 * 9)}}
        *
        *          | 0.5 -0.0532217 |
        *   Rinv = |                |
        *          | 0.5 -0.0532217 |
        *
        * Multiplicaton with the jump in quantities gives the eigencoefficient:
        *
        *        | 8 - 10 |   | -1 |   | a1 |
        * Rinv * |        | = |    | = |    |
        *        |  0 - 0 |   | -1 |   | a2 |
        *
        * The net-updates are given through the scaled eigenvectors.
        *
        *                      |  1 |   |   9.394671362 |
        * update #1: s1 * a1 * |    | = |               |
        *                      | s1 |   | -88.25985     |
        *
        *                      |  1 |   |  -9.394671362 |
        * update #2: s2 * a2 * |    | = |               |
        *                      | s2 |   | -88.25985     |
        */
        tsunami_lab::solvers::FWave::netUpdates( 10,
                                                 8,
                                                 0,
                                                 0,
                                                 l_netUpdatesL,
                                                 l_netUpdatesR );

        REQUIRE( l_netUpdatesL[0] ==  Approx(9.394671362) );
        REQUIRE( l_netUpdatesL[1] == -Approx(88.25985)    );

        REQUIRE( l_netUpdatesR[0] == -Approx(9.394671362) );
        REQUIRE( l_netUpdatesR[1] == -Approx(88.25985)    );

        /*
        * Test case (dam break):
        *
        *        left | right
        *   h:     10 | 1
        *   hu:  -100 | 0
        *
        * eigenvalues are calculated from computeEigenvalues as:
        *
        *   s1 = -14.9416
        *   s2 = -0.253316
        *
        * eigencoefficient are calculated form computeEigencoefficients as:
        *
        *   a1 = 99.4054
        *   a2 = 0.594551
        *
        * The net-updates are given through the scaled eigenvectors.
        *
        *                      |  1 |   |     100     |
        * update #1: s1 * a1 * |    | = |             |
        *                      | s1 |   | -1485.4292  |
        *
        *                      |  1 |   |  0  |
        * update #2: s2 * a2 * |    | = |     |
        *                      | s2 |   |  0  |
        */

        tsunami_lab::solvers::FWave::netUpdates( 10,
                                                 1,
                                                 -100,
                                                 0,
                                                 l_netUpdatesL,
                                                 l_netUpdatesR );

        REQUIRE( l_netUpdatesL[0] == Approx(100) );
        REQUIRE( l_netUpdatesL[1] == Approx(-1485.4292) );

        REQUIRE( l_netUpdatesR[0] == Approx(0) );
        REQUIRE( l_netUpdatesR[1] == Approx(0) );

        /*
        * Test case (trivial steady state):
        *
        *     left | right
        *   h:  10 | 10
        *  hu:   0 |  0
        */
        tsunami_lab::solvers::FWave::netUpdates( 10,
                                                 10,
                                                 0,
                                                 0,
                                                 l_netUpdatesL,
                                                 l_netUpdatesR );

        REQUIRE( l_netUpdatesL[0] == Approx(0) );
        REQUIRE( l_netUpdatesL[1] == Approx(0) );

        REQUIRE( l_netUpdatesR[0] == Approx(0) );
        REQUIRE( l_netUpdatesR[1] == Approx(0) );
    }

Visualization 
-------------

Visualization of the *Height* and *Momentum X* with 1000 cells using `ParaView <https://www.paraview.org>`_.

**Height**

    .. raw:: html
        
        <center>
            <video width="700" controls>
                <source src="../_static/videos/01_Visulization_height.mp4" type="video/mp4">
            </video>
        </center>


**Momentum X**

    .. raw:: html

        <center>
            <video width="700" controls>
                <source src="../_static/videos/01_Visulization_momentum_x.mp4" type="video/mp4">
            </video>
        </center>

Sphinx with Doxygen
-------------------

1. First we install ``Doxygen``.

2. We install ``Sphinx`` and ``breathe`` and set breath as an extension. An installation guide can be found at :ref:`getting_started/building_docs:Building the Documentation`.
    
    .. code-block:: python

        extensions = [
            ...
            'breathe',
            ...
        ]

3. We set up the Doxyfile by setting the variables
    
    .. code-block::

        ...
        OUTPUT_DIRECTORY       = "_build"
        ...
        INPUT                  = "../include/"
        ...
        RECURSIVE              = YES
        ...
        GENERATE_XML           = YES
        ...

    ``GENERATE_XML`` is need, because breathe uses the xml files to generate the respective sphinx files.

4. We include the following code at the top of the ``conf.py`` to build the doxygen documentation together with sphinx.

    .. code-block:: python

        import subprocess

        subprocess.call('doxygen Doxyfile.in', shell=True)

5. We set up breathe by adding the following configurations to the ``conf.py``

    .. code-block:: python

        # -- Breathe configuration -------------------------------------------------

        breathe_projects = {
            "Tsunami Simulation": "_build/xml/",
        }

        breathe_default_project = "Tsunami Simulation"
        breathe_default_members = ('members', 'undoc-members')

6. Now we can include a whole namespace e.g. the *tsunami_lab::io* namespace into sphinx

    .. code-block:: rst

        .. doxygennamespace:: tsunami_lab::io
            :project: Tsunami Simulation
            :content-only:
            :members:
            :private-members:
            :undoc-members:
    
    More information about directives to include the doxygen into sphinx can be found at the `official breathe website <https://breathe.readthedocs.io/en/latest/directives.html>`_.


Contribution
------------

All team members contributed equally to the tasks.



.. [1] From https://scalable.uni-jena.de/opt/tsunami/chapters/assignment_1.html#f-wave-solver (29.10.2023)