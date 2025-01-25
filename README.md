# Instructions
func: 6 bits, rs: 4 bits, rt: 4 bits, adr: 8 bits
| Instruction        | Format |
|--------------------|--------|
| RT $func, $rs, $rt | 0b00[func][rs][rt] |
| LD $rs, $adr       | 0b0100[rs][adr] |
| ST $rs, $adr       | 0b0101[rs][adr] |
| JZ $rs, $adr       | 0b1001[rs][adr] |
| JU $adr            | 0b10000000[adr] |

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

# Registers
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

# State transition
| State \ Instruction | RT | LD | ST | JZ | JU |
|---------------------|----|----|----|----|----|
| e0                  | Load_MAR, Gate_PC |  |  |  |  |
| e1                  | Load_Memory |  |  |  |  |
| e2                  | Load_AC, Gate_AC, ALU = $sfunc |  |  |  |  |
| e3                  | Inc_PC |  |  |  |  |
| e4                  |  |  |  |  |  |
| e5                  |  | |  |  |  |
