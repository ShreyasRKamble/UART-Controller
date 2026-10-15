# Testbench index

Each testbench is a standalone SystemVerilog test module. Open `UART_16550.mpf` in Questa/ModelSim to access the registered sources. Start with the integrated tests when reviewing end-to-end behavior; use the focused tests to inspect individual blocks.

## Integrated behavior

| Testbench | Focus |
| --- | --- |
| `uart_16550_top_tb.sv` | Top-level register access, configuration, FIFO enable, loopback, and status/data reads |
| `uart_loopback_tb.sv` | Internal transmit-to-receive loopback |
| `uart_config_loopback_tb.sv` | Loopback across line configurations |

## Transmit and receive

| Testbench | Focus |
| --- | --- |
| `uart_tx_tb.sv` | Basic serial transmit |
| `uart_tx_config_tb.sv` | Transmit framing configuration |
| `uart_tx_fifo_tb.sv` | Buffered transmit |
| `uart_rx_tb.sv` | Basic serial receive |
| `uart_rx_config_tb.sv` | Receive framing and error behavior |
| `uart_rx_16x_tb.sv` | Oversampled receive path |
| `uart_rx_fifo_tb.sv` | Receive buffering and reads |
| `uart_rx_synchronizer_tb.sv` | RX input synchronization |
| `uart_rx_timeout_tb.sv` | Receive timeout behavior |

## Registers, FIFO, and timing

| Testbench | Focus |
| --- | --- |
| `uart_reg_interface_tb.sv` | Host register interface |
| `uart_lcr_tb.sv` | Line control register |
| `uart_fcr_tb.sv` | FIFO control register |
| `uart_fifo_tb.sv` | Generic FIFO |
| `uart_lsr_tb.sv` | Line status register |
| `uart_mcr_tb.sv` | Modem control register |
| `uart_msr_tb.sv` | Modem status register |
| `uart_scr_tb.sv` | Scratchpad register |
| `uart_psd_tb.sv` | Programmable speed/divisor support |
| `uart_divisor_tb.sv` | Divisor register behavior |
| `uart_baud_gen_tb.sv` | Fixed baud tick generator |
| `uart_baud_gen_prog_tb.sv` | Programmable baud tick generator |
| `uart_baud_gen_16x_tb.sv` | Fixed 16x sample tick generator |
| `uart_baud_gen_16x_prog_tb.sv` | Programmable 16x sample tick generator |
