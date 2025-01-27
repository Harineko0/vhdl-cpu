# CPU made with VHDL
## Instructions
func: 6 bits, rs: 4 bits, rt: 4 bits, adr: 8 bits, ra: 4 bits
|    Instruction     |        Format        |         Operation         |
| ------------------ | -------------------- | ------------------------- |
| RT $func, $rs, $rt | `0b00[func][rs][rt]` | $rs = $rs $func $rt       |
| LD $rs, $adr       | `0b0100[rs][adr___]` | $rs = memory[$adr]        |
| LDR $rs, $rt, $ra  | `0b0101[rs][rt][ra]` | $rs = memory[$rt + $ra]   |
| ST $rs, $adr       | `0b0110[rs][adr___]` | memory[$adr] = $rs        |
| STR $rs, $rt, $ra  | `0b0111[rs][rt][ra]` | memory[$rt + $ra] = $rs   |
| JZ $rs, $adr       | `0b1001[rs][adr___]` | pc = $rs == 0 ? $adr : pc |
| JNZ $rs, $adr      | `0b1010[rs][adr___]` | pc = $rs != 0 ? $adr : pc |
| JU $adr            | `0b10000000[adr___]` | pc = $adr                 |
| SB $adr            | `0b01100000[adr___]` | bsr = $addr               |


|  Func  |     Operation     |
| ------ | ----------------- |
| 000010 | $rs = $rs + $rt   |
| 010011 | $rs = $rs - $rt   |
| 000111 | $rs = $rt - $rs   |
| 011111 | $rs = $rs + 1     |
| 001110 | $rs = $rs - 1     |
| 000000 | $rs = $rs and $rt |
| 010101 | $rs = $rs or $rt  |
| 001101 | $rs = not $rs     |
| 110001 | $rs = not $rt     |
| 001100 | $rs = $rs         |
| 110000 | $rs = $rt         |

## Registers
|  Name  |       Description       |
| ------ | ----------------------- |
| PC     | Program counter         |
| MAR    | Memory address register |
| MBR    | Memory buffer register  |
| AC[16] | Accumulator             |
| IR     | Instruction register    |
| BSR    | Bank select register    |

### Accumulators
|  Name   | Number |  Description   |
| ------- | ------ | -------------- |
| $0      | 0      | Constant 0     |
| $at     | 1      | Assembler temp |
| $v0     | 2      | Return value   |
| $a0~$a1 | 3~4    | Arguments      |
| $t0~$t7 | 5~12   | Temporaries    |
| $sp     | 13     | Stack pointer  |
| $fp     | 14     | Frame pointer  |
| $ra     | 15     | Return address |

## State transition
| State \ Instruction |              RT               |              LD               |                        LDR                         | ST  | JZ  | JU  |         SB         |
| ------------------- | ----------------------------- | ----------------------------- | -------------------------------------------------- | --- | --- | --- | ------------------ |
| e0                  | Load_MAR, Gate_PC             | Load_MAR, Gate_PC             | Load_MAR, Gate_PC                                  |     |     |     | Load_MAR, Gate_PC  |
| e1                  | Load_Memory                   | Load_Memory                   | Load_Memory                                        |     |     |     | Load_Memory        |
| e2                  | Load_AC, Gate_AC, ALU = $func | Load_MAR, Gate_MBR            | Load_AC, Gate_AC, ALU = PASS, adr1 = at, adr2 = rt |     |     |     | Load_BSR, Gate_MBR |
| e3                  | Inc_PC                        | Load_Memory                   | Load_AC, Gate_AC, ALU = ADD,  adr1 = at, adr2 = ra |     |     |     | Inc_PC             |
| e4                  |                               | Load_AC, Gate_MBR, ALU = PASS | Load_MAR, Gate_A,  adr1 = at                       |     |     |     |                    |
| e5                  |                               | Inc_PC                        | Load_Memory                                        |     |     |     |                    |
| e6                  |                               |                               | Load_AC, Gate_MBR, ALU = PASS,  adr1 = rs          |     |     |     |                    |
| e7                  |                               |                               | Inc_PC                                             |     |     |     |                    |

# OS: Calculatos
## Subroutines
### write
Write a string to the screen.

| Arg |             Description              |
| --- | ------------------------------------ |
| adr | Head address of the string.s         |
| len | Length of the string. `0 < len <= 6` |

```
    LD $a0, adr
    LD $a1, len
    LD $ra, x
    JU write
x:  //

// write
write: LD $t0, chars
       LD $t2, display
       AND $t3, $0 // offset
y:     LDR $t1, $a0, $t0 // load char
       STR $t1, $t2, $t3 // display char
       INCR $t3, $0
       DECR $a1, $0
       JNZ $a1, y
       JU $ra // return

// 7 seg decoder char map
chars: 01111110 // 0
       00110000 // 1
       01101101 // 2

display: // memory mapped i/o
```

### read
Read a number from the keyboard.

| Arg |      Description      |
| --- | --------------------- |
| adr | Address of the buffer |
| len | Buffer size           |

```
    LD $a0, adr
    LD $a1, len
    LD $ra, x
    JU read
x:  //

read: LD $t0, chars
      LD $t1, display
      AND $t2, $0 // offset
```


## Flow
Key(3): Input number
Key(2): Input operator
Key(1): Calculate

1. Display "Calculator" on the screen for 2 seconds
2. Wait for input
3. If key(3) is pressed, display the number on the screen