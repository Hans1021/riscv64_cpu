# Memory Map

| Start | End | Name | Notes |
| --- | --- | --- | --- |
| 0x0000_0000 | 0x0000_FFFF | ROM (reserved) | later boot ROM/firmware |
| 0x1000_0000 | 0x1000_0FFF | UART (reserved) | later MMIO console |
| 0x1000_1000 | 0x1000_1FFF | Timer (reserved) | later MMIO timer |
| 0x8000_0000 | 0x800F_FFFF | RAM | 1 MiB initial sim RAM |

reset PC -> 0x0000_0000
