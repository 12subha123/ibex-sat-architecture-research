ENTRY(_start)

PHDRS
{
    text PT_LOAD FLAGS(5);
}

SECTIONS
{
    . = 0x80;
    .text :
    {
        KEEP(*(.text.start))
        *(.text*)
    } :text

    /DISCARD/ :
    {
        *(.comment)
        *(.riscv.attributes)
        *(.note*)
    }
}
