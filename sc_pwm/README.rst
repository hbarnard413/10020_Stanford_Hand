SOMANET Symmetrical PWM Software Component
.........................................

:Latest release: 1.0.1rc4
:Maintainer: Synapticon
:Description: SOMANET version of the original XMOS Symmetrical PWM module


:Description: The Pulse Width Modulation(PWM) components generates a symmetrical PWM signal. NOTE: Only for use with SOMANET system from Synapticon

Key Features
============

  * The components can be configured for Leading edge, Trailing edge and Center edge variations
  * Configurable timestep, resolution

Firmware Overview
=================

The components will run in a par with the following function which does not terminate. A single function starts the pwm server and passes it a channel with 
which it will communicate with the client, a clock block required for the clocking of the required ports, an array of ports on which the pwm signals will be generated, and the number of ports in the array. 

Known Issues
============

none

License
=======

Please see `LICENSE`_.

.. _LICENSE: https://github.com/synapticon/sc_pwm/blob/master/LICENSE.dox

Required software (dependencies)
================================

  * None

