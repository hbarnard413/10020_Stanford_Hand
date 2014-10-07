.. _ecat_fwu_programming_label:

Using Module EtherCAT Firmwareupdater
=====================================

To make automatic firmware updates over EtherCATs FoE (File over EtherCAT) possible
one needs to add the function firmware_update_loop() to the main function of
the user application.

If data is received on the FoE Mailbox channel the firmware_update_loop()
registers the data and updates the local firmware and the firmware of any
subsequent nodes.

The firmware update handler must be started on tile 0 to work properly and
enable automatic updates.

A basic example will look like this

::

  #define COM_TILE   0

  void main(void) {
	chan coe_in;
	chan coe_out;
	chan eoe_in;
	chan eoe_out;
	chan eoe_sig;
	chan foe_in;
	chan foe_out;
	chan pdo_in;
	chan pdo_out;
	chan sig_1;
	chan c_flash_data;
	chan c_nodes[2];

	...

	par
	{
		on tile[COM_TILE] :
		{
			ecat_init();
			ecat_handler(coe_out, coe_in, eoe_out, eoe_in, eoe_sig, foe_out, foe_in, pdo_out, pdo_in);
		}

		on tile[COM_TILE] :
		{
			firmware_update_loop(p_spi_flash, foe_out, foe_in, c_flash_data, c_nodes, sig_1); // firmware update over ethercat
		}

	        ...
	}
  ...
  }

This example is a rough draft and left out most of the necessary
implementation. But it should give an impressen how to set up the firmware
update handler to enable automatic firmware updates to the nodes application
code.

Through the channel c_nodes[] it is possible to connect up to 17 nodes, which
are also updated by this firmware updater.

