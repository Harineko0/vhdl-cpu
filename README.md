# CPU made with VHDL
## Instructions
func: 6 bits, rs: 4 bits, rt: 4 bits, adr: 8 bits, ra: 4 bits
| Instruction        | Format | Description |
|--------------------|--------|-------------|
| RT $func, $rs, $rt | 0b00[func][rs][rt] | Register type |
| LD $rs, $adr       | 0b0100[rs][adr] | Load data from memory |
| ST $rs, $adr       | 0b0101[rs][adr] | Store data to memory |
| JZ $rs, $adr       | 0b1001[rs][adr] | Jump if zero |
| JU $adr            | 0b10000000[adr] | Jump unconditionally |
| SB $addr           | 0b01100000[addr] | Set bank |

| Func        | Operation |
|-------------|----------|
| 000010      | $rs = $rs + $rt |
| 010011      | $rs = $rs - $rt |
| 000111      | $rs = $rt - $rs |
| 011111      | $rs = $rs + 1   |
| 001110      | $rs = $rs - 1   |
| 000000      | $rs = $rs and $rt |
| 010101      | $rs = $rs or $rt |
| 001101      | $rs = not $rs |
| 110001      | $rs = not $rt |
| 001100      | $rs = $rs       |
| 110000      | $rs = $rt |

## Registers
| Name | Description |
|------|-------------|
| PC   | Program counter |
| MAR  | Memory address register |
| MBR  | Memory buffer register |
| AC[16]   | Accumulator |
| IR   | Instruction register |
| BSR  | Bank select register |

### Accumulators
| Name    | Number | Description |
|---------|--------|-------------|
| $0      | 0      | Constant 0  |
| $v0     | 1      | Return value |
| $a0~$a1 | 2~3    | Arguments   |
| $t0~$t7 | 4~11   | Temporaries |
| $gp     | 12     | Global pointer |
| $sp     | 13     | Stack pointer  |
| $fp     | 14     | Frame pointer  |
| $ra     | 15     | Return address |

## State transition
| State \ Instruction | RT                      | LD         | ST | JZ | JU | SB |
|---------------------|-------------------------|------------|----|----|----|----|
| e0                  | Load_MAR, Gate_PC       |            |    |    |    | Load_MAR, Gate_PC |
| e1                  | Load_Memory             |            |    |    |    | Load_Memory |
| e2                  | Load_AC, Gate_AC, ALU = $func |      |    |    |    | Load_BSR, Gate_MBR |
| e3                  | Inc_PC                  |            |    |    |    | Inc_PC |
| e4                  |                         |            |    |    |    |
| e5                  |                         |            |    |    |    |

