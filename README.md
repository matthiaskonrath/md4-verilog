# md4-verilog
 Verilog implementation of the MD4 hashing algorithm (RFC 1320). 

### General information (pure verilog implementation)
- 85MHz speed was achived on the Nexys 4 (xc7a100tcsg324-1)
    - WNS=0.081 / TNS=0.0ns / WHS=0.051ns / THS=0.0ns
    - Total On-Chip Pwer: ~0.247W
- Computes every ~200 clock cycles a hash (includes reading and writing to FIFOs)


### Verilog resource utilization on Nexys 4 (xc7a100tcsg324-1)
(This inlcudes the test code from controller.v)
| Resource | Utilization | Available | Utilization (%) |
| ------ | ------ | ------ | ------ |
| LUT | 1875 | 63400 | 2.96 |
| FF | 911 | 126800 | 0.72 |
| BUFG | 2 | 32 | 6.25 |

### Speed tests
| Implementation | Device | Frequency | Speed (Hashes/s) | Notes |
| ------ | ------ | ------ | ------ | ------ |
| Verilog | Nexys4 | ~85 MHz | 425000 | not optimized implementation (at all) |

### Implementation information
##### For details see rc4_tb.v or controller.v
#### Instantiation
```verilog
module md4(
    input wire CLK,
    input wire RESET_N,
    // CONTROL
    input wire START_IN,
    output reg BUSY_OUT,
    output reg DONE_OUT,
    input wire [63:0] INPUT_SIZE_IN,
    // INPUT FIFO
    input wire [7:0] INPUT_BYTE,
    input wire INPUT_EMPTY,
    output reg INPUT_READ,
    // OUTPUT FIFO
    output reg [7:0] OUTPUT_BYTE,
    input wire OUTPUT_FULL,
    output reg OUTPUT_WRITE
);
```

### Useful links
- https://en.wikipedia.org/wiki/MD4
- https://tools.ietf.org/html/rfc1320
- https://www.binaryhexconverter.com/binary-to-hex-converter
- https://gchq.github.io/CyberChef
- https://reference.digilentinc.com/reference/programmable-logic/nexys-4/start
