
Project structure
=================

There is only one function to call so the system can update itself through
EtherCAT FoE transfers. If data is received on the FoE Mailbox channel
the firmware_update_loop() registers the data and updates the local
firmware and the firmware of any subsequent nodes.

Symbolic constants
==================

.. doxygendefine:: BUFFER_SIZE
.. doxygendefine:: READY_TO_FLASH

API
===

.. doxygenfunction:: firmware_update_loop

