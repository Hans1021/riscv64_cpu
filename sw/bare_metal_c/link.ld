ENTRY(_start)

RAM_ORIGIN = 0x80000000;
RAM_LENGTH = 1M;

SECTIONS
{
  . = RAM_ORIGIN;

  .text : ALIGN(16) {
    *(.text .text.*)
  }

  .rodata : ALIGN(16) {
    *(.rodata .rodata.*)
  }

  .data : ALIGN(16) {
    __data_start = .;
    *(.data .data.*)
    __data_end = .;
  }

  .bss : ALIGN(16) {
    __bss_start = .;
    *(.bss .bss.*)
    *(COMMON)
    __bss_end = .;
  }

  /* Stack at top of RAM */
  _stack_top = RAM_ORIGIN + RAM_LENGTH;
}
