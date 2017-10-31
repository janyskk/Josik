
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 0c 17 f0       	mov    $0xf0170c50,%eax
f010004b:	2d 26 fd 16 f0       	sub    $0xf016fd26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 fd 16 f0       	push   $0xf016fd26
f0100058:	e8 0c 41 00 00       	call   f0104169 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 46 10 f0       	push   $0xf0104600
f010006f:	e8 ad 2e 00 00       	call   f0102f21 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 07 10 00 00       	call   f0101080 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 f5 28 00 00       	call   f0102973 <env_init>
	trap_init();
f010007e:	e8 0f 2f 00 00       	call   f0102f92 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 a3 11 f0       	push   $0xf011a356
f010008d:	e8 88 2a 00 00       	call   f0102b1a <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 84 ff 16 f0    	pushl  0xf016ff84
f010009b:	e8 b8 2d 00 00       	call   f0102e58 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 0c 17 f0 00 	cmpl   $0x0,0xf0170c40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 0c 17 f0    	mov    %esi,0xf0170c40

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 1b 46 10 f0       	push   $0xf010461b
f01000ca:	e8 52 2e 00 00       	call   f0102f21 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 22 2e 00 00       	call   f0102efb <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 a3 55 10 f0 	movl   $0xf01055a3,(%esp)
f01000e0:	e8 3c 2e 00 00       	call   f0102f21 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 ff 06 00 00       	call   f01007f1 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 33 46 10 f0       	push   $0xf0104633
f010010c:	e8 10 2e 00 00       	call   f0102f21 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 de 2d 00 00       	call   f0102efb <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 a3 55 10 f0 	movl   $0xf01055a3,(%esp)
f0100124:	e8 f8 2d 00 00       	call   f0102f21 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 ff 16 f0    	mov    0xf016ff64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 ff 16 f0    	mov    %edx,0xf016ff64
f010016e:	88 81 60 fd 16 f0    	mov    %al,-0xfe902a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 ff 16 f0 00 	movl   $0x0,0xf016ff64
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f8 00 00 00    	je     f0100299 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001a1:	a8 20                	test   $0x20,%al
f01001a3:	0f 85 f6 00 00 00    	jne    f010029f <kbd_proc_data+0x10c>
f01001a9:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ae:	ec                   	in     (%dx),%al
f01001af:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b1:	3c e0                	cmp    $0xe0,%al
f01001b3:	75 0d                	jne    f01001c2 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001b5:	83 0d 40 fd 16 f0 40 	orl    $0x40,0xf016fd40
		return 0;
f01001bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c1:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c2:	55                   	push   %ebp
f01001c3:	89 e5                	mov    %esp,%ebp
f01001c5:	53                   	push   %ebx
f01001c6:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c9:	84 c0                	test   %al,%al
f01001cb:	79 36                	jns    f0100203 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cd:	8b 0d 40 fd 16 f0    	mov    0xf016fd40,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 a0 47 10 f0 	movzbl -0xfefb860(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 40 fd 16 f0       	mov    %eax,0xf016fd40
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 40 fd 16 f0    	mov    0xf016fd40,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 40 fd 16 f0    	mov    %ecx,0xf016fd40
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 a0 47 10 f0 	movzbl -0xfefb860(%edx),%eax
f0100226:	0b 05 40 fd 16 f0    	or     0xf016fd40,%eax
f010022c:	0f b6 8a a0 46 10 f0 	movzbl -0xfefb960(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 40 fd 16 f0       	mov    %eax,0xf016fd40

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 80 46 10 f0 	mov    -0xfefb980(,%ecx,4),%ecx
f0100246:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010024d:	a8 08                	test   $0x8,%al
f010024f:	74 1b                	je     f010026c <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100251:	89 da                	mov    %ebx,%edx
f0100253:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100256:	83 f9 19             	cmp    $0x19,%ecx
f0100259:	77 05                	ja     f0100260 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010025b:	83 eb 20             	sub    $0x20,%ebx
f010025e:	eb 0c                	jmp    f010026c <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100260:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100263:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100266:	83 fa 19             	cmp    $0x19,%edx
f0100269:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026c:	f7 d0                	not    %eax
f010026e:	a8 06                	test   $0x6,%al
f0100270:	75 33                	jne    f01002a5 <kbd_proc_data+0x112>
f0100272:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100278:	75 2b                	jne    f01002a5 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f010027a:	83 ec 0c             	sub    $0xc,%esp
f010027d:	68 4d 46 10 f0       	push   $0xf010464d
f0100282:	e8 9a 2c 00 00       	call   f0102f21 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100287:	ba 92 00 00 00       	mov    $0x92,%edx
f010028c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100291:	ee                   	out    %al,(%dx)
f0100292:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100295:	89 d8                	mov    %ebx,%eax
f0100297:	eb 0e                	jmp    f01002a7 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010029e:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010029f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a4:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a5:	89 d8                	mov    %ebx,%eax
}
f01002a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002aa:	c9                   	leave  
f01002ab:	c3                   	ret    

f01002ac <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ac:	55                   	push   %ebp
f01002ad:	89 e5                	mov    %esp,%ebp
f01002af:	57                   	push   %edi
f01002b0:	56                   	push   %esi
f01002b1:	53                   	push   %ebx
f01002b2:	83 ec 1c             	sub    $0x1c,%esp
f01002b5:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002b7:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002bc:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002c1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c6:	eb 09                	jmp    f01002d1 <cons_putc+0x25>
f01002c8:	89 ca                	mov    %ecx,%edx
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	ec                   	in     (%dx),%al
f01002cc:	ec                   	in     (%dx),%al
f01002cd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ce:	83 c3 01             	add    $0x1,%ebx
f01002d1:	89 f2                	mov    %esi,%edx
f01002d3:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d4:	a8 20                	test   $0x20,%al
f01002d6:	75 08                	jne    f01002e0 <cons_putc+0x34>
f01002d8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002de:	7e e8                	jle    f01002c8 <cons_putc+0x1c>
f01002e0:	89 f8                	mov    %edi,%eax
f01002e2:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002ea:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002eb:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f0:	be 79 03 00 00       	mov    $0x379,%esi
f01002f5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fa:	eb 09                	jmp    f0100305 <cons_putc+0x59>
f01002fc:	89 ca                	mov    %ecx,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	ec                   	in     (%dx),%al
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	83 c3 01             	add    $0x1,%ebx
f0100305:	89 f2                	mov    %esi,%edx
f0100307:	ec                   	in     (%dx),%al
f0100308:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010030e:	7f 04                	jg     f0100314 <cons_putc+0x68>
f0100310:	84 c0                	test   %al,%al
f0100312:	79 e8                	jns    f01002fc <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	ba 78 03 00 00       	mov    $0x378,%edx
f0100319:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010031d:	ee                   	out    %al,(%dx)
f010031e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100323:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100328:	ee                   	out    %al,(%dx)
f0100329:	b8 08 00 00 00       	mov    $0x8,%eax
f010032e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032f:	89 fa                	mov    %edi,%edx
f0100331:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	80 cc 07             	or     $0x7,%ah
f010033c:	85 d2                	test   %edx,%edx
f010033e:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100341:	89 f8                	mov    %edi,%eax
f0100343:	0f b6 c0             	movzbl %al,%eax
f0100346:	83 f8 09             	cmp    $0x9,%eax
f0100349:	74 74                	je     f01003bf <cons_putc+0x113>
f010034b:	83 f8 09             	cmp    $0x9,%eax
f010034e:	7f 0a                	jg     f010035a <cons_putc+0xae>
f0100350:	83 f8 08             	cmp    $0x8,%eax
f0100353:	74 14                	je     f0100369 <cons_putc+0xbd>
f0100355:	e9 99 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
f010035a:	83 f8 0a             	cmp    $0xa,%eax
f010035d:	74 3a                	je     f0100399 <cons_putc+0xed>
f010035f:	83 f8 0d             	cmp    $0xd,%eax
f0100362:	74 3d                	je     f01003a1 <cons_putc+0xf5>
f0100364:	e9 8a 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100369:	0f b7 05 68 ff 16 f0 	movzwl 0xf016ff68,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 68 ff 16 f0    	mov    %ax,0xf016ff68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 6c ff 16 f0    	mov    0xf016ff6c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 68 ff 16 f0 	addw   $0x50,0xf016ff68
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 68 ff 16 f0 	movzwl 0xf016ff68,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 68 ff 16 f0    	mov    %ax,0xf016ff68
f01003bd:	eb 52                	jmp    f0100411 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003bf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c4:	e8 e3 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 d9 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 cf fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 c5 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 bb fe ff ff       	call   f01002ac <cons_putc>
f01003f1:	eb 1e                	jmp    f0100411 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f3:	0f b7 05 68 ff 16 f0 	movzwl 0xf016ff68,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 68 ff 16 f0 	mov    %dx,0xf016ff68
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 6c ff 16 f0    	mov    0xf016ff6c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 68 ff 16 f0 	cmpw   $0x7cf,0xf016ff68
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 6c ff 16 f0       	mov    0xf016ff6c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 80 3d 00 00       	call   f01041b6 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 6c ff 16 f0    	mov    0xf016ff6c,%edx
f010043c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100442:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100448:	83 c4 10             	add    $0x10,%esp
f010044b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100450:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100453:	39 d0                	cmp    %edx,%eax
f0100455:	75 f4                	jne    f010044b <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100457:	66 83 2d 68 ff 16 f0 	subw   $0x50,0xf016ff68
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 70 ff 16 f0    	mov    0xf016ff70,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 68 ff 16 f0 	movzwl 0xf016ff68,%ebx
f0100474:	8d 71 01             	lea    0x1(%ecx),%esi
f0100477:	89 d8                	mov    %ebx,%eax
f0100479:	66 c1 e8 08          	shr    $0x8,%ax
f010047d:	89 f2                	mov    %esi,%edx
f010047f:	ee                   	out    %al,(%dx)
f0100480:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100485:	89 ca                	mov    %ecx,%edx
f0100487:	ee                   	out    %al,(%dx)
f0100488:	89 d8                	mov    %ebx,%eax
f010048a:	89 f2                	mov    %esi,%edx
f010048c:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100490:	5b                   	pop    %ebx
f0100491:	5e                   	pop    %esi
f0100492:	5f                   	pop    %edi
f0100493:	5d                   	pop    %ebp
f0100494:	c3                   	ret    

f0100495 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100495:	80 3d 74 ff 16 f0 00 	cmpb   $0x0,0xf016ff74
f010049c:	74 11                	je     f01004af <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010049e:	55                   	push   %ebp
f010049f:	89 e5                	mov    %esp,%ebp
f01004a1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a4:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f01004a9:	e8 a2 fc ff ff       	call   f0100150 <cons_intr>
}
f01004ae:	c9                   	leave  
f01004af:	f3 c3                	repz ret 

f01004b1 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b1:	55                   	push   %ebp
f01004b2:	89 e5                	mov    %esp,%ebp
f01004b4:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b7:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004bc:	e8 8f fc ff ff       	call   f0100150 <cons_intr>
}
f01004c1:	c9                   	leave  
f01004c2:	c3                   	ret    

f01004c3 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c9:	e8 c7 ff ff ff       	call   f0100495 <serial_intr>
	kbd_intr();
f01004ce:	e8 de ff ff ff       	call   f01004b1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d3:	a1 60 ff 16 f0       	mov    0xf016ff60,%eax
f01004d8:	3b 05 64 ff 16 f0    	cmp    0xf016ff64,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 60 ff 16 f0    	mov    %edx,0xf016ff60
f01004e9:	0f b6 88 60 fd 16 f0 	movzbl -0xfe902a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f0:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f8:	75 11                	jne    f010050b <cons_getc+0x48>
			cons.rpos = 0;
f01004fa:	c7 05 60 ff 16 f0 00 	movl   $0x0,0xf016ff60
f0100501:	00 00 00 
f0100504:	eb 05                	jmp    f010050b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100506:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050b:	c9                   	leave  
f010050c:	c3                   	ret    

f010050d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050d:	55                   	push   %ebp
f010050e:	89 e5                	mov    %esp,%ebp
f0100510:	57                   	push   %edi
f0100511:	56                   	push   %esi
f0100512:	53                   	push   %ebx
f0100513:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100516:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100524:	5a a5 
	if (*cp != 0xA55A) {
f0100526:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100531:	74 11                	je     f0100544 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100533:	c7 05 70 ff 16 f0 b4 	movl   $0x3b4,0xf016ff70
f010053a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100542:	eb 16                	jmp    f010055a <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100544:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054b:	c7 05 70 ff 16 f0 d4 	movl   $0x3d4,0xf016ff70
f0100552:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100555:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055a:	8b 3d 70 ff 16 f0    	mov    0xf016ff70,%edi
f0100560:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100565:	89 fa                	mov    %edi,%edx
f0100567:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100568:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
f010056e:	0f b6 c8             	movzbl %al,%ecx
f0100571:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100574:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100579:	89 fa                	mov    %edi,%edx
f010057b:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010057f:	89 35 6c ff 16 f0    	mov    %esi,0xf016ff6c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 68 ff 16 f0    	mov    %ax,0xf016ff68
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100590:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100595:	b8 00 00 00 00       	mov    $0x0,%eax
f010059a:	89 f2                	mov    %esi,%edx
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005db:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e9:	3c ff                	cmp    $0xff,%al
f01005eb:	0f 95 05 74 ff 16 f0 	setne  0xf016ff74
f01005f2:	89 f2                	mov    %esi,%edx
f01005f4:	ec                   	in     (%dx),%al
f01005f5:	89 da                	mov    %ebx,%edx
f01005f7:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f8:	80 f9 ff             	cmp    $0xff,%cl
f01005fb:	75 10                	jne    f010060d <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005fd:	83 ec 0c             	sub    $0xc,%esp
f0100600:	68 59 46 10 f0       	push   $0xf0104659
f0100605:	e8 17 29 00 00       	call   f0102f21 <cprintf>
f010060a:	83 c4 10             	add    $0x10,%esp
}
f010060d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100610:	5b                   	pop    %ebx
f0100611:	5e                   	pop    %esi
f0100612:	5f                   	pop    %edi
f0100613:	5d                   	pop    %ebp
f0100614:	c3                   	ret    

f0100615 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100615:	55                   	push   %ebp
f0100616:	89 e5                	mov    %esp,%ebp
f0100618:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010061b:	8b 45 08             	mov    0x8(%ebp),%eax
f010061e:	e8 89 fc ff ff       	call   f01002ac <cons_putc>
}
f0100623:	c9                   	leave  
f0100624:	c3                   	ret    

f0100625 <getchar>:

int
getchar(void)
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010062b:	e8 93 fe ff ff       	call   f01004c3 <cons_getc>
f0100630:	85 c0                	test   %eax,%eax
f0100632:	74 f7                	je     f010062b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100634:	c9                   	leave  
f0100635:	c3                   	ret    

f0100636 <iscons>:

int
iscons(int fdnum)
{
f0100636:	55                   	push   %ebp
f0100637:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100639:	b8 01 00 00 00       	mov    $0x1,%eax
f010063e:	5d                   	pop    %ebp
f010063f:	c3                   	ret    

f0100640 <mon_help>:
	
};

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	68 a0 48 10 f0       	push   $0xf01048a0
f010064b:	68 be 48 10 f0       	push   $0xf01048be
f0100650:	68 c3 48 10 f0       	push   $0xf01048c3
f0100655:	e8 c7 28 00 00       	call   f0102f21 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 98 49 10 f0       	push   $0xf0104998
f0100662:	68 cc 48 10 f0       	push   $0xf01048cc
f0100667:	68 c3 48 10 f0       	push   $0xf01048c3
f010066c:	e8 b0 28 00 00       	call   f0102f21 <cprintf>
f0100671:	83 c4 0c             	add    $0xc,%esp
f0100674:	68 d5 48 10 f0       	push   $0xf01048d5
f0100679:	68 f2 48 10 f0       	push   $0xf01048f2
f010067e:	68 c3 48 10 f0       	push   $0xf01048c3
f0100683:	e8 99 28 00 00       	call   f0102f21 <cprintf>
	return 0;
}
f0100688:	b8 00 00 00 00       	mov    $0x0,%eax
f010068d:	c9                   	leave  
f010068e:	c3                   	ret    

f010068f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010068f:	55                   	push   %ebp
f0100690:	89 e5                	mov    %esp,%ebp
f0100692:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100695:	68 fc 48 10 f0       	push   $0xf01048fc
f010069a:	e8 82 28 00 00       	call   f0102f21 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010069f:	83 c4 08             	add    $0x8,%esp
f01006a2:	68 0c 00 10 00       	push   $0x10000c
f01006a7:	68 c0 49 10 f0       	push   $0xf01049c0
f01006ac:	e8 70 28 00 00       	call   f0102f21 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 0c 00 10 00       	push   $0x10000c
f01006b9:	68 0c 00 10 f0       	push   $0xf010000c
f01006be:	68 e8 49 10 f0       	push   $0xf01049e8
f01006c3:	e8 59 28 00 00       	call   f0102f21 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 f1 45 10 00       	push   $0x1045f1
f01006d0:	68 f1 45 10 f0       	push   $0xf01045f1
f01006d5:	68 0c 4a 10 f0       	push   $0xf0104a0c
f01006da:	e8 42 28 00 00       	call   f0102f21 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 26 fd 16 00       	push   $0x16fd26
f01006e7:	68 26 fd 16 f0       	push   $0xf016fd26
f01006ec:	68 30 4a 10 f0       	push   $0xf0104a30
f01006f1:	e8 2b 28 00 00       	call   f0102f21 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	83 c4 0c             	add    $0xc,%esp
f01006f9:	68 50 0c 17 00       	push   $0x170c50
f01006fe:	68 50 0c 17 f0       	push   $0xf0170c50
f0100703:	68 54 4a 10 f0       	push   $0xf0104a54
f0100708:	e8 14 28 00 00       	call   f0102f21 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010070d:	b8 4f 10 17 f0       	mov    $0xf017104f,%eax
f0100712:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100717:	83 c4 08             	add    $0x8,%esp
f010071a:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010071f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100725:	85 c0                	test   %eax,%eax
f0100727:	0f 48 c2             	cmovs  %edx,%eax
f010072a:	c1 f8 0a             	sar    $0xa,%eax
f010072d:	50                   	push   %eax
f010072e:	68 78 4a 10 f0       	push   $0xf0104a78
f0100733:	e8 e9 27 00 00       	call   f0102f21 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100738:	b8 00 00 00 00       	mov    $0x0,%eax
f010073d:	c9                   	leave  
f010073e:	c3                   	ret    

f010073f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010073f:	55                   	push   %ebp
f0100740:	89 e5                	mov    %esp,%ebp
f0100742:	57                   	push   %edi
f0100743:	56                   	push   %esi
f0100744:	53                   	push   %ebx
f0100745:	83 ec 48             	sub    $0x48,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100748:	89 ee                	mov    %ebp,%esi
	struct Eipdebuginfo info;
  uint32_t ebp = read_ebp(), eip = 0;
  uint32_t* ebpp;
  cprintf("Stack backtrace:");
f010074a:	68 15 49 10 f0       	push   $0xf0104915
f010074f:	e8 cd 27 00 00       	call   f0102f21 <cprintf>
  while(ebp){//if ebp is 0, we are back at the first caller
f0100754:	83 c4 10             	add    $0x10,%esp
f0100757:	eb 7a                	jmp    f01007d3 <mon_backtrace+0x94>
    ebpp = (uint32_t*) ebp;
f0100759:	89 75 c4             	mov    %esi,-0x3c(%ebp)
    eip = *(ebpp+1);
f010075c:	8b 7e 04             	mov    0x4(%esi),%edi
    cprintf("\n  ebp %08x eip %08x args ", ebp, eip);
f010075f:	83 ec 04             	sub    $0x4,%esp
f0100762:	57                   	push   %edi
f0100763:	56                   	push   %esi
f0100764:	68 26 49 10 f0       	push   $0xf0104926
f0100769:	e8 b3 27 00 00       	call   f0102f21 <cprintf>
f010076e:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100771:	83 c6 1c             	add    $0x1c,%esi
f0100774:	83 c4 10             	add    $0x10,%esp

    int argno = 0;
    for(; argno < 5; argno++){
      cprintf("%08x ", *(ebpp+2+argno));
f0100777:	83 ec 08             	sub    $0x8,%esp
f010077a:	ff 33                	pushl  (%ebx)
f010077c:	68 41 49 10 f0       	push   $0xf0104941
f0100781:	e8 9b 27 00 00       	call   f0102f21 <cprintf>
f0100786:	83 c3 04             	add    $0x4,%ebx
    ebpp = (uint32_t*) ebp;
    eip = *(ebpp+1);
    cprintf("\n  ebp %08x eip %08x args ", ebp, eip);

    int argno = 0;
    for(; argno < 5; argno++){
f0100789:	83 c4 10             	add    $0x10,%esp
f010078c:	39 f3                	cmp    %esi,%ebx
f010078e:	75 e7                	jne    f0100777 <mon_backtrace+0x38>
      cprintf("%08x ", *(ebpp+2+argno));
    }
	if(debuginfo_eip(eip, &info) == 0){
f0100790:	83 ec 08             	sub    $0x8,%esp
f0100793:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100796:	50                   	push   %eax
f0100797:	57                   	push   %edi
f0100798:	e8 f4 2f 00 00       	call   f0103791 <debuginfo_eip>
f010079d:	83 c4 10             	add    $0x10,%esp
f01007a0:	85 c0                	test   %eax,%eax
f01007a2:	75 2a                	jne    f01007ce <mon_backtrace+0x8f>
      cprintf("\n\t%s:%d: ", info.eip_file, info.eip_line);
f01007a4:	83 ec 04             	sub    $0x4,%esp
f01007a7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007aa:	ff 75 d0             	pushl  -0x30(%ebp)
f01007ad:	68 47 49 10 f0       	push   $0xf0104947
f01007b2:	e8 6a 27 00 00       	call   f0102f21 <cprintf>
      cprintf("%.*s+%d", info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f01007b7:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01007ba:	57                   	push   %edi
f01007bb:	ff 75 d8             	pushl  -0x28(%ebp)
f01007be:	ff 75 dc             	pushl  -0x24(%ebp)
f01007c1:	68 51 49 10 f0       	push   $0xf0104951
f01007c6:	e8 56 27 00 00       	call   f0102f21 <cprintf>
f01007cb:	83 c4 20             	add    $0x20,%esp
    }
    ebp = *ebpp;
f01007ce:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01007d1:	8b 30                	mov    (%eax),%esi
{
	struct Eipdebuginfo info;
  uint32_t ebp = read_ebp(), eip = 0;
  uint32_t* ebpp;
  cprintf("Stack backtrace:");
  while(ebp){//if ebp is 0, we are back at the first caller
f01007d3:	85 f6                	test   %esi,%esi
f01007d5:	75 82                	jne    f0100759 <mon_backtrace+0x1a>
      cprintf("%.*s+%d", info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
    }
    ebp = *ebpp;

  }
  cprintf("\n");
f01007d7:	83 ec 0c             	sub    $0xc,%esp
f01007da:	68 a3 55 10 f0       	push   $0xf01055a3
f01007df:	e8 3d 27 00 00       	call   f0102f21 <cprintf>
  return 0;	
}
f01007e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007ec:	5b                   	pop    %ebx
f01007ed:	5e                   	pop    %esi
f01007ee:	5f                   	pop    %edi
f01007ef:	5d                   	pop    %ebp
f01007f0:	c3                   	ret    

f01007f1 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007f1:	55                   	push   %ebp
f01007f2:	89 e5                	mov    %esp,%ebp
f01007f4:	57                   	push   %edi
f01007f5:	56                   	push   %esi
f01007f6:	53                   	push   %ebx
f01007f7:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007fa:	68 a4 4a 10 f0       	push   $0xf0104aa4
f01007ff:	e8 1d 27 00 00       	call   f0102f21 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100804:	c7 04 24 c8 4a 10 f0 	movl   $0xf0104ac8,(%esp)
f010080b:	e8 11 27 00 00       	call   f0102f21 <cprintf>

	if (tf != NULL)
f0100810:	83 c4 10             	add    $0x10,%esp
f0100813:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100817:	74 0e                	je     f0100827 <monitor+0x36>
		print_trapframe(tf);
f0100819:	83 ec 0c             	sub    $0xc,%esp
f010081c:	ff 75 08             	pushl  0x8(%ebp)
f010081f:	e8 37 2b 00 00       	call   f010335b <print_trapframe>
f0100824:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100827:	83 ec 0c             	sub    $0xc,%esp
f010082a:	68 59 49 10 f0       	push   $0xf0104959
f010082f:	e8 de 36 00 00       	call   f0103f12 <readline>
f0100834:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100836:	83 c4 10             	add    $0x10,%esp
f0100839:	85 c0                	test   %eax,%eax
f010083b:	74 ea                	je     f0100827 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010083d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100844:	be 00 00 00 00       	mov    $0x0,%esi
f0100849:	eb 0a                	jmp    f0100855 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010084b:	c6 03 00             	movb   $0x0,(%ebx)
f010084e:	89 f7                	mov    %esi,%edi
f0100850:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100853:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100855:	0f b6 03             	movzbl (%ebx),%eax
f0100858:	84 c0                	test   %al,%al
f010085a:	74 63                	je     f01008bf <monitor+0xce>
f010085c:	83 ec 08             	sub    $0x8,%esp
f010085f:	0f be c0             	movsbl %al,%eax
f0100862:	50                   	push   %eax
f0100863:	68 5d 49 10 f0       	push   $0xf010495d
f0100868:	e8 bf 38 00 00       	call   f010412c <strchr>
f010086d:	83 c4 10             	add    $0x10,%esp
f0100870:	85 c0                	test   %eax,%eax
f0100872:	75 d7                	jne    f010084b <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100874:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100877:	74 46                	je     f01008bf <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100879:	83 fe 0f             	cmp    $0xf,%esi
f010087c:	75 14                	jne    f0100892 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010087e:	83 ec 08             	sub    $0x8,%esp
f0100881:	6a 10                	push   $0x10
f0100883:	68 62 49 10 f0       	push   $0xf0104962
f0100888:	e8 94 26 00 00       	call   f0102f21 <cprintf>
f010088d:	83 c4 10             	add    $0x10,%esp
f0100890:	eb 95                	jmp    f0100827 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100892:	8d 7e 01             	lea    0x1(%esi),%edi
f0100895:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100899:	eb 03                	jmp    f010089e <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010089b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010089e:	0f b6 03             	movzbl (%ebx),%eax
f01008a1:	84 c0                	test   %al,%al
f01008a3:	74 ae                	je     f0100853 <monitor+0x62>
f01008a5:	83 ec 08             	sub    $0x8,%esp
f01008a8:	0f be c0             	movsbl %al,%eax
f01008ab:	50                   	push   %eax
f01008ac:	68 5d 49 10 f0       	push   $0xf010495d
f01008b1:	e8 76 38 00 00       	call   f010412c <strchr>
f01008b6:	83 c4 10             	add    $0x10,%esp
f01008b9:	85 c0                	test   %eax,%eax
f01008bb:	74 de                	je     f010089b <monitor+0xaa>
f01008bd:	eb 94                	jmp    f0100853 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01008bf:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008c6:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008c7:	85 f6                	test   %esi,%esi
f01008c9:	0f 84 58 ff ff ff    	je     f0100827 <monitor+0x36>
f01008cf:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008d4:	83 ec 08             	sub    $0x8,%esp
f01008d7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008da:	ff 34 85 00 4b 10 f0 	pushl  -0xfefb500(,%eax,4)
f01008e1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e4:	e8 e5 37 00 00       	call   f01040ce <strcmp>
f01008e9:	83 c4 10             	add    $0x10,%esp
f01008ec:	85 c0                	test   %eax,%eax
f01008ee:	75 21                	jne    f0100911 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01008f0:	83 ec 04             	sub    $0x4,%esp
f01008f3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008f6:	ff 75 08             	pushl  0x8(%ebp)
f01008f9:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008fc:	52                   	push   %edx
f01008fd:	56                   	push   %esi
f01008fe:	ff 14 85 08 4b 10 f0 	call   *-0xfefb4f8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100905:	83 c4 10             	add    $0x10,%esp
f0100908:	85 c0                	test   %eax,%eax
f010090a:	78 25                	js     f0100931 <monitor+0x140>
f010090c:	e9 16 ff ff ff       	jmp    f0100827 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100911:	83 c3 01             	add    $0x1,%ebx
f0100914:	83 fb 03             	cmp    $0x3,%ebx
f0100917:	75 bb                	jne    f01008d4 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100919:	83 ec 08             	sub    $0x8,%esp
f010091c:	ff 75 a8             	pushl  -0x58(%ebp)
f010091f:	68 7f 49 10 f0       	push   $0xf010497f
f0100924:	e8 f8 25 00 00       	call   f0102f21 <cprintf>
f0100929:	83 c4 10             	add    $0x10,%esp
f010092c:	e9 f6 fe ff ff       	jmp    f0100827 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100931:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100934:	5b                   	pop    %ebx
f0100935:	5e                   	pop    %esi
f0100936:	5f                   	pop    %edi
f0100937:	5d                   	pop    %ebp
f0100938:	c3                   	ret    

f0100939 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100939:	55                   	push   %ebp
f010093a:	89 e5                	mov    %esp,%ebp
f010093c:	56                   	push   %esi
f010093d:	53                   	push   %ebx
f010093e:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100940:	83 ec 0c             	sub    $0xc,%esp
f0100943:	50                   	push   %eax
f0100944:	e8 71 25 00 00       	call   f0102eba <mc146818_read>
f0100949:	89 c6                	mov    %eax,%esi
f010094b:	83 c3 01             	add    $0x1,%ebx
f010094e:	89 1c 24             	mov    %ebx,(%esp)
f0100951:	e8 64 25 00 00       	call   f0102eba <mc146818_read>
f0100956:	c1 e0 08             	shl    $0x8,%eax
f0100959:	09 f0                	or     %esi,%eax
}
f010095b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010095e:	5b                   	pop    %ebx
f010095f:	5e                   	pop    %esi
f0100960:	5d                   	pop    %ebp
f0100961:	c3                   	ret    

f0100962 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100962:	89 d1                	mov    %edx,%ecx
f0100964:	c1 e9 16             	shr    $0x16,%ecx
f0100967:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010096a:	a8 01                	test   $0x1,%al
f010096c:	74 52                	je     f01009c0 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010096e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100973:	89 c1                	mov    %eax,%ecx
f0100975:	c1 e9 0c             	shr    $0xc,%ecx
f0100978:	3b 0d 44 0c 17 f0    	cmp    0xf0170c44,%ecx
f010097e:	72 1b                	jb     f010099b <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100980:	55                   	push   %ebp
f0100981:	89 e5                	mov    %esp,%ebp
f0100983:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100986:	50                   	push   %eax
f0100987:	68 24 4b 10 f0       	push   $0xf0104b24
f010098c:	68 3e 03 00 00       	push   $0x33e
f0100991:	68 cd 52 10 f0       	push   $0xf01052cd
f0100996:	e8 05 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010099b:	c1 ea 0c             	shr    $0xc,%edx
f010099e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009a4:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009ab:	89 c2                	mov    %eax,%edx
f01009ad:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009b0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009b5:	85 d2                	test   %edx,%edx
f01009b7:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009bc:	0f 44 c2             	cmove  %edx,%eax
f01009bf:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009c5:	c3                   	ret    

f01009c6 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009c6:	55                   	push   %ebp
f01009c7:	89 e5                	mov    %esp,%ebp
f01009c9:	83 ec 08             	sub    $0x8,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009cc:	83 3d 78 ff 16 f0 00 	cmpl   $0x0,0xf016ff78
f01009d3:	75 11                	jne    f01009e6 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009d5:	ba 4f 1c 17 f0       	mov    $0xf0171c4f,%edx
f01009da:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009e0:	89 15 78 ff 16 f0    	mov    %edx,0xf016ff78
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here
	
	if(n!=0)
f01009e6:	85 c0                	test   %eax,%eax
f01009e8:	74 55                	je     f0100a3f <boot_alloc+0x79>
	{
		result = nextfree;
f01009ea:	8b 0d 78 ff 16 f0    	mov    0xf016ff78,%ecx
		nextfree = ROUNDUP((nextfree + n),PGSIZE);
f01009f0:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f01009f7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009fd:	89 15 78 ff 16 f0    	mov    %edx,0xf016ff78
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100a03:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100a09:	77 12                	ja     f0100a1d <boot_alloc+0x57>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100a0b:	52                   	push   %edx
f0100a0c:	68 48 4b 10 f0       	push   $0xf0104b48
f0100a11:	6a 70                	push   $0x70
f0100a13:	68 cd 52 10 f0       	push   $0xf01052cd
f0100a18:	e8 83 f6 ff ff       	call   f01000a0 <_panic>
	
		if (PADDR(nextfree)>=(PTSIZE))
f0100a1d:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100a23:	81 fa ff ff 3f 00    	cmp    $0x3fffff,%edx
f0100a29:	76 1b                	jbe    f0100a46 <boot_alloc+0x80>
			panic("Out of memeroy!!!");		
f0100a2b:	83 ec 04             	sub    $0x4,%esp
f0100a2e:	68 d9 52 10 f0       	push   $0xf01052d9
f0100a33:	6a 71                	push   $0x71
f0100a35:	68 cd 52 10 f0       	push   $0xf01052cd
f0100a3a:	e8 61 f6 ff ff       	call   f01000a0 <_panic>
	
		return result;
	}
	else
	{
		return nextfree;
f0100a3f:	a1 78 ff 16 f0       	mov    0xf016ff78,%eax
f0100a44:	eb 02                	jmp    f0100a48 <boot_alloc+0x82>
		nextfree = ROUNDUP((nextfree + n),PGSIZE);
	
		if (PADDR(nextfree)>=(PTSIZE))
			panic("Out of memeroy!!!");		
	
		return result;
f0100a46:	89 c8                	mov    %ecx,%eax
	}
	
	cprintf("boot alloc nextfree: %x",result);	
return NULL;	
	
}
f0100a48:	c9                   	leave  
f0100a49:	c3                   	ret    

f0100a4a <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a4a:	55                   	push   %ebp
f0100a4b:	89 e5                	mov    %esp,%ebp
f0100a4d:	57                   	push   %edi
f0100a4e:	56                   	push   %esi
f0100a4f:	53                   	push   %ebx
f0100a50:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a53:	84 c0                	test   %al,%al
f0100a55:	0f 85 81 02 00 00    	jne    f0100cdc <check_page_free_list+0x292>
f0100a5b:	e9 8e 02 00 00       	jmp    f0100cee <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a60:	83 ec 04             	sub    $0x4,%esp
f0100a63:	68 6c 4b 10 f0       	push   $0xf0104b6c
f0100a68:	68 78 02 00 00       	push   $0x278
f0100a6d:	68 cd 52 10 f0       	push   $0xf01052cd
f0100a72:	e8 29 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a77:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a7a:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a7d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a80:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a83:	89 c2                	mov    %eax,%edx
f0100a85:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0100a8b:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a91:	0f 95 c2             	setne  %dl
f0100a94:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a97:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a9b:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a9d:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aa1:	8b 00                	mov    (%eax),%eax
f0100aa3:	85 c0                	test   %eax,%eax
f0100aa5:	75 dc                	jne    f0100a83 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100aa7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100aaa:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ab0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ab3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ab6:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ab8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100abb:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ac0:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ac5:	8b 1d 7c ff 16 f0    	mov    0xf016ff7c,%ebx
f0100acb:	eb 53                	jmp    f0100b20 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100acd:	89 d8                	mov    %ebx,%eax
f0100acf:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0100ad5:	c1 f8 03             	sar    $0x3,%eax
f0100ad8:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100adb:	89 c2                	mov    %eax,%edx
f0100add:	c1 ea 16             	shr    $0x16,%edx
f0100ae0:	39 f2                	cmp    %esi,%edx
f0100ae2:	73 3a                	jae    f0100b1e <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ae4:	89 c2                	mov    %eax,%edx
f0100ae6:	c1 ea 0c             	shr    $0xc,%edx
f0100ae9:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0100aef:	72 12                	jb     f0100b03 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100af1:	50                   	push   %eax
f0100af2:	68 24 4b 10 f0       	push   $0xf0104b24
f0100af7:	6a 56                	push   $0x56
f0100af9:	68 eb 52 10 f0       	push   $0xf01052eb
f0100afe:	e8 9d f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b03:	83 ec 04             	sub    $0x4,%esp
f0100b06:	68 80 00 00 00       	push   $0x80
f0100b0b:	68 97 00 00 00       	push   $0x97
f0100b10:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b15:	50                   	push   %eax
f0100b16:	e8 4e 36 00 00       	call   f0104169 <memset>
f0100b1b:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b1e:	8b 1b                	mov    (%ebx),%ebx
f0100b20:	85 db                	test   %ebx,%ebx
f0100b22:	75 a9                	jne    f0100acd <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b24:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b29:	e8 98 fe ff ff       	call   f01009c6 <boot_alloc>
f0100b2e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b31:	8b 15 7c ff 16 f0    	mov    0xf016ff7c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b37:	8b 0d 4c 0c 17 f0    	mov    0xf0170c4c,%ecx
		assert(pp < pages + npages);
f0100b3d:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f0100b42:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b45:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b48:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b4b:	be 00 00 00 00       	mov    $0x0,%esi
f0100b50:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b53:	e9 30 01 00 00       	jmp    f0100c88 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b58:	39 ca                	cmp    %ecx,%edx
f0100b5a:	73 19                	jae    f0100b75 <check_page_free_list+0x12b>
f0100b5c:	68 f9 52 10 f0       	push   $0xf01052f9
f0100b61:	68 05 53 10 f0       	push   $0xf0105305
f0100b66:	68 92 02 00 00       	push   $0x292
f0100b6b:	68 cd 52 10 f0       	push   $0xf01052cd
f0100b70:	e8 2b f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b75:	39 fa                	cmp    %edi,%edx
f0100b77:	72 19                	jb     f0100b92 <check_page_free_list+0x148>
f0100b79:	68 1a 53 10 f0       	push   $0xf010531a
f0100b7e:	68 05 53 10 f0       	push   $0xf0105305
f0100b83:	68 93 02 00 00       	push   $0x293
f0100b88:	68 cd 52 10 f0       	push   $0xf01052cd
f0100b8d:	e8 0e f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b92:	89 d0                	mov    %edx,%eax
f0100b94:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b97:	a8 07                	test   $0x7,%al
f0100b99:	74 19                	je     f0100bb4 <check_page_free_list+0x16a>
f0100b9b:	68 90 4b 10 f0       	push   $0xf0104b90
f0100ba0:	68 05 53 10 f0       	push   $0xf0105305
f0100ba5:	68 94 02 00 00       	push   $0x294
f0100baa:	68 cd 52 10 f0       	push   $0xf01052cd
f0100baf:	e8 ec f4 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bb4:	c1 f8 03             	sar    $0x3,%eax
f0100bb7:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100bba:	85 c0                	test   %eax,%eax
f0100bbc:	75 19                	jne    f0100bd7 <check_page_free_list+0x18d>
f0100bbe:	68 2e 53 10 f0       	push   $0xf010532e
f0100bc3:	68 05 53 10 f0       	push   $0xf0105305
f0100bc8:	68 97 02 00 00       	push   $0x297
f0100bcd:	68 cd 52 10 f0       	push   $0xf01052cd
f0100bd2:	e8 c9 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bd7:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bdc:	75 19                	jne    f0100bf7 <check_page_free_list+0x1ad>
f0100bde:	68 3f 53 10 f0       	push   $0xf010533f
f0100be3:	68 05 53 10 f0       	push   $0xf0105305
f0100be8:	68 98 02 00 00       	push   $0x298
f0100bed:	68 cd 52 10 f0       	push   $0xf01052cd
f0100bf2:	e8 a9 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bf7:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bfc:	75 19                	jne    f0100c17 <check_page_free_list+0x1cd>
f0100bfe:	68 c4 4b 10 f0       	push   $0xf0104bc4
f0100c03:	68 05 53 10 f0       	push   $0xf0105305
f0100c08:	68 99 02 00 00       	push   $0x299
f0100c0d:	68 cd 52 10 f0       	push   $0xf01052cd
f0100c12:	e8 89 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c17:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c1c:	75 19                	jne    f0100c37 <check_page_free_list+0x1ed>
f0100c1e:	68 58 53 10 f0       	push   $0xf0105358
f0100c23:	68 05 53 10 f0       	push   $0xf0105305
f0100c28:	68 9a 02 00 00       	push   $0x29a
f0100c2d:	68 cd 52 10 f0       	push   $0xf01052cd
f0100c32:	e8 69 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c37:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c3c:	76 3f                	jbe    f0100c7d <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c3e:	89 c3                	mov    %eax,%ebx
f0100c40:	c1 eb 0c             	shr    $0xc,%ebx
f0100c43:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c46:	77 12                	ja     f0100c5a <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c48:	50                   	push   %eax
f0100c49:	68 24 4b 10 f0       	push   $0xf0104b24
f0100c4e:	6a 56                	push   $0x56
f0100c50:	68 eb 52 10 f0       	push   $0xf01052eb
f0100c55:	e8 46 f4 ff ff       	call   f01000a0 <_panic>
f0100c5a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c5f:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c62:	76 1e                	jbe    f0100c82 <check_page_free_list+0x238>
f0100c64:	68 e8 4b 10 f0       	push   $0xf0104be8
f0100c69:	68 05 53 10 f0       	push   $0xf0105305
f0100c6e:	68 9b 02 00 00       	push   $0x29b
f0100c73:	68 cd 52 10 f0       	push   $0xf01052cd
f0100c78:	e8 23 f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c7d:	83 c6 01             	add    $0x1,%esi
f0100c80:	eb 04                	jmp    f0100c86 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c82:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c86:	8b 12                	mov    (%edx),%edx
f0100c88:	85 d2                	test   %edx,%edx
f0100c8a:	0f 85 c8 fe ff ff    	jne    f0100b58 <check_page_free_list+0x10e>
f0100c90:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c93:	85 f6                	test   %esi,%esi
f0100c95:	7f 19                	jg     f0100cb0 <check_page_free_list+0x266>
f0100c97:	68 72 53 10 f0       	push   $0xf0105372
f0100c9c:	68 05 53 10 f0       	push   $0xf0105305
f0100ca1:	68 a3 02 00 00       	push   $0x2a3
f0100ca6:	68 cd 52 10 f0       	push   $0xf01052cd
f0100cab:	e8 f0 f3 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100cb0:	85 db                	test   %ebx,%ebx
f0100cb2:	7f 19                	jg     f0100ccd <check_page_free_list+0x283>
f0100cb4:	68 84 53 10 f0       	push   $0xf0105384
f0100cb9:	68 05 53 10 f0       	push   $0xf0105305
f0100cbe:	68 a4 02 00 00       	push   $0x2a4
f0100cc3:	68 cd 52 10 f0       	push   $0xf01052cd
f0100cc8:	e8 d3 f3 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100ccd:	83 ec 0c             	sub    $0xc,%esp
f0100cd0:	68 30 4c 10 f0       	push   $0xf0104c30
f0100cd5:	e8 47 22 00 00       	call   f0102f21 <cprintf>
}
f0100cda:	eb 29                	jmp    f0100d05 <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cdc:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f0100ce1:	85 c0                	test   %eax,%eax
f0100ce3:	0f 85 8e fd ff ff    	jne    f0100a77 <check_page_free_list+0x2d>
f0100ce9:	e9 72 fd ff ff       	jmp    f0100a60 <check_page_free_list+0x16>
f0100cee:	83 3d 7c ff 16 f0 00 	cmpl   $0x0,0xf016ff7c
f0100cf5:	0f 84 65 fd ff ff    	je     f0100a60 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cfb:	be 00 04 00 00       	mov    $0x400,%esi
f0100d00:	e9 c0 fd ff ff       	jmp    f0100ac5 <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100d05:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d08:	5b                   	pop    %ebx
f0100d09:	5e                   	pop    %esi
f0100d0a:	5f                   	pop    %edi
f0100d0b:	5d                   	pop    %ebp
f0100d0c:	c3                   	ret    

f0100d0d <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d0d:	55                   	push   %ebp
f0100d0e:	89 e5                	mov    %esp,%ebp
f0100d10:	56                   	push   %esi
f0100d11:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = npages - 1; i >= 1; i--) {
f0100d12:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f0100d17:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100d1a:	8d 34 c5 f8 ff ff ff 	lea    -0x8(,%eax,8),%esi
f0100d21:	eb 6e                	jmp    f0100d91 <page_init+0x84>
		if((i>= PGNUM(IOPHYSMEM)) && (i<PGNUM(EXTPHYSMEM)))
f0100d23:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100d29:	83 f8 5f             	cmp    $0x5f,%eax
f0100d2c:	76 5d                	jbe    f0100d8b <page_init+0x7e>
		{
			continue;
		}
		if (i>=PGNUM(EXTPHYSMEM) && (i<PGNUM(PADDR(boot_alloc(0)))))
f0100d2e:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100d34:	76 32                	jbe    f0100d68 <page_init+0x5b>
f0100d36:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d3b:	e8 86 fc ff ff       	call   f01009c6 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d40:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d45:	77 15                	ja     f0100d5c <page_init+0x4f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d47:	50                   	push   %eax
f0100d48:	68 48 4b 10 f0       	push   $0xf0104b48
f0100d4d:	68 41 01 00 00       	push   $0x141
f0100d52:	68 cd 52 10 f0       	push   $0xf01052cd
f0100d57:	e8 44 f3 ff ff       	call   f01000a0 <_panic>
f0100d5c:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d61:	c1 e8 0c             	shr    $0xc,%eax
f0100d64:	39 c3                	cmp    %eax,%ebx
f0100d66:	72 23                	jb     f0100d8b <page_init+0x7e>
		{
			continue;	
		}
		pages[i].pp_ref = 0;
f0100d68:	89 f0                	mov    %esi,%eax
f0100d6a:	03 05 4c 0c 17 f0    	add    0xf0170c4c,%eax
f0100d70:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100d76:	8b 15 7c ff 16 f0    	mov    0xf016ff7c,%edx
f0100d7c:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100d7e:	89 f0                	mov    %esi,%eax
f0100d80:	03 05 4c 0c 17 f0    	add    0xf0170c4c,%eax
f0100d86:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = npages - 1; i >= 1; i--) {
f0100d8b:	83 eb 01             	sub    $0x1,%ebx
f0100d8e:	83 ee 08             	sub    $0x8,%esi
f0100d91:	85 db                	test   %ebx,%ebx
f0100d93:	75 8e                	jne    f0100d23 <page_init+0x16>
		}
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100d95:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d98:	5b                   	pop    %ebx
f0100d99:	5e                   	pop    %esi
f0100d9a:	5d                   	pop    %ebp
f0100d9b:	c3                   	ret    

f0100d9c <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d9c:	55                   	push   %ebp
f0100d9d:	89 e5                	mov    %esp,%ebp
f0100d9f:	53                   	push   %ebx
f0100da0:	83 ec 04             	sub    $0x4,%esp
	
	// Fill this function in
	if(!page_free_list)
f0100da3:	8b 1d 7c ff 16 f0    	mov    0xf016ff7c,%ebx
f0100da9:	85 db                	test   %ebx,%ebx
f0100dab:	74 58                	je     f0100e05 <page_alloc+0x69>
                return NULL;
	struct PageInfo *pa_page=page_free_list;
	page_free_list = pa_page->pp_link;
f0100dad:	8b 03                	mov    (%ebx),%eax
f0100daf:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c
	pa_page->pp_link=NULL;
f0100db4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100dba:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100dbe:	74 45                	je     f0100e05 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dc0:	89 d8                	mov    %ebx,%eax
f0100dc2:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0100dc8:	c1 f8 03             	sar    $0x3,%eax
f0100dcb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dce:	89 c2                	mov    %eax,%edx
f0100dd0:	c1 ea 0c             	shr    $0xc,%edx
f0100dd3:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0100dd9:	72 12                	jb     f0100ded <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ddb:	50                   	push   %eax
f0100ddc:	68 24 4b 10 f0       	push   $0xf0104b24
f0100de1:	6a 56                	push   $0x56
f0100de3:	68 eb 52 10 f0       	push   $0xf01052eb
f0100de8:	e8 b3 f2 ff ff       	call   f01000a0 <_panic>
	{
		memset(page2kva(pa_page),'\0',PGSIZE);
f0100ded:	83 ec 04             	sub    $0x4,%esp
f0100df0:	68 00 10 00 00       	push   $0x1000
f0100df5:	6a 00                	push   $0x0
f0100df7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dfc:	50                   	push   %eax
f0100dfd:	e8 67 33 00 00       	call   f0104169 <memset>
f0100e02:	83 c4 10             	add    $0x10,%esp
	}
	return pa_page;
}
f0100e05:	89 d8                	mov    %ebx,%eax
f0100e07:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e0a:	c9                   	leave  
f0100e0b:	c3                   	ret    

f0100e0c <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e0c:	55                   	push   %ebp
f0100e0d:	89 e5                	mov    %esp,%ebp
f0100e0f:	83 ec 08             	sub    $0x8,%esp
f0100e12:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_link!=NULL || pp->pp_ref!=0)
f0100e15:	83 38 00             	cmpl   $0x0,(%eax)
f0100e18:	75 07                	jne    f0100e21 <page_free+0x15>
f0100e1a:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e1f:	74 17                	je     f0100e38 <page_free+0x2c>
	panic("Panic...chudak....");
f0100e21:	83 ec 04             	sub    $0x4,%esp
f0100e24:	68 95 53 10 f0       	push   $0xf0105395
f0100e29:	68 73 01 00 00       	push   $0x173
f0100e2e:	68 cd 52 10 f0       	push   $0xf01052cd
f0100e33:	e8 68 f2 ff ff       	call   f01000a0 <_panic>
	pp->pp_link=page_free_list;
f0100e38:	8b 15 7c ff 16 f0    	mov    0xf016ff7c,%edx
f0100e3e:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f0100e40:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c
}
f0100e45:	c9                   	leave  
f0100e46:	c3                   	ret    

f0100e47 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e47:	55                   	push   %ebp
f0100e48:	89 e5                	mov    %esp,%ebp
f0100e4a:	83 ec 08             	sub    $0x8,%esp
f0100e4d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e50:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e54:	83 e8 01             	sub    $0x1,%eax
f0100e57:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e5b:	66 85 c0             	test   %ax,%ax
f0100e5e:	75 0c                	jne    f0100e6c <page_decref+0x25>
		page_free(pp);
f0100e60:	83 ec 0c             	sub    $0xc,%esp
f0100e63:	52                   	push   %edx
f0100e64:	e8 a3 ff ff ff       	call   f0100e0c <page_free>
f0100e69:	83 c4 10             	add    $0x10,%esp
}
f0100e6c:	c9                   	leave  
f0100e6d:	c3                   	ret    

f0100e6e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e6e:	55                   	push   %ebp
f0100e6f:	89 e5                	mov    %esp,%ebp
f0100e71:	56                   	push   %esi
f0100e72:	53                   	push   %ebx
f0100e73:	8b 75 0c             	mov    0xc(%ebp),%esi
	
	pde_t * pde=&pgdir[PDX(va)];
f0100e76:	89 f3                	mov    %esi,%ebx
f0100e78:	c1 eb 16             	shr    $0x16,%ebx
f0100e7b:	c1 e3 02             	shl    $0x2,%ebx
f0100e7e:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*pde & PTE_P)){
f0100e81:	f6 03 01             	testb  $0x1,(%ebx)
f0100e84:	75 2d                	jne    f0100eb3 <pgdir_walk+0x45>
		if(!create)
f0100e86:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e8a:	74 62                	je     f0100eee <pgdir_walk+0x80>
			return NULL;

		struct PageInfo *pp=page_alloc(ALLOC_ZERO);
f0100e8c:	83 ec 0c             	sub    $0xc,%esp
f0100e8f:	6a 01                	push   $0x1
f0100e91:	e8 06 ff ff ff       	call   f0100d9c <page_alloc>
		if(!pp)
f0100e96:	83 c4 10             	add    $0x10,%esp
f0100e99:	85 c0                	test   %eax,%eax
f0100e9b:	74 58                	je     f0100ef5 <pgdir_walk+0x87>
			return NULL;
		pp->pp_ref++;
f0100e9d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		*pde=page2pa(pp)|PTE_P|PTE_W|PTE_U;		
f0100ea2:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0100ea8:	c1 f8 03             	sar    $0x3,%eax
f0100eab:	c1 e0 0c             	shl    $0xc,%eax
f0100eae:	83 c8 07             	or     $0x7,%eax
f0100eb1:	89 03                	mov    %eax,(%ebx)
	}
	pte_t * pte=KADDR(PTE_ADDR(*pde));
f0100eb3:	8b 03                	mov    (%ebx),%eax
f0100eb5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eba:	89 c2                	mov    %eax,%edx
f0100ebc:	c1 ea 0c             	shr    $0xc,%edx
f0100ebf:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0100ec5:	72 15                	jb     f0100edc <pgdir_walk+0x6e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ec7:	50                   	push   %eax
f0100ec8:	68 24 4b 10 f0       	push   $0xf0104b24
f0100ecd:	68 a8 01 00 00       	push   $0x1a8
f0100ed2:	68 cd 52 10 f0       	push   $0xf01052cd
f0100ed7:	e8 c4 f1 ff ff       	call   f01000a0 <_panic>
	pte=&pte[PTX(va)];
f0100edc:	c1 ee 0a             	shr    $0xa,%esi
f0100edf:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
	return pte;
f0100ee5:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100eec:	eb 0c                	jmp    f0100efa <pgdir_walk+0x8c>
{
	
	pde_t * pde=&pgdir[PDX(va)];
	if(!(*pde & PTE_P)){
		if(!create)
			return NULL;
f0100eee:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ef3:	eb 05                	jmp    f0100efa <pgdir_walk+0x8c>

		struct PageInfo *pp=page_alloc(ALLOC_ZERO);
		if(!pp)
			return NULL;
f0100ef5:	b8 00 00 00 00       	mov    $0x0,%eax
		*pde=page2pa(pp)|PTE_P|PTE_W|PTE_U;		
	}
	pte_t * pte=KADDR(PTE_ADDR(*pde));
	pte=&pte[PTX(va)];
	return pte;
}
f0100efa:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100efd:	5b                   	pop    %ebx
f0100efe:	5e                   	pop    %esi
f0100eff:	5d                   	pop    %ebp
f0100f00:	c3                   	ret    

f0100f01 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f01:	55                   	push   %ebp
f0100f02:	89 e5                	mov    %esp,%ebp
f0100f04:	57                   	push   %edi
f0100f05:	56                   	push   %esi
f0100f06:	53                   	push   %ebx
f0100f07:	83 ec 1c             	sub    $0x1c,%esp
f0100f0a:	89 c7                	mov    %eax,%edi
f0100f0c:	89 d6                	mov    %edx,%esi
f0100f0e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	for(int i=0;i< size; i+=PGSIZE)
f0100f11:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		pte_t* pte=pgdir_walk(pgdir,(void*)(va+i),1);
		*pte=(pa+i)|perm|PTE_P;	
f0100f16:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f19:	83 c8 01             	or     $0x1,%eax
f0100f1c:	89 45 e0             	mov    %eax,-0x20(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for(int i=0;i< size; i+=PGSIZE)
f0100f1f:	eb 22                	jmp    f0100f43 <boot_map_region+0x42>
	{
		pte_t* pte=pgdir_walk(pgdir,(void*)(va+i),1);
f0100f21:	83 ec 04             	sub    $0x4,%esp
f0100f24:	6a 01                	push   $0x1
f0100f26:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f0100f29:	50                   	push   %eax
f0100f2a:	57                   	push   %edi
f0100f2b:	e8 3e ff ff ff       	call   f0100e6e <pgdir_walk>
		*pte=(pa+i)|perm|PTE_P;	
f0100f30:	89 da                	mov    %ebx,%edx
f0100f32:	03 55 08             	add    0x8(%ebp),%edx
f0100f35:	0b 55 e0             	or     -0x20(%ebp),%edx
f0100f38:	89 10                	mov    %edx,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for(int i=0;i< size; i+=PGSIZE)
f0100f3a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f40:	83 c4 10             	add    $0x10,%esp
f0100f43:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100f46:	77 d9                	ja     f0100f21 <boot_map_region+0x20>
	{
		pte_t* pte=pgdir_walk(pgdir,(void*)(va+i),1);
		*pte=(pa+i)|perm|PTE_P;	
	}
	
}
f0100f48:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f4b:	5b                   	pop    %ebx
f0100f4c:	5e                   	pop    %esi
f0100f4d:	5f                   	pop    %edi
f0100f4e:	5d                   	pop    %ebp
f0100f4f:	c3                   	ret    

f0100f50 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f50:	55                   	push   %ebp
f0100f51:	89 e5                	mov    %esp,%ebp
f0100f53:	83 ec 0c             	sub    $0xc,%esp
	// Fill this function in
	pte_t *pte=pgdir_walk(pgdir,va,0);
f0100f56:	6a 00                	push   $0x0
f0100f58:	ff 75 0c             	pushl  0xc(%ebp)
f0100f5b:	ff 75 08             	pushl  0x8(%ebp)
f0100f5e:	e8 0b ff ff ff       	call   f0100e6e <pgdir_walk>
	if(!(pte) || !(*pte & PTE_P))
f0100f63:	83 c4 10             	add    $0x10,%esp
f0100f66:	85 c0                	test   %eax,%eax
f0100f68:	74 30                	je     f0100f9a <page_lookup+0x4a>
f0100f6a:	8b 00                	mov    (%eax),%eax
f0100f6c:	a8 01                	test   $0x1,%al
f0100f6e:	74 31                	je     f0100fa1 <page_lookup+0x51>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f70:	c1 e8 0c             	shr    $0xc,%eax
f0100f73:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0100f79:	72 14                	jb     f0100f8f <page_lookup+0x3f>
		panic("pa2page called with invalid pa");
f0100f7b:	83 ec 04             	sub    $0x4,%esp
f0100f7e:	68 54 4c 10 f0       	push   $0xf0104c54
f0100f83:	6a 4f                	push   $0x4f
f0100f85:	68 eb 52 10 f0       	push   $0xf01052eb
f0100f8a:	e8 11 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f8f:	8b 15 4c 0c 17 f0    	mov    0xf0170c4c,%edx
f0100f95:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	if(pte_store)
	{
		pte_store=&pte;
		
	}
	return pa2page(PTE_ADDR(*pte));
f0100f98:	eb 0c                	jmp    f0100fa6 <page_lookup+0x56>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
	pte_t *pte=pgdir_walk(pgdir,va,0);
	if(!(pte) || !(*pte & PTE_P))
		return NULL;
f0100f9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f9f:	eb 05                	jmp    f0100fa6 <page_lookup+0x56>
f0100fa1:	b8 00 00 00 00       	mov    $0x0,%eax
	{
		pte_store=&pte;
		
	}
	return pa2page(PTE_ADDR(*pte));
}
f0100fa6:	c9                   	leave  
f0100fa7:	c3                   	ret    

f0100fa8 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fa8:	55                   	push   %ebp
f0100fa9:	89 e5                	mov    %esp,%ebp
f0100fab:	56                   	push   %esi
f0100fac:	53                   	push   %ebx
f0100fad:	83 ec 14             	sub    $0x14,%esp
f0100fb0:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fb3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t * pte=pgdir_walk(pgdir,va,0);
f0100fb6:	6a 00                	push   $0x0
f0100fb8:	53                   	push   %ebx
f0100fb9:	56                   	push   %esi
f0100fba:	e8 af fe ff ff       	call   f0100e6e <pgdir_walk>
f0100fbf:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if((*pte & PTE_P))
f0100fc2:	83 c4 10             	add    $0x10,%esp
f0100fc5:	f6 00 01             	testb  $0x1,(%eax)
f0100fc8:	74 25                	je     f0100fef <page_remove+0x47>
	{
		
		page_decref(page_lookup(pgdir,va,&pte));
f0100fca:	83 ec 04             	sub    $0x4,%esp
f0100fcd:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fd0:	50                   	push   %eax
f0100fd1:	53                   	push   %ebx
f0100fd2:	56                   	push   %esi
f0100fd3:	e8 78 ff ff ff       	call   f0100f50 <page_lookup>
f0100fd8:	89 04 24             	mov    %eax,(%esp)
f0100fdb:	e8 67 fe ff ff       	call   f0100e47 <page_decref>
		*pte=0;
f0100fe0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fe3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fe9:	0f 01 3b             	invlpg (%ebx)
f0100fec:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir,va);
	}
		
	
}
f0100fef:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ff2:	5b                   	pop    %ebx
f0100ff3:	5e                   	pop    %esi
f0100ff4:	5d                   	pop    %ebp
f0100ff5:	c3                   	ret    

f0100ff6 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100ff6:	55                   	push   %ebp
f0100ff7:	89 e5                	mov    %esp,%ebp
f0100ff9:	57                   	push   %edi
f0100ffa:	56                   	push   %esi
f0100ffb:	53                   	push   %ebx
f0100ffc:	83 ec 10             	sub    $0x10,%esp
f0100fff:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101002:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t * pte=pgdir_walk(pgdir,va,1);	
f0101005:	6a 01                	push   $0x1
f0101007:	57                   	push   %edi
f0101008:	ff 75 08             	pushl  0x8(%ebp)
f010100b:	e8 5e fe ff ff       	call   f0100e6e <pgdir_walk>
	
	if(!pte)
f0101010:	83 c4 10             	add    $0x10,%esp
f0101013:	85 c0                	test   %eax,%eax
f0101015:	74 5c                	je     f0101073 <page_insert+0x7d>
f0101017:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f0101019:	0f b7 4b 04          	movzwl 0x4(%ebx),%ecx
f010101d:	8d 41 01             	lea    0x1(%ecx),%eax
f0101020:	66 89 43 04          	mov    %ax,0x4(%ebx)

	if((*pte & PTE_P))
f0101024:	8b 06                	mov    (%esi),%eax
f0101026:	a8 01                	test   $0x1,%al
f0101028:	74 2c                	je     f0101056 <page_insert+0x60>
	{
		if(page2pa(pp)!=PTE_ADDR(*pte))
f010102a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010102f:	89 da                	mov    %ebx,%edx
f0101031:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101037:	c1 fa 03             	sar    $0x3,%edx
f010103a:	c1 e2 0c             	shl    $0xc,%edx
f010103d:	39 d0                	cmp    %edx,%eax
f010103f:	74 11                	je     f0101052 <page_insert+0x5c>
		{
		page_remove(pgdir,va);
f0101041:	83 ec 08             	sub    $0x8,%esp
f0101044:	57                   	push   %edi
f0101045:	ff 75 08             	pushl  0x8(%ebp)
f0101048:	e8 5b ff ff ff       	call   f0100fa8 <page_remove>
f010104d:	83 c4 10             	add    $0x10,%esp
f0101050:	eb 04                	jmp    f0101056 <page_insert+0x60>
		}else
		{
			pp->pp_ref--;
f0101052:	66 89 4b 04          	mov    %cx,0x4(%ebx)
		}
	}
	*pte=page2pa(pp)|perm|PTE_P;
f0101056:	2b 1d 4c 0c 17 f0    	sub    0xf0170c4c,%ebx
f010105c:	c1 fb 03             	sar    $0x3,%ebx
f010105f:	c1 e3 0c             	shl    $0xc,%ebx
f0101062:	8b 45 14             	mov    0x14(%ebp),%eax
f0101065:	83 c8 01             	or     $0x1,%eax
f0101068:	09 c3                	or     %eax,%ebx
f010106a:	89 1e                	mov    %ebx,(%esi)
	return 0;
f010106c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101071:	eb 05                	jmp    f0101078 <page_insert+0x82>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t * pte=pgdir_walk(pgdir,va,1);	
	
	if(!pte)
		return -E_NO_MEM;
f0101073:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
			pp->pp_ref--;
		}
	}
	*pte=page2pa(pp)|perm|PTE_P;
	return 0;
}
f0101078:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010107b:	5b                   	pop    %ebx
f010107c:	5e                   	pop    %esi
f010107d:	5f                   	pop    %edi
f010107e:	5d                   	pop    %ebp
f010107f:	c3                   	ret    

f0101080 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101080:	55                   	push   %ebp
f0101081:	89 e5                	mov    %esp,%ebp
f0101083:	57                   	push   %edi
f0101084:	56                   	push   %esi
f0101085:	53                   	push   %ebx
f0101086:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101089:	b8 15 00 00 00       	mov    $0x15,%eax
f010108e:	e8 a6 f8 ff ff       	call   f0100939 <nvram_read>
f0101093:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101095:	b8 17 00 00 00       	mov    $0x17,%eax
f010109a:	e8 9a f8 ff ff       	call   f0100939 <nvram_read>
f010109f:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010a1:	b8 34 00 00 00       	mov    $0x34,%eax
f01010a6:	e8 8e f8 ff ff       	call   f0100939 <nvram_read>
f01010ab:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01010ae:	85 c0                	test   %eax,%eax
f01010b0:	74 07                	je     f01010b9 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01010b2:	05 00 40 00 00       	add    $0x4000,%eax
f01010b7:	eb 0b                	jmp    f01010c4 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01010b9:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01010bf:	85 f6                	test   %esi,%esi
f01010c1:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01010c4:	89 c2                	mov    %eax,%edx
f01010c6:	c1 ea 02             	shr    $0x2,%edx
f01010c9:	89 15 44 0c 17 f0    	mov    %edx,0xf0170c44
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010cf:	89 c2                	mov    %eax,%edx
f01010d1:	29 da                	sub    %ebx,%edx
f01010d3:	52                   	push   %edx
f01010d4:	53                   	push   %ebx
f01010d5:	50                   	push   %eax
f01010d6:	68 74 4c 10 f0       	push   $0xf0104c74
f01010db:	e8 41 1e 00 00       	call   f0102f21 <cprintf>
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010e0:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010e5:	e8 dc f8 ff ff       	call   f01009c6 <boot_alloc>
f01010ea:	a3 48 0c 17 f0       	mov    %eax,0xf0170c48
	memset(kern_pgdir, 0, PGSIZE);
f01010ef:	83 c4 0c             	add    $0xc,%esp
f01010f2:	68 00 10 00 00       	push   $0x1000
f01010f7:	6a 00                	push   $0x0
f01010f9:	50                   	push   %eax
f01010fa:	e8 6a 30 00 00       	call   f0104169 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010ff:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101104:	83 c4 10             	add    $0x10,%esp
f0101107:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010110c:	77 15                	ja     f0101123 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010110e:	50                   	push   %eax
f010110f:	68 48 4b 10 f0       	push   $0xf0104b48
f0101114:	68 a3 00 00 00       	push   $0xa3
f0101119:	68 cd 52 10 f0       	push   $0xf01052cd
f010111e:	e8 7d ef ff ff       	call   f01000a0 <_panic>
f0101123:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101129:	83 ca 05             	or     $0x5,%edx
f010112c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	//Your code goes here:

	pages=(struct PageInfo*)(boot_alloc(npages * sizeof(struct PageInfo)));
f0101132:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f0101137:	c1 e0 03             	shl    $0x3,%eax
f010113a:	e8 87 f8 ff ff       	call   f01009c6 <boot_alloc>
f010113f:	a3 4c 0c 17 f0       	mov    %eax,0xf0170c4c
	
	for(int i=0;i<npages;i++)
f0101144:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101149:	eb 1b                	jmp    f0101166 <mem_init+0xe6>
	{
		memset(&pages[i],0,sizeof(struct PageInfo));
f010114b:	83 ec 04             	sub    $0x4,%esp
f010114e:	6a 08                	push   $0x8
f0101150:	6a 00                	push   $0x0
f0101152:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
f0101157:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f010115a:	50                   	push   %eax
f010115b:	e8 09 30 00 00       	call   f0104169 <memset>
	// to initialize all fields of each struct PageInfo to 0.
	//Your code goes here:

	pages=(struct PageInfo*)(boot_alloc(npages * sizeof(struct PageInfo)));
	
	for(int i=0;i<npages;i++)
f0101160:	83 c3 01             	add    $0x1,%ebx
f0101163:	83 c4 10             	add    $0x10,%esp
f0101166:	3b 1d 44 0c 17 f0    	cmp    0xf0170c44,%ebx
f010116c:	72 dd                	jb     f010114b <mem_init+0xcb>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs=(struct Env*)(boot_alloc(NENV * sizeof(struct Env)));
f010116e:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101173:	e8 4e f8 ff ff       	call   f01009c6 <boot_alloc>
f0101178:	a3 84 ff 16 f0       	mov    %eax,0xf016ff84
f010117d:	bb 00 00 00 00       	mov    $0x0,%ebx
	for(int i=0; i<NENV;i++)
	{
		memset(&envs[i],0,sizeof(struct Env));
f0101182:	83 ec 04             	sub    $0x4,%esp
f0101185:	6a 60                	push   $0x60
f0101187:	6a 00                	push   $0x0
f0101189:	89 d8                	mov    %ebx,%eax
f010118b:	03 05 84 ff 16 f0    	add    0xf016ff84,%eax
f0101191:	50                   	push   %eax
f0101192:	e8 d2 2f 00 00       	call   f0104169 <memset>
f0101197:	83 c3 60             	add    $0x60,%ebx
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs=(struct Env*)(boot_alloc(NENV * sizeof(struct Env)));
	for(int i=0; i<NENV;i++)
f010119a:	83 c4 10             	add    $0x10,%esp
f010119d:	81 fb 00 80 01 00    	cmp    $0x18000,%ebx
f01011a3:	75 dd                	jne    f0101182 <mem_init+0x102>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01011a5:	e8 63 fb ff ff       	call   f0100d0d <page_init>

	check_page_free_list(1);
f01011aa:	b8 01 00 00 00       	mov    $0x1,%eax
f01011af:	e8 96 f8 ff ff       	call   f0100a4a <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011b4:	83 3d 4c 0c 17 f0 00 	cmpl   $0x0,0xf0170c4c
f01011bb:	75 17                	jne    f01011d4 <mem_init+0x154>
		panic("'pages' is a null pointer!");
f01011bd:	83 ec 04             	sub    $0x4,%esp
f01011c0:	68 a8 53 10 f0       	push   $0xf01053a8
f01011c5:	68 b7 02 00 00       	push   $0x2b7
f01011ca:	68 cd 52 10 f0       	push   $0xf01052cd
f01011cf:	e8 cc ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011d4:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f01011d9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011de:	eb 05                	jmp    f01011e5 <mem_init+0x165>
		++nfree;
f01011e0:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011e3:	8b 00                	mov    (%eax),%eax
f01011e5:	85 c0                	test   %eax,%eax
f01011e7:	75 f7                	jne    f01011e0 <mem_init+0x160>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
//	cprintf("pagealloc(0):%p\n",page_alloc(0));
	assert((pp0 = page_alloc(0)));
f01011e9:	83 ec 0c             	sub    $0xc,%esp
f01011ec:	6a 00                	push   $0x0
f01011ee:	e8 a9 fb ff ff       	call   f0100d9c <page_alloc>
f01011f3:	89 c7                	mov    %eax,%edi
f01011f5:	83 c4 10             	add    $0x10,%esp
f01011f8:	85 c0                	test   %eax,%eax
f01011fa:	75 19                	jne    f0101215 <mem_init+0x195>
f01011fc:	68 c3 53 10 f0       	push   $0xf01053c3
f0101201:	68 05 53 10 f0       	push   $0xf0105305
f0101206:	68 c0 02 00 00       	push   $0x2c0
f010120b:	68 cd 52 10 f0       	push   $0xf01052cd
f0101210:	e8 8b ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101215:	83 ec 0c             	sub    $0xc,%esp
f0101218:	6a 00                	push   $0x0
f010121a:	e8 7d fb ff ff       	call   f0100d9c <page_alloc>
f010121f:	89 c6                	mov    %eax,%esi
f0101221:	83 c4 10             	add    $0x10,%esp
f0101224:	85 c0                	test   %eax,%eax
f0101226:	75 19                	jne    f0101241 <mem_init+0x1c1>
f0101228:	68 d9 53 10 f0       	push   $0xf01053d9
f010122d:	68 05 53 10 f0       	push   $0xf0105305
f0101232:	68 c1 02 00 00       	push   $0x2c1
f0101237:	68 cd 52 10 f0       	push   $0xf01052cd
f010123c:	e8 5f ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101241:	83 ec 0c             	sub    $0xc,%esp
f0101244:	6a 00                	push   $0x0
f0101246:	e8 51 fb ff ff       	call   f0100d9c <page_alloc>
f010124b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010124e:	83 c4 10             	add    $0x10,%esp
f0101251:	85 c0                	test   %eax,%eax
f0101253:	75 19                	jne    f010126e <mem_init+0x1ee>
f0101255:	68 ef 53 10 f0       	push   $0xf01053ef
f010125a:	68 05 53 10 f0       	push   $0xf0105305
f010125f:	68 c2 02 00 00       	push   $0x2c2
f0101264:	68 cd 52 10 f0       	push   $0xf01052cd
f0101269:	e8 32 ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010126e:	39 f7                	cmp    %esi,%edi
f0101270:	75 19                	jne    f010128b <mem_init+0x20b>
f0101272:	68 05 54 10 f0       	push   $0xf0105405
f0101277:	68 05 53 10 f0       	push   $0xf0105305
f010127c:	68 c5 02 00 00       	push   $0x2c5
f0101281:	68 cd 52 10 f0       	push   $0xf01052cd
f0101286:	e8 15 ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010128b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010128e:	39 c6                	cmp    %eax,%esi
f0101290:	74 04                	je     f0101296 <mem_init+0x216>
f0101292:	39 c7                	cmp    %eax,%edi
f0101294:	75 19                	jne    f01012af <mem_init+0x22f>
f0101296:	68 b0 4c 10 f0       	push   $0xf0104cb0
f010129b:	68 05 53 10 f0       	push   $0xf0105305
f01012a0:	68 c6 02 00 00       	push   $0x2c6
f01012a5:	68 cd 52 10 f0       	push   $0xf01052cd
f01012aa:	e8 f1 ed ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012af:	8b 0d 4c 0c 17 f0    	mov    0xf0170c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012b5:	8b 15 44 0c 17 f0    	mov    0xf0170c44,%edx
f01012bb:	c1 e2 0c             	shl    $0xc,%edx
f01012be:	89 f8                	mov    %edi,%eax
f01012c0:	29 c8                	sub    %ecx,%eax
f01012c2:	c1 f8 03             	sar    $0x3,%eax
f01012c5:	c1 e0 0c             	shl    $0xc,%eax
f01012c8:	39 d0                	cmp    %edx,%eax
f01012ca:	72 19                	jb     f01012e5 <mem_init+0x265>
f01012cc:	68 17 54 10 f0       	push   $0xf0105417
f01012d1:	68 05 53 10 f0       	push   $0xf0105305
f01012d6:	68 c7 02 00 00       	push   $0x2c7
f01012db:	68 cd 52 10 f0       	push   $0xf01052cd
f01012e0:	e8 bb ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012e5:	89 f0                	mov    %esi,%eax
f01012e7:	29 c8                	sub    %ecx,%eax
f01012e9:	c1 f8 03             	sar    $0x3,%eax
f01012ec:	c1 e0 0c             	shl    $0xc,%eax
f01012ef:	39 c2                	cmp    %eax,%edx
f01012f1:	77 19                	ja     f010130c <mem_init+0x28c>
f01012f3:	68 34 54 10 f0       	push   $0xf0105434
f01012f8:	68 05 53 10 f0       	push   $0xf0105305
f01012fd:	68 c8 02 00 00       	push   $0x2c8
f0101302:	68 cd 52 10 f0       	push   $0xf01052cd
f0101307:	e8 94 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010130c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010130f:	29 c8                	sub    %ecx,%eax
f0101311:	c1 f8 03             	sar    $0x3,%eax
f0101314:	c1 e0 0c             	shl    $0xc,%eax
f0101317:	39 c2                	cmp    %eax,%edx
f0101319:	77 19                	ja     f0101334 <mem_init+0x2b4>
f010131b:	68 51 54 10 f0       	push   $0xf0105451
f0101320:	68 05 53 10 f0       	push   $0xf0105305
f0101325:	68 c9 02 00 00       	push   $0x2c9
f010132a:	68 cd 52 10 f0       	push   $0xf01052cd
f010132f:	e8 6c ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101334:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f0101339:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010133c:	c7 05 7c ff 16 f0 00 	movl   $0x0,0xf016ff7c
f0101343:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101346:	83 ec 0c             	sub    $0xc,%esp
f0101349:	6a 00                	push   $0x0
f010134b:	e8 4c fa ff ff       	call   f0100d9c <page_alloc>
f0101350:	83 c4 10             	add    $0x10,%esp
f0101353:	85 c0                	test   %eax,%eax
f0101355:	74 19                	je     f0101370 <mem_init+0x2f0>
f0101357:	68 6e 54 10 f0       	push   $0xf010546e
f010135c:	68 05 53 10 f0       	push   $0xf0105305
f0101361:	68 d0 02 00 00       	push   $0x2d0
f0101366:	68 cd 52 10 f0       	push   $0xf01052cd
f010136b:	e8 30 ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101370:	83 ec 0c             	sub    $0xc,%esp
f0101373:	57                   	push   %edi
f0101374:	e8 93 fa ff ff       	call   f0100e0c <page_free>
	page_free(pp1);
f0101379:	89 34 24             	mov    %esi,(%esp)
f010137c:	e8 8b fa ff ff       	call   f0100e0c <page_free>
	page_free(pp2);
f0101381:	83 c4 04             	add    $0x4,%esp
f0101384:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101387:	e8 80 fa ff ff       	call   f0100e0c <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010138c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101393:	e8 04 fa ff ff       	call   f0100d9c <page_alloc>
f0101398:	89 c6                	mov    %eax,%esi
f010139a:	83 c4 10             	add    $0x10,%esp
f010139d:	85 c0                	test   %eax,%eax
f010139f:	75 19                	jne    f01013ba <mem_init+0x33a>
f01013a1:	68 c3 53 10 f0       	push   $0xf01053c3
f01013a6:	68 05 53 10 f0       	push   $0xf0105305
f01013ab:	68 d7 02 00 00       	push   $0x2d7
f01013b0:	68 cd 52 10 f0       	push   $0xf01052cd
f01013b5:	e8 e6 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01013ba:	83 ec 0c             	sub    $0xc,%esp
f01013bd:	6a 00                	push   $0x0
f01013bf:	e8 d8 f9 ff ff       	call   f0100d9c <page_alloc>
f01013c4:	89 c7                	mov    %eax,%edi
f01013c6:	83 c4 10             	add    $0x10,%esp
f01013c9:	85 c0                	test   %eax,%eax
f01013cb:	75 19                	jne    f01013e6 <mem_init+0x366>
f01013cd:	68 d9 53 10 f0       	push   $0xf01053d9
f01013d2:	68 05 53 10 f0       	push   $0xf0105305
f01013d7:	68 d8 02 00 00       	push   $0x2d8
f01013dc:	68 cd 52 10 f0       	push   $0xf01052cd
f01013e1:	e8 ba ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01013e6:	83 ec 0c             	sub    $0xc,%esp
f01013e9:	6a 00                	push   $0x0
f01013eb:	e8 ac f9 ff ff       	call   f0100d9c <page_alloc>
f01013f0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013f3:	83 c4 10             	add    $0x10,%esp
f01013f6:	85 c0                	test   %eax,%eax
f01013f8:	75 19                	jne    f0101413 <mem_init+0x393>
f01013fa:	68 ef 53 10 f0       	push   $0xf01053ef
f01013ff:	68 05 53 10 f0       	push   $0xf0105305
f0101404:	68 d9 02 00 00       	push   $0x2d9
f0101409:	68 cd 52 10 f0       	push   $0xf01052cd
f010140e:	e8 8d ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101413:	39 fe                	cmp    %edi,%esi
f0101415:	75 19                	jne    f0101430 <mem_init+0x3b0>
f0101417:	68 05 54 10 f0       	push   $0xf0105405
f010141c:	68 05 53 10 f0       	push   $0xf0105305
f0101421:	68 db 02 00 00       	push   $0x2db
f0101426:	68 cd 52 10 f0       	push   $0xf01052cd
f010142b:	e8 70 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101430:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101433:	39 c7                	cmp    %eax,%edi
f0101435:	74 04                	je     f010143b <mem_init+0x3bb>
f0101437:	39 c6                	cmp    %eax,%esi
f0101439:	75 19                	jne    f0101454 <mem_init+0x3d4>
f010143b:	68 b0 4c 10 f0       	push   $0xf0104cb0
f0101440:	68 05 53 10 f0       	push   $0xf0105305
f0101445:	68 dc 02 00 00       	push   $0x2dc
f010144a:	68 cd 52 10 f0       	push   $0xf01052cd
f010144f:	e8 4c ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101454:	83 ec 0c             	sub    $0xc,%esp
f0101457:	6a 00                	push   $0x0
f0101459:	e8 3e f9 ff ff       	call   f0100d9c <page_alloc>
f010145e:	83 c4 10             	add    $0x10,%esp
f0101461:	85 c0                	test   %eax,%eax
f0101463:	74 19                	je     f010147e <mem_init+0x3fe>
f0101465:	68 6e 54 10 f0       	push   $0xf010546e
f010146a:	68 05 53 10 f0       	push   $0xf0105305
f010146f:	68 dd 02 00 00       	push   $0x2dd
f0101474:	68 cd 52 10 f0       	push   $0xf01052cd
f0101479:	e8 22 ec ff ff       	call   f01000a0 <_panic>
f010147e:	89 f0                	mov    %esi,%eax
f0101480:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101486:	c1 f8 03             	sar    $0x3,%eax
f0101489:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010148c:	89 c2                	mov    %eax,%edx
f010148e:	c1 ea 0c             	shr    $0xc,%edx
f0101491:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0101497:	72 12                	jb     f01014ab <mem_init+0x42b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101499:	50                   	push   %eax
f010149a:	68 24 4b 10 f0       	push   $0xf0104b24
f010149f:	6a 56                	push   $0x56
f01014a1:	68 eb 52 10 f0       	push   $0xf01052eb
f01014a6:	e8 f5 eb ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014ab:	83 ec 04             	sub    $0x4,%esp
f01014ae:	68 00 10 00 00       	push   $0x1000
f01014b3:	6a 01                	push   $0x1
f01014b5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014ba:	50                   	push   %eax
f01014bb:	e8 a9 2c 00 00       	call   f0104169 <memset>
	page_free(pp0);
f01014c0:	89 34 24             	mov    %esi,(%esp)
f01014c3:	e8 44 f9 ff ff       	call   f0100e0c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014c8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014cf:	e8 c8 f8 ff ff       	call   f0100d9c <page_alloc>
f01014d4:	83 c4 10             	add    $0x10,%esp
f01014d7:	85 c0                	test   %eax,%eax
f01014d9:	75 19                	jne    f01014f4 <mem_init+0x474>
f01014db:	68 7d 54 10 f0       	push   $0xf010547d
f01014e0:	68 05 53 10 f0       	push   $0xf0105305
f01014e5:	68 e2 02 00 00       	push   $0x2e2
f01014ea:	68 cd 52 10 f0       	push   $0xf01052cd
f01014ef:	e8 ac eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01014f4:	39 c6                	cmp    %eax,%esi
f01014f6:	74 19                	je     f0101511 <mem_init+0x491>
f01014f8:	68 9b 54 10 f0       	push   $0xf010549b
f01014fd:	68 05 53 10 f0       	push   $0xf0105305
f0101502:	68 e3 02 00 00       	push   $0x2e3
f0101507:	68 cd 52 10 f0       	push   $0xf01052cd
f010150c:	e8 8f eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101511:	89 f0                	mov    %esi,%eax
f0101513:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101519:	c1 f8 03             	sar    $0x3,%eax
f010151c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010151f:	89 c2                	mov    %eax,%edx
f0101521:	c1 ea 0c             	shr    $0xc,%edx
f0101524:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f010152a:	72 12                	jb     f010153e <mem_init+0x4be>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010152c:	50                   	push   %eax
f010152d:	68 24 4b 10 f0       	push   $0xf0104b24
f0101532:	6a 56                	push   $0x56
f0101534:	68 eb 52 10 f0       	push   $0xf01052eb
f0101539:	e8 62 eb ff ff       	call   f01000a0 <_panic>
f010153e:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101544:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010154a:	80 38 00             	cmpb   $0x0,(%eax)
f010154d:	74 19                	je     f0101568 <mem_init+0x4e8>
f010154f:	68 ab 54 10 f0       	push   $0xf01054ab
f0101554:	68 05 53 10 f0       	push   $0xf0105305
f0101559:	68 e6 02 00 00       	push   $0x2e6
f010155e:	68 cd 52 10 f0       	push   $0xf01052cd
f0101563:	e8 38 eb ff ff       	call   f01000a0 <_panic>
f0101568:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010156b:	39 d0                	cmp    %edx,%eax
f010156d:	75 db                	jne    f010154a <mem_init+0x4ca>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010156f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101572:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c

	// free the pages we took
	page_free(pp0);
f0101577:	83 ec 0c             	sub    $0xc,%esp
f010157a:	56                   	push   %esi
f010157b:	e8 8c f8 ff ff       	call   f0100e0c <page_free>
	page_free(pp1);
f0101580:	89 3c 24             	mov    %edi,(%esp)
f0101583:	e8 84 f8 ff ff       	call   f0100e0c <page_free>
	page_free(pp2);
f0101588:	83 c4 04             	add    $0x4,%esp
f010158b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010158e:	e8 79 f8 ff ff       	call   f0100e0c <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101593:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f0101598:	83 c4 10             	add    $0x10,%esp
f010159b:	eb 05                	jmp    f01015a2 <mem_init+0x522>
		--nfree;
f010159d:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015a0:	8b 00                	mov    (%eax),%eax
f01015a2:	85 c0                	test   %eax,%eax
f01015a4:	75 f7                	jne    f010159d <mem_init+0x51d>
		--nfree;
	assert(nfree == 0);
f01015a6:	85 db                	test   %ebx,%ebx
f01015a8:	74 19                	je     f01015c3 <mem_init+0x543>
f01015aa:	68 b5 54 10 f0       	push   $0xf01054b5
f01015af:	68 05 53 10 f0       	push   $0xf0105305
f01015b4:	68 f3 02 00 00       	push   $0x2f3
f01015b9:	68 cd 52 10 f0       	push   $0xf01052cd
f01015be:	e8 dd ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015c3:	83 ec 0c             	sub    $0xc,%esp
f01015c6:	68 d0 4c 10 f0       	push   $0xf0104cd0
f01015cb:	e8 51 19 00 00       	call   f0102f21 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015d7:	e8 c0 f7 ff ff       	call   f0100d9c <page_alloc>
f01015dc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015df:	83 c4 10             	add    $0x10,%esp
f01015e2:	85 c0                	test   %eax,%eax
f01015e4:	75 19                	jne    f01015ff <mem_init+0x57f>
f01015e6:	68 c3 53 10 f0       	push   $0xf01053c3
f01015eb:	68 05 53 10 f0       	push   $0xf0105305
f01015f0:	68 52 03 00 00       	push   $0x352
f01015f5:	68 cd 52 10 f0       	push   $0xf01052cd
f01015fa:	e8 a1 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01015ff:	83 ec 0c             	sub    $0xc,%esp
f0101602:	6a 00                	push   $0x0
f0101604:	e8 93 f7 ff ff       	call   f0100d9c <page_alloc>
f0101609:	89 c6                	mov    %eax,%esi
f010160b:	83 c4 10             	add    $0x10,%esp
f010160e:	85 c0                	test   %eax,%eax
f0101610:	75 19                	jne    f010162b <mem_init+0x5ab>
f0101612:	68 d9 53 10 f0       	push   $0xf01053d9
f0101617:	68 05 53 10 f0       	push   $0xf0105305
f010161c:	68 53 03 00 00       	push   $0x353
f0101621:	68 cd 52 10 f0       	push   $0xf01052cd
f0101626:	e8 75 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010162b:	83 ec 0c             	sub    $0xc,%esp
f010162e:	6a 00                	push   $0x0
f0101630:	e8 67 f7 ff ff       	call   f0100d9c <page_alloc>
f0101635:	89 c3                	mov    %eax,%ebx
f0101637:	83 c4 10             	add    $0x10,%esp
f010163a:	85 c0                	test   %eax,%eax
f010163c:	75 19                	jne    f0101657 <mem_init+0x5d7>
f010163e:	68 ef 53 10 f0       	push   $0xf01053ef
f0101643:	68 05 53 10 f0       	push   $0xf0105305
f0101648:	68 54 03 00 00       	push   $0x354
f010164d:	68 cd 52 10 f0       	push   $0xf01052cd
f0101652:	e8 49 ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101657:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010165a:	75 19                	jne    f0101675 <mem_init+0x5f5>
f010165c:	68 05 54 10 f0       	push   $0xf0105405
f0101661:	68 05 53 10 f0       	push   $0xf0105305
f0101666:	68 57 03 00 00       	push   $0x357
f010166b:	68 cd 52 10 f0       	push   $0xf01052cd
f0101670:	e8 2b ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101675:	39 c6                	cmp    %eax,%esi
f0101677:	74 05                	je     f010167e <mem_init+0x5fe>
f0101679:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010167c:	75 19                	jne    f0101697 <mem_init+0x617>
f010167e:	68 b0 4c 10 f0       	push   $0xf0104cb0
f0101683:	68 05 53 10 f0       	push   $0xf0105305
f0101688:	68 58 03 00 00       	push   $0x358
f010168d:	68 cd 52 10 f0       	push   $0xf01052cd
f0101692:	e8 09 ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101697:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f010169c:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010169f:	c7 05 7c ff 16 f0 00 	movl   $0x0,0xf016ff7c
f01016a6:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016a9:	83 ec 0c             	sub    $0xc,%esp
f01016ac:	6a 00                	push   $0x0
f01016ae:	e8 e9 f6 ff ff       	call   f0100d9c <page_alloc>
f01016b3:	83 c4 10             	add    $0x10,%esp
f01016b6:	85 c0                	test   %eax,%eax
f01016b8:	74 19                	je     f01016d3 <mem_init+0x653>
f01016ba:	68 6e 54 10 f0       	push   $0xf010546e
f01016bf:	68 05 53 10 f0       	push   $0xf0105305
f01016c4:	68 5f 03 00 00       	push   $0x35f
f01016c9:	68 cd 52 10 f0       	push   $0xf01052cd
f01016ce:	e8 cd e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016d3:	83 ec 04             	sub    $0x4,%esp
f01016d6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016d9:	50                   	push   %eax
f01016da:	6a 00                	push   $0x0
f01016dc:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01016e2:	e8 69 f8 ff ff       	call   f0100f50 <page_lookup>
f01016e7:	83 c4 10             	add    $0x10,%esp
f01016ea:	85 c0                	test   %eax,%eax
f01016ec:	74 19                	je     f0101707 <mem_init+0x687>
f01016ee:	68 f0 4c 10 f0       	push   $0xf0104cf0
f01016f3:	68 05 53 10 f0       	push   $0xf0105305
f01016f8:	68 62 03 00 00       	push   $0x362
f01016fd:	68 cd 52 10 f0       	push   $0xf01052cd
f0101702:	e8 99 e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101707:	6a 02                	push   $0x2
f0101709:	6a 00                	push   $0x0
f010170b:	56                   	push   %esi
f010170c:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101712:	e8 df f8 ff ff       	call   f0100ff6 <page_insert>
f0101717:	83 c4 10             	add    $0x10,%esp
f010171a:	85 c0                	test   %eax,%eax
f010171c:	78 19                	js     f0101737 <mem_init+0x6b7>
f010171e:	68 28 4d 10 f0       	push   $0xf0104d28
f0101723:	68 05 53 10 f0       	push   $0xf0105305
f0101728:	68 65 03 00 00       	push   $0x365
f010172d:	68 cd 52 10 f0       	push   $0xf01052cd
f0101732:	e8 69 e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101737:	83 ec 0c             	sub    $0xc,%esp
f010173a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010173d:	e8 ca f6 ff ff       	call   f0100e0c <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101742:	6a 02                	push   $0x2
f0101744:	6a 00                	push   $0x0
f0101746:	56                   	push   %esi
f0101747:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f010174d:	e8 a4 f8 ff ff       	call   f0100ff6 <page_insert>
f0101752:	83 c4 20             	add    $0x20,%esp
f0101755:	85 c0                	test   %eax,%eax
f0101757:	74 19                	je     f0101772 <mem_init+0x6f2>
f0101759:	68 58 4d 10 f0       	push   $0xf0104d58
f010175e:	68 05 53 10 f0       	push   $0xf0105305
f0101763:	68 69 03 00 00       	push   $0x369
f0101768:	68 cd 52 10 f0       	push   $0xf01052cd
f010176d:	e8 2e e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101772:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101778:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
f010177d:	89 c1                	mov    %eax,%ecx
f010177f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101782:	8b 17                	mov    (%edi),%edx
f0101784:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010178a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010178d:	29 c8                	sub    %ecx,%eax
f010178f:	c1 f8 03             	sar    $0x3,%eax
f0101792:	c1 e0 0c             	shl    $0xc,%eax
f0101795:	39 c2                	cmp    %eax,%edx
f0101797:	74 19                	je     f01017b2 <mem_init+0x732>
f0101799:	68 88 4d 10 f0       	push   $0xf0104d88
f010179e:	68 05 53 10 f0       	push   $0xf0105305
f01017a3:	68 6a 03 00 00       	push   $0x36a
f01017a8:	68 cd 52 10 f0       	push   $0xf01052cd
f01017ad:	e8 ee e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017b2:	ba 00 00 00 00       	mov    $0x0,%edx
f01017b7:	89 f8                	mov    %edi,%eax
f01017b9:	e8 a4 f1 ff ff       	call   f0100962 <check_va2pa>
f01017be:	89 f2                	mov    %esi,%edx
f01017c0:	2b 55 d0             	sub    -0x30(%ebp),%edx
f01017c3:	c1 fa 03             	sar    $0x3,%edx
f01017c6:	c1 e2 0c             	shl    $0xc,%edx
f01017c9:	39 d0                	cmp    %edx,%eax
f01017cb:	74 19                	je     f01017e6 <mem_init+0x766>
f01017cd:	68 b0 4d 10 f0       	push   $0xf0104db0
f01017d2:	68 05 53 10 f0       	push   $0xf0105305
f01017d7:	68 6b 03 00 00       	push   $0x36b
f01017dc:	68 cd 52 10 f0       	push   $0xf01052cd
f01017e1:	e8 ba e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01017e6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017eb:	74 19                	je     f0101806 <mem_init+0x786>
f01017ed:	68 c0 54 10 f0       	push   $0xf01054c0
f01017f2:	68 05 53 10 f0       	push   $0xf0105305
f01017f7:	68 6c 03 00 00       	push   $0x36c
f01017fc:	68 cd 52 10 f0       	push   $0xf01052cd
f0101801:	e8 9a e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f0101806:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101809:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010180e:	74 19                	je     f0101829 <mem_init+0x7a9>
f0101810:	68 d1 54 10 f0       	push   $0xf01054d1
f0101815:	68 05 53 10 f0       	push   $0xf0105305
f010181a:	68 6d 03 00 00       	push   $0x36d
f010181f:	68 cd 52 10 f0       	push   $0xf01052cd
f0101824:	e8 77 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101829:	6a 02                	push   $0x2
f010182b:	68 00 10 00 00       	push   $0x1000
f0101830:	53                   	push   %ebx
f0101831:	57                   	push   %edi
f0101832:	e8 bf f7 ff ff       	call   f0100ff6 <page_insert>
f0101837:	83 c4 10             	add    $0x10,%esp
f010183a:	85 c0                	test   %eax,%eax
f010183c:	74 19                	je     f0101857 <mem_init+0x7d7>
f010183e:	68 e0 4d 10 f0       	push   $0xf0104de0
f0101843:	68 05 53 10 f0       	push   $0xf0105305
f0101848:	68 70 03 00 00       	push   $0x370
f010184d:	68 cd 52 10 f0       	push   $0xf01052cd
f0101852:	e8 49 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101857:	ba 00 10 00 00       	mov    $0x1000,%edx
f010185c:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0101861:	e8 fc f0 ff ff       	call   f0100962 <check_va2pa>
f0101866:	89 da                	mov    %ebx,%edx
f0101868:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f010186e:	c1 fa 03             	sar    $0x3,%edx
f0101871:	c1 e2 0c             	shl    $0xc,%edx
f0101874:	39 d0                	cmp    %edx,%eax
f0101876:	74 19                	je     f0101891 <mem_init+0x811>
f0101878:	68 1c 4e 10 f0       	push   $0xf0104e1c
f010187d:	68 05 53 10 f0       	push   $0xf0105305
f0101882:	68 71 03 00 00       	push   $0x371
f0101887:	68 cd 52 10 f0       	push   $0xf01052cd
f010188c:	e8 0f e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101891:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101896:	74 19                	je     f01018b1 <mem_init+0x831>
f0101898:	68 e2 54 10 f0       	push   $0xf01054e2
f010189d:	68 05 53 10 f0       	push   $0xf0105305
f01018a2:	68 72 03 00 00       	push   $0x372
f01018a7:	68 cd 52 10 f0       	push   $0xf01052cd
f01018ac:	e8 ef e7 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018b1:	83 ec 0c             	sub    $0xc,%esp
f01018b4:	6a 00                	push   $0x0
f01018b6:	e8 e1 f4 ff ff       	call   f0100d9c <page_alloc>
f01018bb:	83 c4 10             	add    $0x10,%esp
f01018be:	85 c0                	test   %eax,%eax
f01018c0:	74 19                	je     f01018db <mem_init+0x85b>
f01018c2:	68 6e 54 10 f0       	push   $0xf010546e
f01018c7:	68 05 53 10 f0       	push   $0xf0105305
f01018cc:	68 75 03 00 00       	push   $0x375
f01018d1:	68 cd 52 10 f0       	push   $0xf01052cd
f01018d6:	e8 c5 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018db:	6a 02                	push   $0x2
f01018dd:	68 00 10 00 00       	push   $0x1000
f01018e2:	53                   	push   %ebx
f01018e3:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01018e9:	e8 08 f7 ff ff       	call   f0100ff6 <page_insert>
f01018ee:	83 c4 10             	add    $0x10,%esp
f01018f1:	85 c0                	test   %eax,%eax
f01018f3:	74 19                	je     f010190e <mem_init+0x88e>
f01018f5:	68 e0 4d 10 f0       	push   $0xf0104de0
f01018fa:	68 05 53 10 f0       	push   $0xf0105305
f01018ff:	68 78 03 00 00       	push   $0x378
f0101904:	68 cd 52 10 f0       	push   $0xf01052cd
f0101909:	e8 92 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010190e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101913:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0101918:	e8 45 f0 ff ff       	call   f0100962 <check_va2pa>
f010191d:	89 da                	mov    %ebx,%edx
f010191f:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101925:	c1 fa 03             	sar    $0x3,%edx
f0101928:	c1 e2 0c             	shl    $0xc,%edx
f010192b:	39 d0                	cmp    %edx,%eax
f010192d:	74 19                	je     f0101948 <mem_init+0x8c8>
f010192f:	68 1c 4e 10 f0       	push   $0xf0104e1c
f0101934:	68 05 53 10 f0       	push   $0xf0105305
f0101939:	68 79 03 00 00       	push   $0x379
f010193e:	68 cd 52 10 f0       	push   $0xf01052cd
f0101943:	e8 58 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101948:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010194d:	74 19                	je     f0101968 <mem_init+0x8e8>
f010194f:	68 e2 54 10 f0       	push   $0xf01054e2
f0101954:	68 05 53 10 f0       	push   $0xf0105305
f0101959:	68 7a 03 00 00       	push   $0x37a
f010195e:	68 cd 52 10 f0       	push   $0xf01052cd
f0101963:	e8 38 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101968:	83 ec 0c             	sub    $0xc,%esp
f010196b:	6a 00                	push   $0x0
f010196d:	e8 2a f4 ff ff       	call   f0100d9c <page_alloc>
f0101972:	83 c4 10             	add    $0x10,%esp
f0101975:	85 c0                	test   %eax,%eax
f0101977:	74 19                	je     f0101992 <mem_init+0x912>
f0101979:	68 6e 54 10 f0       	push   $0xf010546e
f010197e:	68 05 53 10 f0       	push   $0xf0105305
f0101983:	68 7e 03 00 00       	push   $0x37e
f0101988:	68 cd 52 10 f0       	push   $0xf01052cd
f010198d:	e8 0e e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101992:	8b 15 48 0c 17 f0    	mov    0xf0170c48,%edx
f0101998:	8b 02                	mov    (%edx),%eax
f010199a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010199f:	89 c1                	mov    %eax,%ecx
f01019a1:	c1 e9 0c             	shr    $0xc,%ecx
f01019a4:	3b 0d 44 0c 17 f0    	cmp    0xf0170c44,%ecx
f01019aa:	72 15                	jb     f01019c1 <mem_init+0x941>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019ac:	50                   	push   %eax
f01019ad:	68 24 4b 10 f0       	push   $0xf0104b24
f01019b2:	68 81 03 00 00       	push   $0x381
f01019b7:	68 cd 52 10 f0       	push   $0xf01052cd
f01019bc:	e8 df e6 ff ff       	call   f01000a0 <_panic>
f01019c1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019c6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019c9:	83 ec 04             	sub    $0x4,%esp
f01019cc:	6a 00                	push   $0x0
f01019ce:	68 00 10 00 00       	push   $0x1000
f01019d3:	52                   	push   %edx
f01019d4:	e8 95 f4 ff ff       	call   f0100e6e <pgdir_walk>
f01019d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019dc:	8d 57 04             	lea    0x4(%edi),%edx
f01019df:	83 c4 10             	add    $0x10,%esp
f01019e2:	39 d0                	cmp    %edx,%eax
f01019e4:	74 19                	je     f01019ff <mem_init+0x97f>
f01019e6:	68 4c 4e 10 f0       	push   $0xf0104e4c
f01019eb:	68 05 53 10 f0       	push   $0xf0105305
f01019f0:	68 82 03 00 00       	push   $0x382
f01019f5:	68 cd 52 10 f0       	push   $0xf01052cd
f01019fa:	e8 a1 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019ff:	6a 06                	push   $0x6
f0101a01:	68 00 10 00 00       	push   $0x1000
f0101a06:	53                   	push   %ebx
f0101a07:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101a0d:	e8 e4 f5 ff ff       	call   f0100ff6 <page_insert>
f0101a12:	83 c4 10             	add    $0x10,%esp
f0101a15:	85 c0                	test   %eax,%eax
f0101a17:	74 19                	je     f0101a32 <mem_init+0x9b2>
f0101a19:	68 8c 4e 10 f0       	push   $0xf0104e8c
f0101a1e:	68 05 53 10 f0       	push   $0xf0105305
f0101a23:	68 85 03 00 00       	push   $0x385
f0101a28:	68 cd 52 10 f0       	push   $0xf01052cd
f0101a2d:	e8 6e e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a32:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101a38:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a3d:	89 f8                	mov    %edi,%eax
f0101a3f:	e8 1e ef ff ff       	call   f0100962 <check_va2pa>
f0101a44:	89 da                	mov    %ebx,%edx
f0101a46:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101a4c:	c1 fa 03             	sar    $0x3,%edx
f0101a4f:	c1 e2 0c             	shl    $0xc,%edx
f0101a52:	39 d0                	cmp    %edx,%eax
f0101a54:	74 19                	je     f0101a6f <mem_init+0x9ef>
f0101a56:	68 1c 4e 10 f0       	push   $0xf0104e1c
f0101a5b:	68 05 53 10 f0       	push   $0xf0105305
f0101a60:	68 86 03 00 00       	push   $0x386
f0101a65:	68 cd 52 10 f0       	push   $0xf01052cd
f0101a6a:	e8 31 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a6f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a74:	74 19                	je     f0101a8f <mem_init+0xa0f>
f0101a76:	68 e2 54 10 f0       	push   $0xf01054e2
f0101a7b:	68 05 53 10 f0       	push   $0xf0105305
f0101a80:	68 87 03 00 00       	push   $0x387
f0101a85:	68 cd 52 10 f0       	push   $0xf01052cd
f0101a8a:	e8 11 e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a8f:	83 ec 04             	sub    $0x4,%esp
f0101a92:	6a 00                	push   $0x0
f0101a94:	68 00 10 00 00       	push   $0x1000
f0101a99:	57                   	push   %edi
f0101a9a:	e8 cf f3 ff ff       	call   f0100e6e <pgdir_walk>
f0101a9f:	83 c4 10             	add    $0x10,%esp
f0101aa2:	f6 00 04             	testb  $0x4,(%eax)
f0101aa5:	75 19                	jne    f0101ac0 <mem_init+0xa40>
f0101aa7:	68 cc 4e 10 f0       	push   $0xf0104ecc
f0101aac:	68 05 53 10 f0       	push   $0xf0105305
f0101ab1:	68 88 03 00 00       	push   $0x388
f0101ab6:	68 cd 52 10 f0       	push   $0xf01052cd
f0101abb:	e8 e0 e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ac0:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0101ac5:	f6 00 04             	testb  $0x4,(%eax)
f0101ac8:	75 19                	jne    f0101ae3 <mem_init+0xa63>
f0101aca:	68 f3 54 10 f0       	push   $0xf01054f3
f0101acf:	68 05 53 10 f0       	push   $0xf0105305
f0101ad4:	68 89 03 00 00       	push   $0x389
f0101ad9:	68 cd 52 10 f0       	push   $0xf01052cd
f0101ade:	e8 bd e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ae3:	6a 02                	push   $0x2
f0101ae5:	68 00 10 00 00       	push   $0x1000
f0101aea:	53                   	push   %ebx
f0101aeb:	50                   	push   %eax
f0101aec:	e8 05 f5 ff ff       	call   f0100ff6 <page_insert>
f0101af1:	83 c4 10             	add    $0x10,%esp
f0101af4:	85 c0                	test   %eax,%eax
f0101af6:	74 19                	je     f0101b11 <mem_init+0xa91>
f0101af8:	68 e0 4d 10 f0       	push   $0xf0104de0
f0101afd:	68 05 53 10 f0       	push   $0xf0105305
f0101b02:	68 8c 03 00 00       	push   $0x38c
f0101b07:	68 cd 52 10 f0       	push   $0xf01052cd
f0101b0c:	e8 8f e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b11:	83 ec 04             	sub    $0x4,%esp
f0101b14:	6a 00                	push   $0x0
f0101b16:	68 00 10 00 00       	push   $0x1000
f0101b1b:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101b21:	e8 48 f3 ff ff       	call   f0100e6e <pgdir_walk>
f0101b26:	83 c4 10             	add    $0x10,%esp
f0101b29:	f6 00 02             	testb  $0x2,(%eax)
f0101b2c:	75 19                	jne    f0101b47 <mem_init+0xac7>
f0101b2e:	68 00 4f 10 f0       	push   $0xf0104f00
f0101b33:	68 05 53 10 f0       	push   $0xf0105305
f0101b38:	68 8d 03 00 00       	push   $0x38d
f0101b3d:	68 cd 52 10 f0       	push   $0xf01052cd
f0101b42:	e8 59 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b47:	83 ec 04             	sub    $0x4,%esp
f0101b4a:	6a 00                	push   $0x0
f0101b4c:	68 00 10 00 00       	push   $0x1000
f0101b51:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101b57:	e8 12 f3 ff ff       	call   f0100e6e <pgdir_walk>
f0101b5c:	83 c4 10             	add    $0x10,%esp
f0101b5f:	f6 00 04             	testb  $0x4,(%eax)
f0101b62:	74 19                	je     f0101b7d <mem_init+0xafd>
f0101b64:	68 34 4f 10 f0       	push   $0xf0104f34
f0101b69:	68 05 53 10 f0       	push   $0xf0105305
f0101b6e:	68 8e 03 00 00       	push   $0x38e
f0101b73:	68 cd 52 10 f0       	push   $0xf01052cd
f0101b78:	e8 23 e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b7d:	6a 02                	push   $0x2
f0101b7f:	68 00 00 40 00       	push   $0x400000
f0101b84:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b87:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101b8d:	e8 64 f4 ff ff       	call   f0100ff6 <page_insert>
f0101b92:	83 c4 10             	add    $0x10,%esp
f0101b95:	85 c0                	test   %eax,%eax
f0101b97:	78 19                	js     f0101bb2 <mem_init+0xb32>
f0101b99:	68 6c 4f 10 f0       	push   $0xf0104f6c
f0101b9e:	68 05 53 10 f0       	push   $0xf0105305
f0101ba3:	68 91 03 00 00       	push   $0x391
f0101ba8:	68 cd 52 10 f0       	push   $0xf01052cd
f0101bad:	e8 ee e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101bb2:	6a 02                	push   $0x2
f0101bb4:	68 00 10 00 00       	push   $0x1000
f0101bb9:	56                   	push   %esi
f0101bba:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101bc0:	e8 31 f4 ff ff       	call   f0100ff6 <page_insert>
f0101bc5:	83 c4 10             	add    $0x10,%esp
f0101bc8:	85 c0                	test   %eax,%eax
f0101bca:	74 19                	je     f0101be5 <mem_init+0xb65>
f0101bcc:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0101bd1:	68 05 53 10 f0       	push   $0xf0105305
f0101bd6:	68 94 03 00 00       	push   $0x394
f0101bdb:	68 cd 52 10 f0       	push   $0xf01052cd
f0101be0:	e8 bb e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101be5:	83 ec 04             	sub    $0x4,%esp
f0101be8:	6a 00                	push   $0x0
f0101bea:	68 00 10 00 00       	push   $0x1000
f0101bef:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101bf5:	e8 74 f2 ff ff       	call   f0100e6e <pgdir_walk>
f0101bfa:	83 c4 10             	add    $0x10,%esp
f0101bfd:	f6 00 04             	testb  $0x4,(%eax)
f0101c00:	74 19                	je     f0101c1b <mem_init+0xb9b>
f0101c02:	68 34 4f 10 f0       	push   $0xf0104f34
f0101c07:	68 05 53 10 f0       	push   $0xf0105305
f0101c0c:	68 95 03 00 00       	push   $0x395
f0101c11:	68 cd 52 10 f0       	push   $0xf01052cd
f0101c16:	e8 85 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c1b:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101c21:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c26:	89 f8                	mov    %edi,%eax
f0101c28:	e8 35 ed ff ff       	call   f0100962 <check_va2pa>
f0101c2d:	89 c1                	mov    %eax,%ecx
f0101c2f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101c32:	89 f0                	mov    %esi,%eax
f0101c34:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101c3a:	c1 f8 03             	sar    $0x3,%eax
f0101c3d:	c1 e0 0c             	shl    $0xc,%eax
f0101c40:	39 c1                	cmp    %eax,%ecx
f0101c42:	74 19                	je     f0101c5d <mem_init+0xbdd>
f0101c44:	68 e0 4f 10 f0       	push   $0xf0104fe0
f0101c49:	68 05 53 10 f0       	push   $0xf0105305
f0101c4e:	68 98 03 00 00       	push   $0x398
f0101c53:	68 cd 52 10 f0       	push   $0xf01052cd
f0101c58:	e8 43 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c5d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c62:	89 f8                	mov    %edi,%eax
f0101c64:	e8 f9 ec ff ff       	call   f0100962 <check_va2pa>
f0101c69:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101c6c:	74 19                	je     f0101c87 <mem_init+0xc07>
f0101c6e:	68 0c 50 10 f0       	push   $0xf010500c
f0101c73:	68 05 53 10 f0       	push   $0xf0105305
f0101c78:	68 99 03 00 00       	push   $0x399
f0101c7d:	68 cd 52 10 f0       	push   $0xf01052cd
f0101c82:	e8 19 e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c87:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101c8c:	74 19                	je     f0101ca7 <mem_init+0xc27>
f0101c8e:	68 09 55 10 f0       	push   $0xf0105509
f0101c93:	68 05 53 10 f0       	push   $0xf0105305
f0101c98:	68 9b 03 00 00       	push   $0x39b
f0101c9d:	68 cd 52 10 f0       	push   $0xf01052cd
f0101ca2:	e8 f9 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ca7:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101cac:	74 19                	je     f0101cc7 <mem_init+0xc47>
f0101cae:	68 1a 55 10 f0       	push   $0xf010551a
f0101cb3:	68 05 53 10 f0       	push   $0xf0105305
f0101cb8:	68 9c 03 00 00       	push   $0x39c
f0101cbd:	68 cd 52 10 f0       	push   $0xf01052cd
f0101cc2:	e8 d9 e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cc7:	83 ec 0c             	sub    $0xc,%esp
f0101cca:	6a 00                	push   $0x0
f0101ccc:	e8 cb f0 ff ff       	call   f0100d9c <page_alloc>
f0101cd1:	83 c4 10             	add    $0x10,%esp
f0101cd4:	39 c3                	cmp    %eax,%ebx
f0101cd6:	75 04                	jne    f0101cdc <mem_init+0xc5c>
f0101cd8:	85 c0                	test   %eax,%eax
f0101cda:	75 19                	jne    f0101cf5 <mem_init+0xc75>
f0101cdc:	68 3c 50 10 f0       	push   $0xf010503c
f0101ce1:	68 05 53 10 f0       	push   $0xf0105305
f0101ce6:	68 9f 03 00 00       	push   $0x39f
f0101ceb:	68 cd 52 10 f0       	push   $0xf01052cd
f0101cf0:	e8 ab e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cf5:	83 ec 08             	sub    $0x8,%esp
f0101cf8:	6a 00                	push   $0x0
f0101cfa:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101d00:	e8 a3 f2 ff ff       	call   f0100fa8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d05:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101d0b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d10:	89 f8                	mov    %edi,%eax
f0101d12:	e8 4b ec ff ff       	call   f0100962 <check_va2pa>
f0101d17:	83 c4 10             	add    $0x10,%esp
f0101d1a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d1d:	74 19                	je     f0101d38 <mem_init+0xcb8>
f0101d1f:	68 60 50 10 f0       	push   $0xf0105060
f0101d24:	68 05 53 10 f0       	push   $0xf0105305
f0101d29:	68 a3 03 00 00       	push   $0x3a3
f0101d2e:	68 cd 52 10 f0       	push   $0xf01052cd
f0101d33:	e8 68 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d38:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d3d:	89 f8                	mov    %edi,%eax
f0101d3f:	e8 1e ec ff ff       	call   f0100962 <check_va2pa>
f0101d44:	89 f2                	mov    %esi,%edx
f0101d46:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101d4c:	c1 fa 03             	sar    $0x3,%edx
f0101d4f:	c1 e2 0c             	shl    $0xc,%edx
f0101d52:	39 d0                	cmp    %edx,%eax
f0101d54:	74 19                	je     f0101d6f <mem_init+0xcef>
f0101d56:	68 0c 50 10 f0       	push   $0xf010500c
f0101d5b:	68 05 53 10 f0       	push   $0xf0105305
f0101d60:	68 a4 03 00 00       	push   $0x3a4
f0101d65:	68 cd 52 10 f0       	push   $0xf01052cd
f0101d6a:	e8 31 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101d6f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d74:	74 19                	je     f0101d8f <mem_init+0xd0f>
f0101d76:	68 c0 54 10 f0       	push   $0xf01054c0
f0101d7b:	68 05 53 10 f0       	push   $0xf0105305
f0101d80:	68 a5 03 00 00       	push   $0x3a5
f0101d85:	68 cd 52 10 f0       	push   $0xf01052cd
f0101d8a:	e8 11 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d8f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d94:	74 19                	je     f0101daf <mem_init+0xd2f>
f0101d96:	68 1a 55 10 f0       	push   $0xf010551a
f0101d9b:	68 05 53 10 f0       	push   $0xf0105305
f0101da0:	68 a6 03 00 00       	push   $0x3a6
f0101da5:	68 cd 52 10 f0       	push   $0xf01052cd
f0101daa:	e8 f1 e2 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101daf:	6a 00                	push   $0x0
f0101db1:	68 00 10 00 00       	push   $0x1000
f0101db6:	56                   	push   %esi
f0101db7:	57                   	push   %edi
f0101db8:	e8 39 f2 ff ff       	call   f0100ff6 <page_insert>
f0101dbd:	83 c4 10             	add    $0x10,%esp
f0101dc0:	85 c0                	test   %eax,%eax
f0101dc2:	74 19                	je     f0101ddd <mem_init+0xd5d>
f0101dc4:	68 84 50 10 f0       	push   $0xf0105084
f0101dc9:	68 05 53 10 f0       	push   $0xf0105305
f0101dce:	68 a9 03 00 00       	push   $0x3a9
f0101dd3:	68 cd 52 10 f0       	push   $0xf01052cd
f0101dd8:	e8 c3 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101ddd:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101de2:	75 19                	jne    f0101dfd <mem_init+0xd7d>
f0101de4:	68 2b 55 10 f0       	push   $0xf010552b
f0101de9:	68 05 53 10 f0       	push   $0xf0105305
f0101dee:	68 aa 03 00 00       	push   $0x3aa
f0101df3:	68 cd 52 10 f0       	push   $0xf01052cd
f0101df8:	e8 a3 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101dfd:	83 3e 00             	cmpl   $0x0,(%esi)
f0101e00:	74 19                	je     f0101e1b <mem_init+0xd9b>
f0101e02:	68 37 55 10 f0       	push   $0xf0105537
f0101e07:	68 05 53 10 f0       	push   $0xf0105305
f0101e0c:	68 ab 03 00 00       	push   $0x3ab
f0101e11:	68 cd 52 10 f0       	push   $0xf01052cd
f0101e16:	e8 85 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e1b:	83 ec 08             	sub    $0x8,%esp
f0101e1e:	68 00 10 00 00       	push   $0x1000
f0101e23:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101e29:	e8 7a f1 ff ff       	call   f0100fa8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e2e:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101e34:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e39:	89 f8                	mov    %edi,%eax
f0101e3b:	e8 22 eb ff ff       	call   f0100962 <check_va2pa>
f0101e40:	83 c4 10             	add    $0x10,%esp
f0101e43:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e46:	74 19                	je     f0101e61 <mem_init+0xde1>
f0101e48:	68 60 50 10 f0       	push   $0xf0105060
f0101e4d:	68 05 53 10 f0       	push   $0xf0105305
f0101e52:	68 af 03 00 00       	push   $0x3af
f0101e57:	68 cd 52 10 f0       	push   $0xf01052cd
f0101e5c:	e8 3f e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e61:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e66:	89 f8                	mov    %edi,%eax
f0101e68:	e8 f5 ea ff ff       	call   f0100962 <check_va2pa>
f0101e6d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e70:	74 19                	je     f0101e8b <mem_init+0xe0b>
f0101e72:	68 bc 50 10 f0       	push   $0xf01050bc
f0101e77:	68 05 53 10 f0       	push   $0xf0105305
f0101e7c:	68 b0 03 00 00       	push   $0x3b0
f0101e81:	68 cd 52 10 f0       	push   $0xf01052cd
f0101e86:	e8 15 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e8b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e90:	74 19                	je     f0101eab <mem_init+0xe2b>
f0101e92:	68 4c 55 10 f0       	push   $0xf010554c
f0101e97:	68 05 53 10 f0       	push   $0xf0105305
f0101e9c:	68 b1 03 00 00       	push   $0x3b1
f0101ea1:	68 cd 52 10 f0       	push   $0xf01052cd
f0101ea6:	e8 f5 e1 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101eab:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101eb0:	74 19                	je     f0101ecb <mem_init+0xe4b>
f0101eb2:	68 1a 55 10 f0       	push   $0xf010551a
f0101eb7:	68 05 53 10 f0       	push   $0xf0105305
f0101ebc:	68 b2 03 00 00       	push   $0x3b2
f0101ec1:	68 cd 52 10 f0       	push   $0xf01052cd
f0101ec6:	e8 d5 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ecb:	83 ec 0c             	sub    $0xc,%esp
f0101ece:	6a 00                	push   $0x0
f0101ed0:	e8 c7 ee ff ff       	call   f0100d9c <page_alloc>
f0101ed5:	83 c4 10             	add    $0x10,%esp
f0101ed8:	85 c0                	test   %eax,%eax
f0101eda:	74 04                	je     f0101ee0 <mem_init+0xe60>
f0101edc:	39 c6                	cmp    %eax,%esi
f0101ede:	74 19                	je     f0101ef9 <mem_init+0xe79>
f0101ee0:	68 e4 50 10 f0       	push   $0xf01050e4
f0101ee5:	68 05 53 10 f0       	push   $0xf0105305
f0101eea:	68 b5 03 00 00       	push   $0x3b5
f0101eef:	68 cd 52 10 f0       	push   $0xf01052cd
f0101ef4:	e8 a7 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ef9:	83 ec 0c             	sub    $0xc,%esp
f0101efc:	6a 00                	push   $0x0
f0101efe:	e8 99 ee ff ff       	call   f0100d9c <page_alloc>
f0101f03:	83 c4 10             	add    $0x10,%esp
f0101f06:	85 c0                	test   %eax,%eax
f0101f08:	74 19                	je     f0101f23 <mem_init+0xea3>
f0101f0a:	68 6e 54 10 f0       	push   $0xf010546e
f0101f0f:	68 05 53 10 f0       	push   $0xf0105305
f0101f14:	68 b8 03 00 00       	push   $0x3b8
f0101f19:	68 cd 52 10 f0       	push   $0xf01052cd
f0101f1e:	e8 7d e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f23:	8b 0d 48 0c 17 f0    	mov    0xf0170c48,%ecx
f0101f29:	8b 11                	mov    (%ecx),%edx
f0101f2b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f31:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f34:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101f3a:	c1 f8 03             	sar    $0x3,%eax
f0101f3d:	c1 e0 0c             	shl    $0xc,%eax
f0101f40:	39 c2                	cmp    %eax,%edx
f0101f42:	74 19                	je     f0101f5d <mem_init+0xedd>
f0101f44:	68 88 4d 10 f0       	push   $0xf0104d88
f0101f49:	68 05 53 10 f0       	push   $0xf0105305
f0101f4e:	68 bb 03 00 00       	push   $0x3bb
f0101f53:	68 cd 52 10 f0       	push   $0xf01052cd
f0101f58:	e8 43 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f5d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f63:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f66:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f6b:	74 19                	je     f0101f86 <mem_init+0xf06>
f0101f6d:	68 d1 54 10 f0       	push   $0xf01054d1
f0101f72:	68 05 53 10 f0       	push   $0xf0105305
f0101f77:	68 bd 03 00 00       	push   $0x3bd
f0101f7c:	68 cd 52 10 f0       	push   $0xf01052cd
f0101f81:	e8 1a e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f86:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f89:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f8f:	83 ec 0c             	sub    $0xc,%esp
f0101f92:	50                   	push   %eax
f0101f93:	e8 74 ee ff ff       	call   f0100e0c <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f98:	83 c4 0c             	add    $0xc,%esp
f0101f9b:	6a 01                	push   $0x1
f0101f9d:	68 00 10 40 00       	push   $0x401000
f0101fa2:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101fa8:	e8 c1 ee ff ff       	call   f0100e6e <pgdir_walk>
f0101fad:	89 c7                	mov    %eax,%edi
f0101faf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fb2:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0101fb7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101fba:	8b 40 04             	mov    0x4(%eax),%eax
f0101fbd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fc2:	8b 0d 44 0c 17 f0    	mov    0xf0170c44,%ecx
f0101fc8:	89 c2                	mov    %eax,%edx
f0101fca:	c1 ea 0c             	shr    $0xc,%edx
f0101fcd:	83 c4 10             	add    $0x10,%esp
f0101fd0:	39 ca                	cmp    %ecx,%edx
f0101fd2:	72 15                	jb     f0101fe9 <mem_init+0xf69>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fd4:	50                   	push   %eax
f0101fd5:	68 24 4b 10 f0       	push   $0xf0104b24
f0101fda:	68 c4 03 00 00       	push   $0x3c4
f0101fdf:	68 cd 52 10 f0       	push   $0xf01052cd
f0101fe4:	e8 b7 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fe9:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fee:	39 c7                	cmp    %eax,%edi
f0101ff0:	74 19                	je     f010200b <mem_init+0xf8b>
f0101ff2:	68 5d 55 10 f0       	push   $0xf010555d
f0101ff7:	68 05 53 10 f0       	push   $0xf0105305
f0101ffc:	68 c5 03 00 00       	push   $0x3c5
f0102001:	68 cd 52 10 f0       	push   $0xf01052cd
f0102006:	e8 95 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010200b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010200e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102015:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102018:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010201e:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0102024:	c1 f8 03             	sar    $0x3,%eax
f0102027:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010202a:	89 c2                	mov    %eax,%edx
f010202c:	c1 ea 0c             	shr    $0xc,%edx
f010202f:	39 d1                	cmp    %edx,%ecx
f0102031:	77 12                	ja     f0102045 <mem_init+0xfc5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102033:	50                   	push   %eax
f0102034:	68 24 4b 10 f0       	push   $0xf0104b24
f0102039:	6a 56                	push   $0x56
f010203b:	68 eb 52 10 f0       	push   $0xf01052eb
f0102040:	e8 5b e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102045:	83 ec 04             	sub    $0x4,%esp
f0102048:	68 00 10 00 00       	push   $0x1000
f010204d:	68 ff 00 00 00       	push   $0xff
f0102052:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102057:	50                   	push   %eax
f0102058:	e8 0c 21 00 00       	call   f0104169 <memset>
	page_free(pp0);
f010205d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102060:	89 3c 24             	mov    %edi,(%esp)
f0102063:	e8 a4 ed ff ff       	call   f0100e0c <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102068:	83 c4 0c             	add    $0xc,%esp
f010206b:	6a 01                	push   $0x1
f010206d:	6a 00                	push   $0x0
f010206f:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0102075:	e8 f4 ed ff ff       	call   f0100e6e <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010207a:	89 fa                	mov    %edi,%edx
f010207c:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0102082:	c1 fa 03             	sar    $0x3,%edx
f0102085:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102088:	89 d0                	mov    %edx,%eax
f010208a:	c1 e8 0c             	shr    $0xc,%eax
f010208d:	83 c4 10             	add    $0x10,%esp
f0102090:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0102096:	72 12                	jb     f01020aa <mem_init+0x102a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102098:	52                   	push   %edx
f0102099:	68 24 4b 10 f0       	push   $0xf0104b24
f010209e:	6a 56                	push   $0x56
f01020a0:	68 eb 52 10 f0       	push   $0xf01052eb
f01020a5:	e8 f6 df ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f01020aa:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020b3:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020b9:	f6 00 01             	testb  $0x1,(%eax)
f01020bc:	74 19                	je     f01020d7 <mem_init+0x1057>
f01020be:	68 75 55 10 f0       	push   $0xf0105575
f01020c3:	68 05 53 10 f0       	push   $0xf0105305
f01020c8:	68 cf 03 00 00       	push   $0x3cf
f01020cd:	68 cd 52 10 f0       	push   $0xf01052cd
f01020d2:	e8 c9 df ff ff       	call   f01000a0 <_panic>
f01020d7:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020da:	39 c2                	cmp    %eax,%edx
f01020dc:	75 db                	jne    f01020b9 <mem_init+0x1039>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020de:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f01020e3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020e9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020ec:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020f2:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01020f5:	89 3d 7c ff 16 f0    	mov    %edi,0xf016ff7c

	// free the pages we took
	page_free(pp0);
f01020fb:	83 ec 0c             	sub    $0xc,%esp
f01020fe:	50                   	push   %eax
f01020ff:	e8 08 ed ff ff       	call   f0100e0c <page_free>
	page_free(pp1);
f0102104:	89 34 24             	mov    %esi,(%esp)
f0102107:	e8 00 ed ff ff       	call   f0100e0c <page_free>
	page_free(pp2);
f010210c:	89 1c 24             	mov    %ebx,(%esp)
f010210f:	e8 f8 ec ff ff       	call   f0100e0c <page_free>

	cprintf("check_page() succeeded!\n");
f0102114:	c7 04 24 8c 55 10 f0 	movl   $0xf010558c,(%esp)
f010211b:	e8 01 0e 00 00       	call   f0102f21 <cprintf>
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
//	boot_map_region(kern_pgdir,PADDR(pages),PTSIZE,PADDR(pages),PTE_W);
	
	boot_map_region(kern_pgdir,UPAGES,ROUNDUP(npages*sizeof(struct PageInfo),PGSIZE),PADDR(pages),PTE_U);
f0102120:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102125:	83 c4 10             	add    $0x10,%esp
f0102128:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010212d:	77 15                	ja     f0102144 <mem_init+0x10c4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010212f:	50                   	push   %eax
f0102130:	68 48 4b 10 f0       	push   $0xf0104b48
f0102135:	68 d8 00 00 00       	push   $0xd8
f010213a:	68 cd 52 10 f0       	push   $0xf01052cd
f010213f:	e8 5c df ff ff       	call   f01000a0 <_panic>
f0102144:	8b 15 44 0c 17 f0    	mov    0xf0170c44,%edx
f010214a:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102151:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102157:	83 ec 08             	sub    $0x8,%esp
f010215a:	6a 04                	push   $0x4
f010215c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102161:	50                   	push   %eax
f0102162:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102167:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f010216c:	e8 90 ed ff ff       	call   f0100f01 <boot_map_region>
	boot_map_region(kern_pgdir,(uintptr_t)pages,ROUNDUP(npages*sizeof(struct PageInfo),PGSIZE),PADDR(pages),PTE_W);
f0102171:	8b 15 4c 0c 17 f0    	mov    0xf0170c4c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102177:	83 c4 10             	add    $0x10,%esp
f010217a:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102180:	77 15                	ja     f0102197 <mem_init+0x1117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102182:	52                   	push   %edx
f0102183:	68 48 4b 10 f0       	push   $0xf0104b48
f0102188:	68 d9 00 00 00       	push   $0xd9
f010218d:	68 cd 52 10 f0       	push   $0xf01052cd
f0102192:	e8 09 df ff ff       	call   f01000a0 <_panic>
f0102197:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f010219c:	8d 0c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ecx
f01021a3:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01021a9:	83 ec 08             	sub    $0x8,%esp
f01021ac:	6a 02                	push   $0x2
f01021ae:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f01021b4:	50                   	push   %eax
f01021b5:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f01021ba:	e8 42 ed ff ff       	call   f0100f01 <boot_map_region>
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
//	boot_map_region(kern_pgdir,PADDR(envs),PTSIZE,PADDR(envs),PTE_W);
	boot_map_region(kern_pgdir,UENVS,ROUNDUP(NENV*sizeof(struct Env),PGSIZE),PADDR(envs),PTE_U);
f01021bf:	a1 84 ff 16 f0       	mov    0xf016ff84,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021c4:	83 c4 10             	add    $0x10,%esp
f01021c7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021cc:	77 15                	ja     f01021e3 <mem_init+0x1163>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021ce:	50                   	push   %eax
f01021cf:	68 48 4b 10 f0       	push   $0xf0104b48
f01021d4:	68 e5 00 00 00       	push   $0xe5
f01021d9:	68 cd 52 10 f0       	push   $0xf01052cd
f01021de:	e8 bd de ff ff       	call   f01000a0 <_panic>
f01021e3:	83 ec 08             	sub    $0x8,%esp
f01021e6:	6a 04                	push   $0x4
f01021e8:	05 00 00 00 10       	add    $0x10000000,%eax
f01021ed:	50                   	push   %eax
f01021ee:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01021f3:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021f8:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f01021fd:	e8 ff ec ff ff       	call   f0100f01 <boot_map_region>
	boot_map_region(kern_pgdir,(uintptr_t)envs,ROUNDUP(NENV*sizeof(struct Env),PGSIZE),PADDR(envs),PTE_W);
f0102202:	8b 15 84 ff 16 f0    	mov    0xf016ff84,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102208:	83 c4 10             	add    $0x10,%esp
f010220b:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102211:	77 15                	ja     f0102228 <mem_init+0x11a8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102213:	52                   	push   %edx
f0102214:	68 48 4b 10 f0       	push   $0xf0104b48
f0102219:	68 e6 00 00 00       	push   $0xe6
f010221e:	68 cd 52 10 f0       	push   $0xf01052cd
f0102223:	e8 78 de ff ff       	call   f01000a0 <_panic>
f0102228:	83 ec 08             	sub    $0x8,%esp
f010222b:	6a 02                	push   $0x2
f010222d:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f0102233:	50                   	push   %eax
f0102234:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102239:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f010223e:	e8 be ec ff ff       	call   f0100f01 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102243:	83 c4 10             	add    $0x10,%esp
f0102246:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f010224b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102250:	77 15                	ja     f0102267 <mem_init+0x11e7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102252:	50                   	push   %eax
f0102253:	68 48 4b 10 f0       	push   $0xf0104b48
f0102258:	68 f5 00 00 00       	push   $0xf5
f010225d:	68 cd 52 10 f0       	push   $0xf01052cd
f0102262:	e8 39 de ff ff       	call   f01000a0 <_panic>
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	

	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102267:	83 ec 08             	sub    $0x8,%esp
f010226a:	6a 02                	push   $0x2
f010226c:	68 00 00 11 00       	push   $0x110000
f0102271:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102276:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010227b:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0102280:	e8 7c ec ff ff       	call   f0100f01 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff-KERNBASE,0,PTE_W);
f0102285:	83 c4 08             	add    $0x8,%esp
f0102288:	6a 02                	push   $0x2
f010228a:	6a 00                	push   $0x0
f010228c:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102291:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102296:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f010229b:	e8 61 ec ff ff       	call   f0100f01 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01022a0:	8b 1d 48 0c 17 f0    	mov    0xf0170c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01022a6:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f01022ab:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01022ae:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01022b5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01022ba:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022bd:	8b 3d 4c 0c 17 f0    	mov    0xf0170c4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022c3:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01022c6:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022c9:	be 00 00 00 00       	mov    $0x0,%esi
f01022ce:	eb 55                	jmp    f0102325 <mem_init+0x12a5>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022d0:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f01022d6:	89 d8                	mov    %ebx,%eax
f01022d8:	e8 85 e6 ff ff       	call   f0100962 <check_va2pa>
f01022dd:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01022e4:	77 15                	ja     f01022fb <mem_init+0x127b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022e6:	57                   	push   %edi
f01022e7:	68 48 4b 10 f0       	push   $0xf0104b48
f01022ec:	68 0b 03 00 00       	push   $0x30b
f01022f1:	68 cd 52 10 f0       	push   $0xf01052cd
f01022f6:	e8 a5 dd ff ff       	call   f01000a0 <_panic>
f01022fb:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102302:	39 d0                	cmp    %edx,%eax
f0102304:	74 19                	je     f010231f <mem_init+0x129f>
f0102306:	68 08 51 10 f0       	push   $0xf0105108
f010230b:	68 05 53 10 f0       	push   $0xf0105305
f0102310:	68 0b 03 00 00       	push   $0x30b
f0102315:	68 cd 52 10 f0       	push   $0xf01052cd
f010231a:	e8 81 dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010231f:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102325:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102328:	77 a6                	ja     f01022d0 <mem_init+0x1250>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010232a:	8b 3d 84 ff 16 f0    	mov    0xf016ff84,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102330:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102333:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102338:	89 f2                	mov    %esi,%edx
f010233a:	89 d8                	mov    %ebx,%eax
f010233c:	e8 21 e6 ff ff       	call   f0100962 <check_va2pa>
f0102341:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102348:	77 15                	ja     f010235f <mem_init+0x12df>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010234a:	57                   	push   %edi
f010234b:	68 48 4b 10 f0       	push   $0xf0104b48
f0102350:	68 10 03 00 00       	push   $0x310
f0102355:	68 cd 52 10 f0       	push   $0xf01052cd
f010235a:	e8 41 dd ff ff       	call   f01000a0 <_panic>
f010235f:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102366:	39 d0                	cmp    %edx,%eax
f0102368:	74 19                	je     f0102383 <mem_init+0x1303>
f010236a:	68 3c 51 10 f0       	push   $0xf010513c
f010236f:	68 05 53 10 f0       	push   $0xf0105305
f0102374:	68 10 03 00 00       	push   $0x310
f0102379:	68 cd 52 10 f0       	push   $0xf01052cd
f010237e:	e8 1d dd ff ff       	call   f01000a0 <_panic>
f0102383:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102389:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f010238f:	75 a7                	jne    f0102338 <mem_init+0x12b8>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102391:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102394:	c1 e7 0c             	shl    $0xc,%edi
f0102397:	be 00 00 00 00       	mov    $0x0,%esi
f010239c:	eb 30                	jmp    f01023ce <mem_init+0x134e>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010239e:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f01023a4:	89 d8                	mov    %ebx,%eax
f01023a6:	e8 b7 e5 ff ff       	call   f0100962 <check_va2pa>
f01023ab:	39 c6                	cmp    %eax,%esi
f01023ad:	74 19                	je     f01023c8 <mem_init+0x1348>
f01023af:	68 70 51 10 f0       	push   $0xf0105170
f01023b4:	68 05 53 10 f0       	push   $0xf0105305
f01023b9:	68 14 03 00 00       	push   $0x314
f01023be:	68 cd 52 10 f0       	push   $0xf01052cd
f01023c3:	e8 d8 dc ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01023c8:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01023ce:	39 fe                	cmp    %edi,%esi
f01023d0:	72 cc                	jb     f010239e <mem_init+0x131e>
f01023d2:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01023d7:	89 f2                	mov    %esi,%edx
f01023d9:	89 d8                	mov    %ebx,%eax
f01023db:	e8 82 e5 ff ff       	call   f0100962 <check_va2pa>
f01023e0:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f01023e6:	39 c2                	cmp    %eax,%edx
f01023e8:	74 19                	je     f0102403 <mem_init+0x1383>
f01023ea:	68 98 51 10 f0       	push   $0xf0105198
f01023ef:	68 05 53 10 f0       	push   $0xf0105305
f01023f4:	68 18 03 00 00       	push   $0x318
f01023f9:	68 cd 52 10 f0       	push   $0xf01052cd
f01023fe:	e8 9d dc ff ff       	call   f01000a0 <_panic>
f0102403:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102409:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f010240f:	75 c6                	jne    f01023d7 <mem_init+0x1357>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102411:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102416:	89 d8                	mov    %ebx,%eax
f0102418:	e8 45 e5 ff ff       	call   f0100962 <check_va2pa>
f010241d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102420:	74 51                	je     f0102473 <mem_init+0x13f3>
f0102422:	68 e0 51 10 f0       	push   $0xf01051e0
f0102427:	68 05 53 10 f0       	push   $0xf0105305
f010242c:	68 19 03 00 00       	push   $0x319
f0102431:	68 cd 52 10 f0       	push   $0xf01052cd
f0102436:	e8 65 dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010243b:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102440:	72 36                	jb     f0102478 <mem_init+0x13f8>
f0102442:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102447:	76 07                	jbe    f0102450 <mem_init+0x13d0>
f0102449:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010244e:	75 28                	jne    f0102478 <mem_init+0x13f8>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102450:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102454:	0f 85 83 00 00 00    	jne    f01024dd <mem_init+0x145d>
f010245a:	68 a5 55 10 f0       	push   $0xf01055a5
f010245f:	68 05 53 10 f0       	push   $0xf0105305
f0102464:	68 22 03 00 00       	push   $0x322
f0102469:	68 cd 52 10 f0       	push   $0xf01052cd
f010246e:	e8 2d dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102473:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102478:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010247d:	76 3f                	jbe    f01024be <mem_init+0x143e>
				assert(pgdir[i] & PTE_P);
f010247f:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102482:	f6 c2 01             	test   $0x1,%dl
f0102485:	75 19                	jne    f01024a0 <mem_init+0x1420>
f0102487:	68 a5 55 10 f0       	push   $0xf01055a5
f010248c:	68 05 53 10 f0       	push   $0xf0105305
f0102491:	68 26 03 00 00       	push   $0x326
f0102496:	68 cd 52 10 f0       	push   $0xf01052cd
f010249b:	e8 00 dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01024a0:	f6 c2 02             	test   $0x2,%dl
f01024a3:	75 38                	jne    f01024dd <mem_init+0x145d>
f01024a5:	68 b6 55 10 f0       	push   $0xf01055b6
f01024aa:	68 05 53 10 f0       	push   $0xf0105305
f01024af:	68 27 03 00 00       	push   $0x327
f01024b4:	68 cd 52 10 f0       	push   $0xf01052cd
f01024b9:	e8 e2 db ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f01024be:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01024c2:	74 19                	je     f01024dd <mem_init+0x145d>
f01024c4:	68 c7 55 10 f0       	push   $0xf01055c7
f01024c9:	68 05 53 10 f0       	push   $0xf0105305
f01024ce:	68 29 03 00 00       	push   $0x329
f01024d3:	68 cd 52 10 f0       	push   $0xf01052cd
f01024d8:	e8 c3 db ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01024dd:	83 c0 01             	add    $0x1,%eax
f01024e0:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01024e5:	0f 86 50 ff ff ff    	jbe    f010243b <mem_init+0x13bb>
				assert(pgdir[i] == 0);
				
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01024eb:	83 ec 0c             	sub    $0xc,%esp
f01024ee:	68 10 52 10 f0       	push   $0xf0105210
f01024f3:	e8 29 0a 00 00       	call   f0102f21 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024f8:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024fd:	83 c4 10             	add    $0x10,%esp
f0102500:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102505:	77 15                	ja     f010251c <mem_init+0x149c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102507:	50                   	push   %eax
f0102508:	68 48 4b 10 f0       	push   $0xf0104b48
f010250d:	68 0c 01 00 00       	push   $0x10c
f0102512:	68 cd 52 10 f0       	push   $0xf01052cd
f0102517:	e8 84 db ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010251c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102521:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102524:	b8 00 00 00 00       	mov    $0x0,%eax
f0102529:	e8 1c e5 ff ff       	call   f0100a4a <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010252e:	0f 20 c0             	mov    %cr0,%eax
f0102531:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102534:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102539:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010253c:	83 ec 0c             	sub    $0xc,%esp
f010253f:	6a 00                	push   $0x0
f0102541:	e8 56 e8 ff ff       	call   f0100d9c <page_alloc>
f0102546:	89 c3                	mov    %eax,%ebx
f0102548:	83 c4 10             	add    $0x10,%esp
f010254b:	85 c0                	test   %eax,%eax
f010254d:	75 19                	jne    f0102568 <mem_init+0x14e8>
f010254f:	68 c3 53 10 f0       	push   $0xf01053c3
f0102554:	68 05 53 10 f0       	push   $0xf0105305
f0102559:	68 ea 03 00 00       	push   $0x3ea
f010255e:	68 cd 52 10 f0       	push   $0xf01052cd
f0102563:	e8 38 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102568:	83 ec 0c             	sub    $0xc,%esp
f010256b:	6a 00                	push   $0x0
f010256d:	e8 2a e8 ff ff       	call   f0100d9c <page_alloc>
f0102572:	89 c7                	mov    %eax,%edi
f0102574:	83 c4 10             	add    $0x10,%esp
f0102577:	85 c0                	test   %eax,%eax
f0102579:	75 19                	jne    f0102594 <mem_init+0x1514>
f010257b:	68 d9 53 10 f0       	push   $0xf01053d9
f0102580:	68 05 53 10 f0       	push   $0xf0105305
f0102585:	68 eb 03 00 00       	push   $0x3eb
f010258a:	68 cd 52 10 f0       	push   $0xf01052cd
f010258f:	e8 0c db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102594:	83 ec 0c             	sub    $0xc,%esp
f0102597:	6a 00                	push   $0x0
f0102599:	e8 fe e7 ff ff       	call   f0100d9c <page_alloc>
f010259e:	89 c6                	mov    %eax,%esi
f01025a0:	83 c4 10             	add    $0x10,%esp
f01025a3:	85 c0                	test   %eax,%eax
f01025a5:	75 19                	jne    f01025c0 <mem_init+0x1540>
f01025a7:	68 ef 53 10 f0       	push   $0xf01053ef
f01025ac:	68 05 53 10 f0       	push   $0xf0105305
f01025b1:	68 ec 03 00 00       	push   $0x3ec
f01025b6:	68 cd 52 10 f0       	push   $0xf01052cd
f01025bb:	e8 e0 da ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f01025c0:	83 ec 0c             	sub    $0xc,%esp
f01025c3:	53                   	push   %ebx
f01025c4:	e8 43 e8 ff ff       	call   f0100e0c <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025c9:	89 f8                	mov    %edi,%eax
f01025cb:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f01025d1:	c1 f8 03             	sar    $0x3,%eax
f01025d4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025d7:	89 c2                	mov    %eax,%edx
f01025d9:	c1 ea 0c             	shr    $0xc,%edx
f01025dc:	83 c4 10             	add    $0x10,%esp
f01025df:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f01025e5:	72 12                	jb     f01025f9 <mem_init+0x1579>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025e7:	50                   	push   %eax
f01025e8:	68 24 4b 10 f0       	push   $0xf0104b24
f01025ed:	6a 56                	push   $0x56
f01025ef:	68 eb 52 10 f0       	push   $0xf01052eb
f01025f4:	e8 a7 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025f9:	83 ec 04             	sub    $0x4,%esp
f01025fc:	68 00 10 00 00       	push   $0x1000
f0102601:	6a 01                	push   $0x1
f0102603:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102608:	50                   	push   %eax
f0102609:	e8 5b 1b 00 00       	call   f0104169 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010260e:	89 f0                	mov    %esi,%eax
f0102610:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0102616:	c1 f8 03             	sar    $0x3,%eax
f0102619:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010261c:	89 c2                	mov    %eax,%edx
f010261e:	c1 ea 0c             	shr    $0xc,%edx
f0102621:	83 c4 10             	add    $0x10,%esp
f0102624:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f010262a:	72 12                	jb     f010263e <mem_init+0x15be>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010262c:	50                   	push   %eax
f010262d:	68 24 4b 10 f0       	push   $0xf0104b24
f0102632:	6a 56                	push   $0x56
f0102634:	68 eb 52 10 f0       	push   $0xf01052eb
f0102639:	e8 62 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010263e:	83 ec 04             	sub    $0x4,%esp
f0102641:	68 00 10 00 00       	push   $0x1000
f0102646:	6a 02                	push   $0x2
f0102648:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010264d:	50                   	push   %eax
f010264e:	e8 16 1b 00 00       	call   f0104169 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102653:	6a 02                	push   $0x2
f0102655:	68 00 10 00 00       	push   $0x1000
f010265a:	57                   	push   %edi
f010265b:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0102661:	e8 90 e9 ff ff       	call   f0100ff6 <page_insert>
	assert(pp1->pp_ref == 1);
f0102666:	83 c4 20             	add    $0x20,%esp
f0102669:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010266e:	74 19                	je     f0102689 <mem_init+0x1609>
f0102670:	68 c0 54 10 f0       	push   $0xf01054c0
f0102675:	68 05 53 10 f0       	push   $0xf0105305
f010267a:	68 f1 03 00 00       	push   $0x3f1
f010267f:	68 cd 52 10 f0       	push   $0xf01052cd
f0102684:	e8 17 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102689:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102690:	01 01 01 
f0102693:	74 19                	je     f01026ae <mem_init+0x162e>
f0102695:	68 30 52 10 f0       	push   $0xf0105230
f010269a:	68 05 53 10 f0       	push   $0xf0105305
f010269f:	68 f2 03 00 00       	push   $0x3f2
f01026a4:	68 cd 52 10 f0       	push   $0xf01052cd
f01026a9:	e8 f2 d9 ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01026ae:	6a 02                	push   $0x2
f01026b0:	68 00 10 00 00       	push   $0x1000
f01026b5:	56                   	push   %esi
f01026b6:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01026bc:	e8 35 e9 ff ff       	call   f0100ff6 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01026c1:	83 c4 10             	add    $0x10,%esp
f01026c4:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01026cb:	02 02 02 
f01026ce:	74 19                	je     f01026e9 <mem_init+0x1669>
f01026d0:	68 54 52 10 f0       	push   $0xf0105254
f01026d5:	68 05 53 10 f0       	push   $0xf0105305
f01026da:	68 f4 03 00 00       	push   $0x3f4
f01026df:	68 cd 52 10 f0       	push   $0xf01052cd
f01026e4:	e8 b7 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01026e9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01026ee:	74 19                	je     f0102709 <mem_init+0x1689>
f01026f0:	68 e2 54 10 f0       	push   $0xf01054e2
f01026f5:	68 05 53 10 f0       	push   $0xf0105305
f01026fa:	68 f5 03 00 00       	push   $0x3f5
f01026ff:	68 cd 52 10 f0       	push   $0xf01052cd
f0102704:	e8 97 d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0102709:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010270e:	74 19                	je     f0102729 <mem_init+0x16a9>
f0102710:	68 4c 55 10 f0       	push   $0xf010554c
f0102715:	68 05 53 10 f0       	push   $0xf0105305
f010271a:	68 f6 03 00 00       	push   $0x3f6
f010271f:	68 cd 52 10 f0       	push   $0xf01052cd
f0102724:	e8 77 d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102729:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102730:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102733:	89 f0                	mov    %esi,%eax
f0102735:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f010273b:	c1 f8 03             	sar    $0x3,%eax
f010273e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102741:	89 c2                	mov    %eax,%edx
f0102743:	c1 ea 0c             	shr    $0xc,%edx
f0102746:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f010274c:	72 12                	jb     f0102760 <mem_init+0x16e0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010274e:	50                   	push   %eax
f010274f:	68 24 4b 10 f0       	push   $0xf0104b24
f0102754:	6a 56                	push   $0x56
f0102756:	68 eb 52 10 f0       	push   $0xf01052eb
f010275b:	e8 40 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102760:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102767:	03 03 03 
f010276a:	74 19                	je     f0102785 <mem_init+0x1705>
f010276c:	68 78 52 10 f0       	push   $0xf0105278
f0102771:	68 05 53 10 f0       	push   $0xf0105305
f0102776:	68 f8 03 00 00       	push   $0x3f8
f010277b:	68 cd 52 10 f0       	push   $0xf01052cd
f0102780:	e8 1b d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102785:	83 ec 08             	sub    $0x8,%esp
f0102788:	68 00 10 00 00       	push   $0x1000
f010278d:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0102793:	e8 10 e8 ff ff       	call   f0100fa8 <page_remove>
	assert(pp2->pp_ref == 0);
f0102798:	83 c4 10             	add    $0x10,%esp
f010279b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01027a0:	74 19                	je     f01027bb <mem_init+0x173b>
f01027a2:	68 1a 55 10 f0       	push   $0xf010551a
f01027a7:	68 05 53 10 f0       	push   $0xf0105305
f01027ac:	68 fa 03 00 00       	push   $0x3fa
f01027b1:	68 cd 52 10 f0       	push   $0xf01052cd
f01027b6:	e8 e5 d8 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01027bb:	8b 0d 48 0c 17 f0    	mov    0xf0170c48,%ecx
f01027c1:	8b 11                	mov    (%ecx),%edx
f01027c3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01027c9:	89 d8                	mov    %ebx,%eax
f01027cb:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f01027d1:	c1 f8 03             	sar    $0x3,%eax
f01027d4:	c1 e0 0c             	shl    $0xc,%eax
f01027d7:	39 c2                	cmp    %eax,%edx
f01027d9:	74 19                	je     f01027f4 <mem_init+0x1774>
f01027db:	68 88 4d 10 f0       	push   $0xf0104d88
f01027e0:	68 05 53 10 f0       	push   $0xf0105305
f01027e5:	68 fd 03 00 00       	push   $0x3fd
f01027ea:	68 cd 52 10 f0       	push   $0xf01052cd
f01027ef:	e8 ac d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01027f4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01027fa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01027ff:	74 19                	je     f010281a <mem_init+0x179a>
f0102801:	68 d1 54 10 f0       	push   $0xf01054d1
f0102806:	68 05 53 10 f0       	push   $0xf0105305
f010280b:	68 ff 03 00 00       	push   $0x3ff
f0102810:	68 cd 52 10 f0       	push   $0xf01052cd
f0102815:	e8 86 d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f010281a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102820:	83 ec 0c             	sub    $0xc,%esp
f0102823:	53                   	push   %ebx
f0102824:	e8 e3 e5 ff ff       	call   f0100e0c <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102829:	c7 04 24 a4 52 10 f0 	movl   $0xf01052a4,(%esp)
f0102830:	e8 ec 06 00 00       	call   f0102f21 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102835:	83 c4 10             	add    $0x10,%esp
f0102838:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010283b:	5b                   	pop    %ebx
f010283c:	5e                   	pop    %esi
f010283d:	5f                   	pop    %edi
f010283e:	5d                   	pop    %ebp
f010283f:	c3                   	ret    

f0102840 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102840:	55                   	push   %ebp
f0102841:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102843:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102846:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102849:	5d                   	pop    %ebp
f010284a:	c3                   	ret    

f010284b <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f010284b:	55                   	push   %ebp
f010284c:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f010284e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102853:	5d                   	pop    %ebp
f0102854:	c3                   	ret    

f0102855 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102855:	55                   	push   %ebp
f0102856:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f0102858:	5d                   	pop    %ebp
f0102859:	c3                   	ret    

f010285a <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010285a:	55                   	push   %ebp
f010285b:	89 e5                	mov    %esp,%ebp
f010285d:	57                   	push   %edi
f010285e:	56                   	push   %esi
f010285f:	53                   	push   %ebx
f0102860:	83 ec 0c             	sub    $0xc,%esp
f0102863:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	void* zaciatok = ROUNDDOWN(va,PGSIZE);
f0102865:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010286b:	89 d3                	mov    %edx,%ebx
	void* koniec = ROUNDUP(zaciatok+len,PGSIZE);
f010286d:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102874:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for(void* i=zaciatok;i<koniec;i+=PGSIZE)
f010287a:	eb 3d                	jmp    f01028b9 <region_alloc+0x5f>
	{
		struct PageInfo* pp=page_alloc(0);
f010287c:	83 ec 0c             	sub    $0xc,%esp
f010287f:	6a 00                	push   $0x0
f0102881:	e8 16 e5 ff ff       	call   f0100d9c <page_alloc>
		if(!pp)panic("page alloc sa nepodarilo");
f0102886:	83 c4 10             	add    $0x10,%esp
f0102889:	85 c0                	test   %eax,%eax
f010288b:	75 17                	jne    f01028a4 <region_alloc+0x4a>
f010288d:	83 ec 04             	sub    $0x4,%esp
f0102890:	68 d5 55 10 f0       	push   $0xf01055d5
f0102895:	68 15 01 00 00       	push   $0x115
f010289a:	68 ee 55 10 f0       	push   $0xf01055ee
f010289f:	e8 fc d7 ff ff       	call   f01000a0 <_panic>
		page_insert(e->env_pgdir,pp,i,PTE_P|PTE_W|PTE_U);
f01028a4:	6a 07                	push   $0x7
f01028a6:	53                   	push   %ebx
f01028a7:	50                   	push   %eax
f01028a8:	ff 77 5c             	pushl  0x5c(%edi)
f01028ab:	e8 46 e7 ff ff       	call   f0100ff6 <page_insert>
{
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	void* zaciatok = ROUNDDOWN(va,PGSIZE);
	void* koniec = ROUNDUP(zaciatok+len,PGSIZE);
	for(void* i=zaciatok;i<koniec;i+=PGSIZE)
f01028b0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028b6:	83 c4 10             	add    $0x10,%esp
f01028b9:	39 f3                	cmp    %esi,%ebx
f01028bb:	72 bf                	jb     f010287c <region_alloc+0x22>
	}
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f01028bd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028c0:	5b                   	pop    %ebx
f01028c1:	5e                   	pop    %esi
f01028c2:	5f                   	pop    %edi
f01028c3:	5d                   	pop    %ebp
f01028c4:	c3                   	ret    

f01028c5 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01028c5:	55                   	push   %ebp
f01028c6:	89 e5                	mov    %esp,%ebp
f01028c8:	8b 55 08             	mov    0x8(%ebp),%edx
f01028cb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01028ce:	85 d2                	test   %edx,%edx
f01028d0:	75 11                	jne    f01028e3 <envid2env+0x1e>
		*env_store = curenv;
f01028d2:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f01028d7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028da:	89 01                	mov    %eax,(%ecx)
		return 0;
f01028dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01028e1:	eb 5e                	jmp    f0102941 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01028e3:	89 d0                	mov    %edx,%eax
f01028e5:	25 ff 03 00 00       	and    $0x3ff,%eax
f01028ea:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01028ed:	c1 e0 05             	shl    $0x5,%eax
f01028f0:	03 05 84 ff 16 f0    	add    0xf016ff84,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01028f6:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01028fa:	74 05                	je     f0102901 <envid2env+0x3c>
f01028fc:	3b 50 48             	cmp    0x48(%eax),%edx
f01028ff:	74 10                	je     f0102911 <envid2env+0x4c>
		*env_store = 0;
f0102901:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102904:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010290a:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010290f:	eb 30                	jmp    f0102941 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102911:	84 c9                	test   %cl,%cl
f0102913:	74 22                	je     f0102937 <envid2env+0x72>
f0102915:	8b 15 80 ff 16 f0    	mov    0xf016ff80,%edx
f010291b:	39 d0                	cmp    %edx,%eax
f010291d:	74 18                	je     f0102937 <envid2env+0x72>
f010291f:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102922:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102925:	74 10                	je     f0102937 <envid2env+0x72>
		*env_store = 0;
f0102927:	8b 45 0c             	mov    0xc(%ebp),%eax
f010292a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102930:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102935:	eb 0a                	jmp    f0102941 <envid2env+0x7c>
	}

	*env_store = e;
f0102937:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010293a:	89 01                	mov    %eax,(%ecx)
	return 0;
f010293c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102941:	5d                   	pop    %ebp
f0102942:	c3                   	ret    

f0102943 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102943:	55                   	push   %ebp
f0102944:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102946:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f010294b:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f010294e:	b8 23 00 00 00       	mov    $0x23,%eax
f0102953:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102955:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102957:	b8 10 00 00 00       	mov    $0x10,%eax
f010295c:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f010295e:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102960:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102962:	ea 69 29 10 f0 08 00 	ljmp   $0x8,$0xf0102969
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102969:	b8 00 00 00 00       	mov    $0x0,%eax
f010296e:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102971:	5d                   	pop    %ebp
f0102972:	c3                   	ret    

f0102973 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102973:	55                   	push   %ebp
f0102974:	89 e5                	mov    %esp,%ebp
f0102976:	56                   	push   %esi
f0102977:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	for(int i=NENV-1;i>=0;i--)
	{
		envs[i].env_id=0;
f0102978:	8b 35 84 ff 16 f0    	mov    0xf016ff84,%esi
f010297e:	8b 15 88 ff 16 f0    	mov    0xf016ff88,%edx
f0102984:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f010298a:	8d 5e a0             	lea    -0x60(%esi),%ebx
f010298d:	89 c1                	mov    %eax,%ecx
f010298f:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link=env_free_list;
f0102996:	89 50 44             	mov    %edx,0x44(%eax)
f0102999:	83 e8 60             	sub    $0x60,%eax
		env_free_list=&envs[i];
f010299c:	89 ca                	mov    %ecx,%edx
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	for(int i=NENV-1;i>=0;i--)
f010299e:	39 d8                	cmp    %ebx,%eax
f01029a0:	75 eb                	jne    f010298d <env_init+0x1a>
f01029a2:	89 35 88 ff 16 f0    	mov    %esi,0xf016ff88
		envs[i].env_id=0;
		envs[i].env_link=env_free_list;
		env_free_list=&envs[i];
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f01029a8:	e8 96 ff ff ff       	call   f0102943 <env_init_percpu>
}
f01029ad:	5b                   	pop    %ebx
f01029ae:	5e                   	pop    %esi
f01029af:	5d                   	pop    %ebp
f01029b0:	c3                   	ret    

f01029b1 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01029b1:	55                   	push   %ebp
f01029b2:	89 e5                	mov    %esp,%ebp
f01029b4:	53                   	push   %ebx
f01029b5:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01029b8:	8b 1d 88 ff 16 f0    	mov    0xf016ff88,%ebx
f01029be:	85 db                	test   %ebx,%ebx
f01029c0:	0f 84 43 01 00 00    	je     f0102b09 <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01029c6:	83 ec 0c             	sub    $0xc,%esp
f01029c9:	6a 01                	push   $0x1
f01029cb:	e8 cc e3 ff ff       	call   f0100d9c <page_alloc>
f01029d0:	83 c4 10             	add    $0x10,%esp
f01029d3:	85 c0                	test   %eax,%eax
f01029d5:	0f 84 35 01 00 00    	je     f0102b10 <env_alloc+0x15f>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f01029db:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029e0:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f01029e6:	c1 f8 03             	sar    $0x3,%eax
f01029e9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029ec:	89 c2                	mov    %eax,%edx
f01029ee:	c1 ea 0c             	shr    $0xc,%edx
f01029f1:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f01029f7:	72 12                	jb     f0102a0b <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029f9:	50                   	push   %eax
f01029fa:	68 24 4b 10 f0       	push   $0xf0104b24
f01029ff:	6a 56                	push   $0x56
f0102a01:	68 eb 52 10 f0       	push   $0xf01052eb
f0102a06:	e8 95 d6 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102a0b:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t*) page2kva(p);
f0102a10:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f0102a13:	83 ec 04             	sub    $0x4,%esp
f0102a16:	68 00 10 00 00       	push   $0x1000
f0102a1b:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0102a21:	50                   	push   %eax
f0102a22:	e8 f7 17 00 00       	call   f010421e <memcpy>
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102a27:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a2a:	83 c4 10             	add    $0x10,%esp
f0102a2d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a32:	77 15                	ja     f0102a49 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a34:	50                   	push   %eax
f0102a35:	68 48 4b 10 f0       	push   $0xf0104b48
f0102a3a:	68 c0 00 00 00       	push   $0xc0
f0102a3f:	68 ee 55 10 f0       	push   $0xf01055ee
f0102a44:	e8 57 d6 ff ff       	call   f01000a0 <_panic>
f0102a49:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102a4f:	83 ca 05             	or     $0x5,%edx
f0102a52:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102a58:	8b 43 48             	mov    0x48(%ebx),%eax
f0102a5b:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102a60:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102a65:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a6a:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102a6d:	89 da                	mov    %ebx,%edx
f0102a6f:	2b 15 84 ff 16 f0    	sub    0xf016ff84,%edx
f0102a75:	c1 fa 05             	sar    $0x5,%edx
f0102a78:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a7e:	09 d0                	or     %edx,%eax
f0102a80:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a83:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a86:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a89:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a90:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a97:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a9e:	83 ec 04             	sub    $0x4,%esp
f0102aa1:	6a 44                	push   $0x44
f0102aa3:	6a 00                	push   $0x0
f0102aa5:	53                   	push   %ebx
f0102aa6:	e8 be 16 00 00       	call   f0104169 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102aab:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102ab1:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102ab7:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102abd:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102ac4:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102aca:	8b 43 44             	mov    0x44(%ebx),%eax
f0102acd:	a3 88 ff 16 f0       	mov    %eax,0xf016ff88
	*newenv_store = e;
f0102ad2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ad5:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102ad7:	8b 53 48             	mov    0x48(%ebx),%edx
f0102ada:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f0102adf:	83 c4 10             	add    $0x10,%esp
f0102ae2:	85 c0                	test   %eax,%eax
f0102ae4:	74 05                	je     f0102aeb <env_alloc+0x13a>
f0102ae6:	8b 40 48             	mov    0x48(%eax),%eax
f0102ae9:	eb 05                	jmp    f0102af0 <env_alloc+0x13f>
f0102aeb:	b8 00 00 00 00       	mov    $0x0,%eax
f0102af0:	83 ec 04             	sub    $0x4,%esp
f0102af3:	52                   	push   %edx
f0102af4:	50                   	push   %eax
f0102af5:	68 f9 55 10 f0       	push   $0xf01055f9
f0102afa:	e8 22 04 00 00       	call   f0102f21 <cprintf>
	return 0;
f0102aff:	83 c4 10             	add    $0x10,%esp
f0102b02:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b07:	eb 0c                	jmp    f0102b15 <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102b09:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102b0e:	eb 05                	jmp    f0102b15 <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102b10:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102b15:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102b18:	c9                   	leave  
f0102b19:	c3                   	ret    

f0102b1a <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102b1a:	55                   	push   %ebp
f0102b1b:	89 e5                	mov    %esp,%ebp
f0102b1d:	57                   	push   %edi
f0102b1e:	56                   	push   %esi
f0102b1f:	53                   	push   %ebx
f0102b20:	83 ec 34             	sub    $0x34,%esp
f0102b23:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r = env_alloc(&e,0);
f0102b26:	6a 00                	push   $0x0
f0102b28:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102b2b:	50                   	push   %eax
f0102b2c:	e8 80 fe ff ff       	call   f01029b1 <env_alloc>
	
	if(r<0)
f0102b31:	83 c4 10             	add    $0x10,%esp
f0102b34:	85 c0                	test   %eax,%eax
f0102b36:	79 15                	jns    f0102b4d <env_create+0x33>
		panic("env_alloc error: %e",r);
f0102b38:	50                   	push   %eax
f0102b39:	68 0e 56 10 f0       	push   $0xf010560e
f0102b3e:	68 80 01 00 00       	push   $0x180
f0102b43:	68 ee 55 10 f0       	push   $0xf01055ee
f0102b48:	e8 53 d5 ff ff       	call   f01000a0 <_panic>

	load_icode(e,binary);
f0102b4d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b50:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	struct Proghdr *ph,*eph;
	struct Elf *elf=(struct Elf*) binary;

	if(elf->e_magic!=ELF_MAGIC)
f0102b53:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102b59:	74 17                	je     f0102b72 <env_create+0x58>
		panic("Panic! Nie je to magicky elf!");
f0102b5b:	83 ec 04             	sub    $0x4,%esp
f0102b5e:	68 22 56 10 f0       	push   $0xf0105622
f0102b63:	68 58 01 00 00       	push   $0x158
f0102b68:	68 ee 55 10 f0       	push   $0xf01055ee
f0102b6d:	e8 2e d5 ff ff       	call   f01000a0 <_panic>
	
	ph = (struct Proghdr*) ((uint8_t*)elf + elf->e_phoff);
f0102b72:	89 fb                	mov    %edi,%ebx
f0102b74:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f0102b77:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102b7b:	c1 e6 05             	shl    $0x5,%esi
f0102b7e:	01 de                	add    %ebx,%esi
	lcr3(PADDR(e->env_pgdir));
f0102b80:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b83:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b86:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b8b:	77 15                	ja     f0102ba2 <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b8d:	50                   	push   %eax
f0102b8e:	68 48 4b 10 f0       	push   $0xf0104b48
f0102b93:	68 5c 01 00 00       	push   $0x15c
f0102b98:	68 ee 55 10 f0       	push   $0xf01055ee
f0102b9d:	e8 fe d4 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102ba2:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ba7:	0f 22 d8             	mov    %eax,%cr3
f0102baa:	eb 41                	jmp    f0102bed <env_create+0xd3>
	for(;ph < eph; ph++)
	{
		if(ph->p_type == ELF_PROG_LOAD)
f0102bac:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102baf:	75 39                	jne    f0102bea <env_create+0xd0>
		{
			region_alloc(e,(void*)ph->p_va,ph->p_memsz);
f0102bb1:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102bb4:	8b 53 08             	mov    0x8(%ebx),%edx
f0102bb7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102bba:	e8 9b fc ff ff       	call   f010285a <region_alloc>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
f0102bbf:	83 ec 04             	sub    $0x4,%esp
f0102bc2:	ff 73 10             	pushl  0x10(%ebx)
f0102bc5:	89 f8                	mov    %edi,%eax
f0102bc7:	03 43 04             	add    0x4(%ebx),%eax
f0102bca:	50                   	push   %eax
f0102bcb:	ff 73 08             	pushl  0x8(%ebx)
f0102bce:	e8 4b 16 00 00       	call   f010421e <memcpy>
			memset((void*)ph->p_va,0,ph->p_memsz - ph->p_filesz);
f0102bd3:	83 c4 0c             	add    $0xc,%esp
f0102bd6:	8b 43 14             	mov    0x14(%ebx),%eax
f0102bd9:	2b 43 10             	sub    0x10(%ebx),%eax
f0102bdc:	50                   	push   %eax
f0102bdd:	6a 00                	push   $0x0
f0102bdf:	ff 73 08             	pushl  0x8(%ebx)
f0102be2:	e8 82 15 00 00       	call   f0104169 <memset>
f0102be7:	83 c4 10             	add    $0x10,%esp
		panic("Panic! Nie je to magicky elf!");
	
	ph = (struct Proghdr*) ((uint8_t*)elf + elf->e_phoff);
	eph = ph + elf->e_phnum;
	lcr3(PADDR(e->env_pgdir));
	for(;ph < eph; ph++)
f0102bea:	83 c3 20             	add    $0x20,%ebx
f0102bed:	39 de                	cmp    %ebx,%esi
f0102bef:	77 bb                	ja     f0102bac <env_create+0x92>
			region_alloc(e,(void*)ph->p_va,ph->p_memsz);
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
			memset((void*)ph->p_va,0,ph->p_memsz - ph->p_filesz);
		}
	}
	lcr3(PADDR(kern_pgdir));
f0102bf1:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bf6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bfb:	77 15                	ja     f0102c12 <env_create+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bfd:	50                   	push   %eax
f0102bfe:	68 48 4b 10 f0       	push   $0xf0104b48
f0102c03:	68 66 01 00 00       	push   $0x166
f0102c08:	68 ee 55 10 f0       	push   $0xf01055ee
f0102c0d:	e8 8e d4 ff ff       	call   f01000a0 <_panic>
f0102c12:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c17:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	
	region_alloc(e,(void*)(USTACKTOP - PGSIZE),PGSIZE);
f0102c1a:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102c1f:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102c24:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102c27:	89 f0                	mov    %esi,%eax
f0102c29:	e8 2c fc ff ff       	call   f010285a <region_alloc>
	e->env_tf.tf_eip = elf->e_entry;
f0102c2e:	8b 47 18             	mov    0x18(%edi),%eax
f0102c31:	89 46 30             	mov    %eax,0x30(%esi)
	e->env_tf.tf_esp =(uintptr_t)(USTACKTOP);
f0102c34:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	
	if(r<0)
		panic("env_alloc error: %e",r);

	load_icode(e,binary);
	e->env_type = type;	
f0102c3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c3e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102c41:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102c44:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c47:	5b                   	pop    %ebx
f0102c48:	5e                   	pop    %esi
f0102c49:	5f                   	pop    %edi
f0102c4a:	5d                   	pop    %ebp
f0102c4b:	c3                   	ret    

f0102c4c <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102c4c:	55                   	push   %ebp
f0102c4d:	89 e5                	mov    %esp,%ebp
f0102c4f:	57                   	push   %edi
f0102c50:	56                   	push   %esi
f0102c51:	53                   	push   %ebx
f0102c52:	83 ec 1c             	sub    $0x1c,%esp
f0102c55:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102c58:	8b 15 80 ff 16 f0    	mov    0xf016ff80,%edx
f0102c5e:	39 fa                	cmp    %edi,%edx
f0102c60:	75 29                	jne    f0102c8b <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102c62:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c67:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c6c:	77 15                	ja     f0102c83 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c6e:	50                   	push   %eax
f0102c6f:	68 48 4b 10 f0       	push   $0xf0104b48
f0102c74:	68 94 01 00 00       	push   $0x194
f0102c79:	68 ee 55 10 f0       	push   $0xf01055ee
f0102c7e:	e8 1d d4 ff ff       	call   f01000a0 <_panic>
f0102c83:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c88:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c8b:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c8e:	85 d2                	test   %edx,%edx
f0102c90:	74 05                	je     f0102c97 <env_free+0x4b>
f0102c92:	8b 42 48             	mov    0x48(%edx),%eax
f0102c95:	eb 05                	jmp    f0102c9c <env_free+0x50>
f0102c97:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c9c:	83 ec 04             	sub    $0x4,%esp
f0102c9f:	51                   	push   %ecx
f0102ca0:	50                   	push   %eax
f0102ca1:	68 40 56 10 f0       	push   $0xf0105640
f0102ca6:	e8 76 02 00 00       	call   f0102f21 <cprintf>
f0102cab:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102cae:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102cb5:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102cb8:	89 d0                	mov    %edx,%eax
f0102cba:	c1 e0 02             	shl    $0x2,%eax
f0102cbd:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102cc0:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102cc3:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102cc6:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102ccc:	0f 84 a8 00 00 00    	je     f0102d7a <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102cd2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cd8:	89 f0                	mov    %esi,%eax
f0102cda:	c1 e8 0c             	shr    $0xc,%eax
f0102cdd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ce0:	39 05 44 0c 17 f0    	cmp    %eax,0xf0170c44
f0102ce6:	77 15                	ja     f0102cfd <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ce8:	56                   	push   %esi
f0102ce9:	68 24 4b 10 f0       	push   $0xf0104b24
f0102cee:	68 a3 01 00 00       	push   $0x1a3
f0102cf3:	68 ee 55 10 f0       	push   $0xf01055ee
f0102cf8:	e8 a3 d3 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102cfd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d00:	c1 e0 16             	shl    $0x16,%eax
f0102d03:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d06:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102d0b:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102d12:	01 
f0102d13:	74 17                	je     f0102d2c <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d15:	83 ec 08             	sub    $0x8,%esp
f0102d18:	89 d8                	mov    %ebx,%eax
f0102d1a:	c1 e0 0c             	shl    $0xc,%eax
f0102d1d:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102d20:	50                   	push   %eax
f0102d21:	ff 77 5c             	pushl  0x5c(%edi)
f0102d24:	e8 7f e2 ff ff       	call   f0100fa8 <page_remove>
f0102d29:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d2c:	83 c3 01             	add    $0x1,%ebx
f0102d2f:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102d35:	75 d4                	jne    f0102d0b <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102d37:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d3a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d3d:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d44:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d47:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0102d4d:	72 14                	jb     f0102d63 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102d4f:	83 ec 04             	sub    $0x4,%esp
f0102d52:	68 54 4c 10 f0       	push   $0xf0104c54
f0102d57:	6a 4f                	push   $0x4f
f0102d59:	68 eb 52 10 f0       	push   $0xf01052eb
f0102d5e:	e8 3d d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102d63:	83 ec 0c             	sub    $0xc,%esp
f0102d66:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
f0102d6b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d6e:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102d71:	50                   	push   %eax
f0102d72:	e8 d0 e0 ff ff       	call   f0100e47 <page_decref>
f0102d77:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d7a:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102d7e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d81:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d86:	0f 85 29 ff ff ff    	jne    f0102cb5 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102d8c:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d8f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d94:	77 15                	ja     f0102dab <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d96:	50                   	push   %eax
f0102d97:	68 48 4b 10 f0       	push   $0xf0104b48
f0102d9c:	68 b1 01 00 00       	push   $0x1b1
f0102da1:	68 ee 55 10 f0       	push   $0xf01055ee
f0102da6:	e8 f5 d2 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102dab:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102db2:	05 00 00 00 10       	add    $0x10000000,%eax
f0102db7:	c1 e8 0c             	shr    $0xc,%eax
f0102dba:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0102dc0:	72 14                	jb     f0102dd6 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102dc2:	83 ec 04             	sub    $0x4,%esp
f0102dc5:	68 54 4c 10 f0       	push   $0xf0104c54
f0102dca:	6a 4f                	push   $0x4f
f0102dcc:	68 eb 52 10 f0       	push   $0xf01052eb
f0102dd1:	e8 ca d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102dd6:	83 ec 0c             	sub    $0xc,%esp
f0102dd9:	8b 15 4c 0c 17 f0    	mov    0xf0170c4c,%edx
f0102ddf:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102de2:	50                   	push   %eax
f0102de3:	e8 5f e0 ff ff       	call   f0100e47 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102de8:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102def:	a1 88 ff 16 f0       	mov    0xf016ff88,%eax
f0102df4:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102df7:	89 3d 88 ff 16 f0    	mov    %edi,0xf016ff88
}
f0102dfd:	83 c4 10             	add    $0x10,%esp
f0102e00:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e03:	5b                   	pop    %ebx
f0102e04:	5e                   	pop    %esi
f0102e05:	5f                   	pop    %edi
f0102e06:	5d                   	pop    %ebp
f0102e07:	c3                   	ret    

f0102e08 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102e08:	55                   	push   %ebp
f0102e09:	89 e5                	mov    %esp,%ebp
f0102e0b:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102e0e:	ff 75 08             	pushl  0x8(%ebp)
f0102e11:	e8 36 fe ff ff       	call   f0102c4c <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102e16:	c7 04 24 64 56 10 f0 	movl   $0xf0105664,(%esp)
f0102e1d:	e8 ff 00 00 00       	call   f0102f21 <cprintf>
f0102e22:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102e25:	83 ec 0c             	sub    $0xc,%esp
f0102e28:	6a 00                	push   $0x0
f0102e2a:	e8 c2 d9 ff ff       	call   f01007f1 <monitor>
f0102e2f:	83 c4 10             	add    $0x10,%esp
f0102e32:	eb f1                	jmp    f0102e25 <env_destroy+0x1d>

f0102e34 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102e34:	55                   	push   %ebp
f0102e35:	89 e5                	mov    %esp,%ebp
f0102e37:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102e3a:	8b 65 08             	mov    0x8(%ebp),%esp
f0102e3d:	61                   	popa   
f0102e3e:	07                   	pop    %es
f0102e3f:	1f                   	pop    %ds
f0102e40:	83 c4 08             	add    $0x8,%esp
f0102e43:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102e44:	68 56 56 10 f0       	push   $0xf0105656
f0102e49:	68 da 01 00 00       	push   $0x1da
f0102e4e:	68 ee 55 10 f0       	push   $0xf01055ee
f0102e53:	e8 48 d2 ff ff       	call   f01000a0 <_panic>

f0102e58 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102e58:	55                   	push   %ebp
f0102e59:	89 e5                	mov    %esp,%ebp
f0102e5b:	83 ec 08             	sub    $0x8,%esp
f0102e5e:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv)
f0102e61:	8b 15 80 ff 16 f0    	mov    0xf016ff80,%edx
f0102e67:	85 d2                	test   %edx,%edx
f0102e69:	74 0d                	je     f0102e78 <env_run+0x20>
	{
		if(curenv->env_status == ENV_RUNNING)
f0102e6b:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102e6f:	75 07                	jne    f0102e78 <env_run+0x20>
			curenv->env_status = ENV_RUNNABLE; 
f0102e71:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	lcr3(PADDR(e->env_pgdir));
f0102e78:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e7b:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102e81:	77 15                	ja     f0102e98 <env_run+0x40>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e83:	52                   	push   %edx
f0102e84:	68 48 4b 10 f0       	push   $0xf0104b48
f0102e89:	68 fd 01 00 00       	push   $0x1fd
f0102e8e:	68 ee 55 10 f0       	push   $0xf01055ee
f0102e93:	e8 08 d2 ff ff       	call   f01000a0 <_panic>
f0102e98:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102e9e:	0f 22 da             	mov    %edx,%cr3
	curenv = e;
f0102ea1:	a3 80 ff 16 f0       	mov    %eax,0xf016ff80
	e->env_status = ENV_RUNNING;
f0102ea6:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0102ead:	83 40 58 01          	addl   $0x1,0x58(%eax)
	env_pop_tf(&e->env_tf);
f0102eb1:	83 ec 0c             	sub    $0xc,%esp
f0102eb4:	50                   	push   %eax
f0102eb5:	e8 7a ff ff ff       	call   f0102e34 <env_pop_tf>

f0102eba <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102eba:	55                   	push   %ebp
f0102ebb:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ebd:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ec2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ec5:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ec6:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ecb:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ecc:	0f b6 c0             	movzbl %al,%eax
}
f0102ecf:	5d                   	pop    %ebp
f0102ed0:	c3                   	ret    

f0102ed1 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ed1:	55                   	push   %ebp
f0102ed2:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ed4:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ed9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102edc:	ee                   	out    %al,(%dx)
f0102edd:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ee2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ee5:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ee6:	5d                   	pop    %ebp
f0102ee7:	c3                   	ret    

f0102ee8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ee8:	55                   	push   %ebp
f0102ee9:	89 e5                	mov    %esp,%ebp
f0102eeb:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102eee:	ff 75 08             	pushl  0x8(%ebp)
f0102ef1:	e8 1f d7 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102ef6:	83 c4 10             	add    $0x10,%esp
f0102ef9:	c9                   	leave  
f0102efa:	c3                   	ret    

f0102efb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102efb:	55                   	push   %ebp
f0102efc:	89 e5                	mov    %esp,%ebp
f0102efe:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102f01:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f08:	ff 75 0c             	pushl  0xc(%ebp)
f0102f0b:	ff 75 08             	pushl  0x8(%ebp)
f0102f0e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f11:	50                   	push   %eax
f0102f12:	68 e8 2e 10 f0       	push   $0xf0102ee8
f0102f17:	e8 e1 0b 00 00       	call   f0103afd <vprintfmt>
	return cnt;
}
f0102f1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f1f:	c9                   	leave  
f0102f20:	c3                   	ret    

f0102f21 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f21:	55                   	push   %ebp
f0102f22:	89 e5                	mov    %esp,%ebp
f0102f24:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f27:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f2a:	50                   	push   %eax
f0102f2b:	ff 75 08             	pushl  0x8(%ebp)
f0102f2e:	e8 c8 ff ff ff       	call   f0102efb <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f33:	c9                   	leave  
f0102f34:	c3                   	ret    

f0102f35 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102f35:	55                   	push   %ebp
f0102f36:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102f38:	b8 c0 07 17 f0       	mov    $0xf01707c0,%eax
f0102f3d:	c7 05 c4 07 17 f0 00 	movl   $0xf0000000,0xf01707c4
f0102f44:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102f47:	66 c7 05 c8 07 17 f0 	movw   $0x10,0xf01707c8
f0102f4e:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102f50:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102f57:	67 00 
f0102f59:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102f5f:	89 c2                	mov    %eax,%edx
f0102f61:	c1 ea 10             	shr    $0x10,%edx
f0102f64:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102f6a:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102f71:	c1 e8 18             	shr    $0x18,%eax
f0102f74:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f79:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102f80:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f85:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102f88:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102f8d:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102f90:	5d                   	pop    %ebp
f0102f91:	c3                   	ret    

f0102f92 <trap_init>:
}


void
trap_init(void)
{
f0102f92:	55                   	push   %ebp
f0102f93:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	
	extern void TH_DIVIDE(); 	SETGATE(idt[T_DIVIDE], 0, GD_KT, TH_DIVIDE, 0); 
f0102f95:	b8 0e 36 10 f0       	mov    $0xf010360e,%eax
f0102f9a:	66 a3 a0 ff 16 f0    	mov    %ax,0xf016ffa0
f0102fa0:	66 c7 05 a2 ff 16 f0 	movw   $0x8,0xf016ffa2
f0102fa7:	08 00 
f0102fa9:	c6 05 a4 ff 16 f0 00 	movb   $0x0,0xf016ffa4
f0102fb0:	c6 05 a5 ff 16 f0 8e 	movb   $0x8e,0xf016ffa5
f0102fb7:	c1 e8 10             	shr    $0x10,%eax
f0102fba:	66 a3 a6 ff 16 f0    	mov    %ax,0xf016ffa6
	extern void TH_DEBUG(); 	SETGATE(idt[T_DEBUG], 0, GD_KT, TH_DEBUG, 0); 
f0102fc0:	b8 14 36 10 f0       	mov    $0xf0103614,%eax
f0102fc5:	66 a3 a8 ff 16 f0    	mov    %ax,0xf016ffa8
f0102fcb:	66 c7 05 aa ff 16 f0 	movw   $0x8,0xf016ffaa
f0102fd2:	08 00 
f0102fd4:	c6 05 ac ff 16 f0 00 	movb   $0x0,0xf016ffac
f0102fdb:	c6 05 ad ff 16 f0 8e 	movb   $0x8e,0xf016ffad
f0102fe2:	c1 e8 10             	shr    $0x10,%eax
f0102fe5:	66 a3 ae ff 16 f0    	mov    %ax,0xf016ffae
	extern void TH_NMI(); 		SETGATE(idt[T_NMI], 0, GD_KT, TH_NMI, 0); 
f0102feb:	b8 1a 36 10 f0       	mov    $0xf010361a,%eax
f0102ff0:	66 a3 b0 ff 16 f0    	mov    %ax,0xf016ffb0
f0102ff6:	66 c7 05 b2 ff 16 f0 	movw   $0x8,0xf016ffb2
f0102ffd:	08 00 
f0102fff:	c6 05 b4 ff 16 f0 00 	movb   $0x0,0xf016ffb4
f0103006:	c6 05 b5 ff 16 f0 8e 	movb   $0x8e,0xf016ffb5
f010300d:	c1 e8 10             	shr    $0x10,%eax
f0103010:	66 a3 b6 ff 16 f0    	mov    %ax,0xf016ffb6
	extern void TH_BRKPT(); 	SETGATE(idt[T_BRKPT], 0, GD_KT, TH_BRKPT, 3); 
f0103016:	b8 20 36 10 f0       	mov    $0xf0103620,%eax
f010301b:	66 a3 b8 ff 16 f0    	mov    %ax,0xf016ffb8
f0103021:	66 c7 05 ba ff 16 f0 	movw   $0x8,0xf016ffba
f0103028:	08 00 
f010302a:	c6 05 bc ff 16 f0 00 	movb   $0x0,0xf016ffbc
f0103031:	c6 05 bd ff 16 f0 ee 	movb   $0xee,0xf016ffbd
f0103038:	c1 e8 10             	shr    $0x10,%eax
f010303b:	66 a3 be ff 16 f0    	mov    %ax,0xf016ffbe
	extern void TH_OFLOW(); 	SETGATE(idt[T_OFLOW], 0, GD_KT, TH_OFLOW, 0); 
f0103041:	b8 26 36 10 f0       	mov    $0xf0103626,%eax
f0103046:	66 a3 c0 ff 16 f0    	mov    %ax,0xf016ffc0
f010304c:	66 c7 05 c2 ff 16 f0 	movw   $0x8,0xf016ffc2
f0103053:	08 00 
f0103055:	c6 05 c4 ff 16 f0 00 	movb   $0x0,0xf016ffc4
f010305c:	c6 05 c5 ff 16 f0 8e 	movb   $0x8e,0xf016ffc5
f0103063:	c1 e8 10             	shr    $0x10,%eax
f0103066:	66 a3 c6 ff 16 f0    	mov    %ax,0xf016ffc6
	extern void TH_BOUND(); 	SETGATE(idt[T_BOUND], 0, GD_KT, TH_BOUND, 0); 
f010306c:	b8 2c 36 10 f0       	mov    $0xf010362c,%eax
f0103071:	66 a3 c8 ff 16 f0    	mov    %ax,0xf016ffc8
f0103077:	66 c7 05 ca ff 16 f0 	movw   $0x8,0xf016ffca
f010307e:	08 00 
f0103080:	c6 05 cc ff 16 f0 00 	movb   $0x0,0xf016ffcc
f0103087:	c6 05 cd ff 16 f0 8e 	movb   $0x8e,0xf016ffcd
f010308e:	c1 e8 10             	shr    $0x10,%eax
f0103091:	66 a3 ce ff 16 f0    	mov    %ax,0xf016ffce
	extern void TH_ILLOP(); 	SETGATE(idt[T_ILLOP], 0, GD_KT, TH_ILLOP, 0); 
f0103097:	b8 32 36 10 f0       	mov    $0xf0103632,%eax
f010309c:	66 a3 d0 ff 16 f0    	mov    %ax,0xf016ffd0
f01030a2:	66 c7 05 d2 ff 16 f0 	movw   $0x8,0xf016ffd2
f01030a9:	08 00 
f01030ab:	c6 05 d4 ff 16 f0 00 	movb   $0x0,0xf016ffd4
f01030b2:	c6 05 d5 ff 16 f0 8e 	movb   $0x8e,0xf016ffd5
f01030b9:	c1 e8 10             	shr    $0x10,%eax
f01030bc:	66 a3 d6 ff 16 f0    	mov    %ax,0xf016ffd6
	extern void TH_DEVICE(); 	SETGATE(idt[T_DEVICE], 0, GD_KT, TH_DEVICE, 0); 
f01030c2:	b8 38 36 10 f0       	mov    $0xf0103638,%eax
f01030c7:	66 a3 d8 ff 16 f0    	mov    %ax,0xf016ffd8
f01030cd:	66 c7 05 da ff 16 f0 	movw   $0x8,0xf016ffda
f01030d4:	08 00 
f01030d6:	c6 05 dc ff 16 f0 00 	movb   $0x0,0xf016ffdc
f01030dd:	c6 05 dd ff 16 f0 8e 	movb   $0x8e,0xf016ffdd
f01030e4:	c1 e8 10             	shr    $0x10,%eax
f01030e7:	66 a3 de ff 16 f0    	mov    %ax,0xf016ffde
	extern void TH_DBLFLT(); 	SETGATE(idt[T_DBLFLT], 0, GD_KT, TH_DBLFLT, 0); 
f01030ed:	b8 3e 36 10 f0       	mov    $0xf010363e,%eax
f01030f2:	66 a3 e0 ff 16 f0    	mov    %ax,0xf016ffe0
f01030f8:	66 c7 05 e2 ff 16 f0 	movw   $0x8,0xf016ffe2
f01030ff:	08 00 
f0103101:	c6 05 e4 ff 16 f0 00 	movb   $0x0,0xf016ffe4
f0103108:	c6 05 e5 ff 16 f0 8e 	movb   $0x8e,0xf016ffe5
f010310f:	c1 e8 10             	shr    $0x10,%eax
f0103112:	66 a3 e6 ff 16 f0    	mov    %ax,0xf016ffe6
	extern void TH_TSS(); 		SETGATE(idt[T_TSS], 0, GD_KT, TH_TSS, 0); 
f0103118:	b8 42 36 10 f0       	mov    $0xf0103642,%eax
f010311d:	66 a3 f0 ff 16 f0    	mov    %ax,0xf016fff0
f0103123:	66 c7 05 f2 ff 16 f0 	movw   $0x8,0xf016fff2
f010312a:	08 00 
f010312c:	c6 05 f4 ff 16 f0 00 	movb   $0x0,0xf016fff4
f0103133:	c6 05 f5 ff 16 f0 8e 	movb   $0x8e,0xf016fff5
f010313a:	c1 e8 10             	shr    $0x10,%eax
f010313d:	66 a3 f6 ff 16 f0    	mov    %ax,0xf016fff6
	extern void TH_SEGNP(); 	SETGATE(idt[T_SEGNP], 0, GD_KT, TH_SEGNP, 0); 
f0103143:	b8 46 36 10 f0       	mov    $0xf0103646,%eax
f0103148:	66 a3 f8 ff 16 f0    	mov    %ax,0xf016fff8
f010314e:	66 c7 05 fa ff 16 f0 	movw   $0x8,0xf016fffa
f0103155:	08 00 
f0103157:	c6 05 fc ff 16 f0 00 	movb   $0x0,0xf016fffc
f010315e:	c6 05 fd ff 16 f0 8e 	movb   $0x8e,0xf016fffd
f0103165:	c1 e8 10             	shr    $0x10,%eax
f0103168:	66 a3 fe ff 16 f0    	mov    %ax,0xf016fffe
	extern void TH_STACK(); 	SETGATE(idt[T_STACK], 0, GD_KT, TH_STACK, 0); 
f010316e:	b8 4a 36 10 f0       	mov    $0xf010364a,%eax
f0103173:	66 a3 00 00 17 f0    	mov    %ax,0xf0170000
f0103179:	66 c7 05 02 00 17 f0 	movw   $0x8,0xf0170002
f0103180:	08 00 
f0103182:	c6 05 04 00 17 f0 00 	movb   $0x0,0xf0170004
f0103189:	c6 05 05 00 17 f0 8e 	movb   $0x8e,0xf0170005
f0103190:	c1 e8 10             	shr    $0x10,%eax
f0103193:	66 a3 06 00 17 f0    	mov    %ax,0xf0170006
	extern void TH_GPFLT(); 	SETGATE(idt[T_GPFLT], 0, GD_KT, TH_GPFLT, 0); 
f0103199:	b8 4e 36 10 f0       	mov    $0xf010364e,%eax
f010319e:	66 a3 08 00 17 f0    	mov    %ax,0xf0170008
f01031a4:	66 c7 05 0a 00 17 f0 	movw   $0x8,0xf017000a
f01031ab:	08 00 
f01031ad:	c6 05 0c 00 17 f0 00 	movb   $0x0,0xf017000c
f01031b4:	c6 05 0d 00 17 f0 8e 	movb   $0x8e,0xf017000d
f01031bb:	c1 e8 10             	shr    $0x10,%eax
f01031be:	66 a3 0e 00 17 f0    	mov    %ax,0xf017000e
	extern void TH_PGFLT(); 	SETGATE(idt[T_PGFLT], 0, GD_KT, TH_PGFLT, 0); 
f01031c4:	b8 52 36 10 f0       	mov    $0xf0103652,%eax
f01031c9:	66 a3 10 00 17 f0    	mov    %ax,0xf0170010
f01031cf:	66 c7 05 12 00 17 f0 	movw   $0x8,0xf0170012
f01031d6:	08 00 
f01031d8:	c6 05 14 00 17 f0 00 	movb   $0x0,0xf0170014
f01031df:	c6 05 15 00 17 f0 8e 	movb   $0x8e,0xf0170015
f01031e6:	c1 e8 10             	shr    $0x10,%eax
f01031e9:	66 a3 16 00 17 f0    	mov    %ax,0xf0170016
	extern void TH_FPERR(); 	SETGATE(idt[T_FPERR], 0, GD_KT, TH_FPERR, 0); 
f01031ef:	b8 56 36 10 f0       	mov    $0xf0103656,%eax
f01031f4:	66 a3 20 00 17 f0    	mov    %ax,0xf0170020
f01031fa:	66 c7 05 22 00 17 f0 	movw   $0x8,0xf0170022
f0103201:	08 00 
f0103203:	c6 05 24 00 17 f0 00 	movb   $0x0,0xf0170024
f010320a:	c6 05 25 00 17 f0 8e 	movb   $0x8e,0xf0170025
f0103211:	c1 e8 10             	shr    $0x10,%eax
f0103214:	66 a3 26 00 17 f0    	mov    %ax,0xf0170026
	extern void TH_ALIGN(); 	SETGATE(idt[T_ALIGN], 0, GD_KT, TH_ALIGN, 0); 
f010321a:	b8 5c 36 10 f0       	mov    $0xf010365c,%eax
f010321f:	66 a3 28 00 17 f0    	mov    %ax,0xf0170028
f0103225:	66 c7 05 2a 00 17 f0 	movw   $0x8,0xf017002a
f010322c:	08 00 
f010322e:	c6 05 2c 00 17 f0 00 	movb   $0x0,0xf017002c
f0103235:	c6 05 2d 00 17 f0 8e 	movb   $0x8e,0xf017002d
f010323c:	c1 e8 10             	shr    $0x10,%eax
f010323f:	66 a3 2e 00 17 f0    	mov    %ax,0xf017002e
	extern void TH_MCHK(); 		SETGATE(idt[T_MCHK], 0, GD_KT, TH_MCHK, 0); 
f0103245:	b8 60 36 10 f0       	mov    $0xf0103660,%eax
f010324a:	66 a3 30 00 17 f0    	mov    %ax,0xf0170030
f0103250:	66 c7 05 32 00 17 f0 	movw   $0x8,0xf0170032
f0103257:	08 00 
f0103259:	c6 05 34 00 17 f0 00 	movb   $0x0,0xf0170034
f0103260:	c6 05 35 00 17 f0 8e 	movb   $0x8e,0xf0170035
f0103267:	c1 e8 10             	shr    $0x10,%eax
f010326a:	66 a3 36 00 17 f0    	mov    %ax,0xf0170036
	extern void TH_SIMDERR(); 	SETGATE(idt[T_SIMDERR], 0, GD_KT, TH_SIMDERR, 0); 
f0103270:	b8 66 36 10 f0       	mov    $0xf0103666,%eax
f0103275:	66 a3 38 00 17 f0    	mov    %ax,0xf0170038
f010327b:	66 c7 05 3a 00 17 f0 	movw   $0x8,0xf017003a
f0103282:	08 00 
f0103284:	c6 05 3c 00 17 f0 00 	movb   $0x0,0xf017003c
f010328b:	c6 05 3d 00 17 f0 8e 	movb   $0x8e,0xf017003d
f0103292:	c1 e8 10             	shr    $0x10,%eax
f0103295:	66 a3 3e 00 17 f0    	mov    %ax,0xf017003e
	extern void TH_SYSCALL(); 	SETGATE(idt[T_SYSCALL], 1, GD_KT, TH_SYSCALL, 3); 
f010329b:	b8 6c 36 10 f0       	mov    $0xf010366c,%eax
f01032a0:	66 a3 20 01 17 f0    	mov    %ax,0xf0170120
f01032a6:	66 c7 05 22 01 17 f0 	movw   $0x8,0xf0170122
f01032ad:	08 00 
f01032af:	c6 05 24 01 17 f0 00 	movb   $0x0,0xf0170124
f01032b6:	c6 05 25 01 17 f0 ef 	movb   $0xef,0xf0170125
f01032bd:	c1 e8 10             	shr    $0x10,%eax
f01032c0:	66 a3 26 01 17 f0    	mov    %ax,0xf0170126

	// Per-CPU setup 
	trap_init_percpu();
f01032c6:	e8 6a fc ff ff       	call   f0102f35 <trap_init_percpu>
}
f01032cb:	5d                   	pop    %ebp
f01032cc:	c3                   	ret    

f01032cd <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01032cd:	55                   	push   %ebp
f01032ce:	89 e5                	mov    %esp,%ebp
f01032d0:	53                   	push   %ebx
f01032d1:	83 ec 0c             	sub    $0xc,%esp
f01032d4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01032d7:	ff 33                	pushl  (%ebx)
f01032d9:	68 9a 56 10 f0       	push   $0xf010569a
f01032de:	e8 3e fc ff ff       	call   f0102f21 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01032e3:	83 c4 08             	add    $0x8,%esp
f01032e6:	ff 73 04             	pushl  0x4(%ebx)
f01032e9:	68 a9 56 10 f0       	push   $0xf01056a9
f01032ee:	e8 2e fc ff ff       	call   f0102f21 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01032f3:	83 c4 08             	add    $0x8,%esp
f01032f6:	ff 73 08             	pushl  0x8(%ebx)
f01032f9:	68 b8 56 10 f0       	push   $0xf01056b8
f01032fe:	e8 1e fc ff ff       	call   f0102f21 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103303:	83 c4 08             	add    $0x8,%esp
f0103306:	ff 73 0c             	pushl  0xc(%ebx)
f0103309:	68 c7 56 10 f0       	push   $0xf01056c7
f010330e:	e8 0e fc ff ff       	call   f0102f21 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103313:	83 c4 08             	add    $0x8,%esp
f0103316:	ff 73 10             	pushl  0x10(%ebx)
f0103319:	68 d6 56 10 f0       	push   $0xf01056d6
f010331e:	e8 fe fb ff ff       	call   f0102f21 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103323:	83 c4 08             	add    $0x8,%esp
f0103326:	ff 73 14             	pushl  0x14(%ebx)
f0103329:	68 e5 56 10 f0       	push   $0xf01056e5
f010332e:	e8 ee fb ff ff       	call   f0102f21 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103333:	83 c4 08             	add    $0x8,%esp
f0103336:	ff 73 18             	pushl  0x18(%ebx)
f0103339:	68 f4 56 10 f0       	push   $0xf01056f4
f010333e:	e8 de fb ff ff       	call   f0102f21 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103343:	83 c4 08             	add    $0x8,%esp
f0103346:	ff 73 1c             	pushl  0x1c(%ebx)
f0103349:	68 03 57 10 f0       	push   $0xf0105703
f010334e:	e8 ce fb ff ff       	call   f0102f21 <cprintf>
}
f0103353:	83 c4 10             	add    $0x10,%esp
f0103356:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103359:	c9                   	leave  
f010335a:	c3                   	ret    

f010335b <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010335b:	55                   	push   %ebp
f010335c:	89 e5                	mov    %esp,%ebp
f010335e:	56                   	push   %esi
f010335f:	53                   	push   %ebx
f0103360:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103363:	83 ec 08             	sub    $0x8,%esp
f0103366:	53                   	push   %ebx
f0103367:	68 39 58 10 f0       	push   $0xf0105839
f010336c:	e8 b0 fb ff ff       	call   f0102f21 <cprintf>
	print_regs(&tf->tf_regs);
f0103371:	89 1c 24             	mov    %ebx,(%esp)
f0103374:	e8 54 ff ff ff       	call   f01032cd <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103379:	83 c4 08             	add    $0x8,%esp
f010337c:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103380:	50                   	push   %eax
f0103381:	68 54 57 10 f0       	push   $0xf0105754
f0103386:	e8 96 fb ff ff       	call   f0102f21 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010338b:	83 c4 08             	add    $0x8,%esp
f010338e:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103392:	50                   	push   %eax
f0103393:	68 67 57 10 f0       	push   $0xf0105767
f0103398:	e8 84 fb ff ff       	call   f0102f21 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010339d:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01033a0:	83 c4 10             	add    $0x10,%esp
f01033a3:	83 f8 13             	cmp    $0x13,%eax
f01033a6:	77 09                	ja     f01033b1 <print_trapframe+0x56>
		return excnames[trapno];
f01033a8:	8b 14 85 00 5a 10 f0 	mov    -0xfefa600(,%eax,4),%edx
f01033af:	eb 10                	jmp    f01033c1 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01033b1:	83 f8 30             	cmp    $0x30,%eax
f01033b4:	b9 1e 57 10 f0       	mov    $0xf010571e,%ecx
f01033b9:	ba 12 57 10 f0       	mov    $0xf0105712,%edx
f01033be:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01033c1:	83 ec 04             	sub    $0x4,%esp
f01033c4:	52                   	push   %edx
f01033c5:	50                   	push   %eax
f01033c6:	68 7a 57 10 f0       	push   $0xf010577a
f01033cb:	e8 51 fb ff ff       	call   f0102f21 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01033d0:	83 c4 10             	add    $0x10,%esp
f01033d3:	3b 1d a0 07 17 f0    	cmp    0xf01707a0,%ebx
f01033d9:	75 1a                	jne    f01033f5 <print_trapframe+0x9a>
f01033db:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01033df:	75 14                	jne    f01033f5 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01033e1:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01033e4:	83 ec 08             	sub    $0x8,%esp
f01033e7:	50                   	push   %eax
f01033e8:	68 8c 57 10 f0       	push   $0xf010578c
f01033ed:	e8 2f fb ff ff       	call   f0102f21 <cprintf>
f01033f2:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01033f5:	83 ec 08             	sub    $0x8,%esp
f01033f8:	ff 73 2c             	pushl  0x2c(%ebx)
f01033fb:	68 9b 57 10 f0       	push   $0xf010579b
f0103400:	e8 1c fb ff ff       	call   f0102f21 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103405:	83 c4 10             	add    $0x10,%esp
f0103408:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010340c:	75 49                	jne    f0103457 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010340e:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103411:	89 c2                	mov    %eax,%edx
f0103413:	83 e2 01             	and    $0x1,%edx
f0103416:	ba 38 57 10 f0       	mov    $0xf0105738,%edx
f010341b:	b9 2d 57 10 f0       	mov    $0xf010572d,%ecx
f0103420:	0f 44 ca             	cmove  %edx,%ecx
f0103423:	89 c2                	mov    %eax,%edx
f0103425:	83 e2 02             	and    $0x2,%edx
f0103428:	ba 4a 57 10 f0       	mov    $0xf010574a,%edx
f010342d:	be 44 57 10 f0       	mov    $0xf0105744,%esi
f0103432:	0f 45 d6             	cmovne %esi,%edx
f0103435:	83 e0 04             	and    $0x4,%eax
f0103438:	be 64 58 10 f0       	mov    $0xf0105864,%esi
f010343d:	b8 4f 57 10 f0       	mov    $0xf010574f,%eax
f0103442:	0f 44 c6             	cmove  %esi,%eax
f0103445:	51                   	push   %ecx
f0103446:	52                   	push   %edx
f0103447:	50                   	push   %eax
f0103448:	68 a9 57 10 f0       	push   $0xf01057a9
f010344d:	e8 cf fa ff ff       	call   f0102f21 <cprintf>
f0103452:	83 c4 10             	add    $0x10,%esp
f0103455:	eb 10                	jmp    f0103467 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103457:	83 ec 0c             	sub    $0xc,%esp
f010345a:	68 a3 55 10 f0       	push   $0xf01055a3
f010345f:	e8 bd fa ff ff       	call   f0102f21 <cprintf>
f0103464:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103467:	83 ec 08             	sub    $0x8,%esp
f010346a:	ff 73 30             	pushl  0x30(%ebx)
f010346d:	68 b8 57 10 f0       	push   $0xf01057b8
f0103472:	e8 aa fa ff ff       	call   f0102f21 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103477:	83 c4 08             	add    $0x8,%esp
f010347a:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010347e:	50                   	push   %eax
f010347f:	68 c7 57 10 f0       	push   $0xf01057c7
f0103484:	e8 98 fa ff ff       	call   f0102f21 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103489:	83 c4 08             	add    $0x8,%esp
f010348c:	ff 73 38             	pushl  0x38(%ebx)
f010348f:	68 da 57 10 f0       	push   $0xf01057da
f0103494:	e8 88 fa ff ff       	call   f0102f21 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103499:	83 c4 10             	add    $0x10,%esp
f010349c:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01034a0:	74 25                	je     f01034c7 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01034a2:	83 ec 08             	sub    $0x8,%esp
f01034a5:	ff 73 3c             	pushl  0x3c(%ebx)
f01034a8:	68 e9 57 10 f0       	push   $0xf01057e9
f01034ad:	e8 6f fa ff ff       	call   f0102f21 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01034b2:	83 c4 08             	add    $0x8,%esp
f01034b5:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01034b9:	50                   	push   %eax
f01034ba:	68 f8 57 10 f0       	push   $0xf01057f8
f01034bf:	e8 5d fa ff ff       	call   f0102f21 <cprintf>
f01034c4:	83 c4 10             	add    $0x10,%esp
	}
}
f01034c7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01034ca:	5b                   	pop    %ebx
f01034cb:	5e                   	pop    %esi
f01034cc:	5d                   	pop    %ebp
f01034cd:	c3                   	ret    

f01034ce <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01034ce:	55                   	push   %ebp
f01034cf:	89 e5                	mov    %esp,%ebp
f01034d1:	53                   	push   %ebx
f01034d2:	83 ec 04             	sub    $0x4,%esp
f01034d5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01034d8:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01034db:	ff 73 30             	pushl  0x30(%ebx)
f01034de:	50                   	push   %eax
f01034df:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f01034e4:	ff 70 48             	pushl  0x48(%eax)
f01034e7:	68 b0 59 10 f0       	push   $0xf01059b0
f01034ec:	e8 30 fa ff ff       	call   f0102f21 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01034f1:	89 1c 24             	mov    %ebx,(%esp)
f01034f4:	e8 62 fe ff ff       	call   f010335b <print_trapframe>
	env_destroy(curenv);
f01034f9:	83 c4 04             	add    $0x4,%esp
f01034fc:	ff 35 80 ff 16 f0    	pushl  0xf016ff80
f0103502:	e8 01 f9 ff ff       	call   f0102e08 <env_destroy>
}
f0103507:	83 c4 10             	add    $0x10,%esp
f010350a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010350d:	c9                   	leave  
f010350e:	c3                   	ret    

f010350f <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f010350f:	55                   	push   %ebp
f0103510:	89 e5                	mov    %esp,%ebp
f0103512:	57                   	push   %edi
f0103513:	56                   	push   %esi
f0103514:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103517:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103518:	9c                   	pushf  
f0103519:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f010351a:	f6 c4 02             	test   $0x2,%ah
f010351d:	74 19                	je     f0103538 <trap+0x29>
f010351f:	68 0b 58 10 f0       	push   $0xf010580b
f0103524:	68 05 53 10 f0       	push   $0xf0105305
f0103529:	68 c0 00 00 00       	push   $0xc0
f010352e:	68 24 58 10 f0       	push   $0xf0105824
f0103533:	e8 68 cb ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103538:	83 ec 08             	sub    $0x8,%esp
f010353b:	56                   	push   %esi
f010353c:	68 30 58 10 f0       	push   $0xf0105830
f0103541:	e8 db f9 ff ff       	call   f0102f21 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103546:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010354a:	83 e0 03             	and    $0x3,%eax
f010354d:	83 c4 10             	add    $0x10,%esp
f0103550:	66 83 f8 03          	cmp    $0x3,%ax
f0103554:	75 31                	jne    f0103587 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103556:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f010355b:	85 c0                	test   %eax,%eax
f010355d:	75 19                	jne    f0103578 <trap+0x69>
f010355f:	68 4b 58 10 f0       	push   $0xf010584b
f0103564:	68 05 53 10 f0       	push   $0xf0105305
f0103569:	68 c6 00 00 00       	push   $0xc6
f010356e:	68 24 58 10 f0       	push   $0xf0105824
f0103573:	e8 28 cb ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103578:	b9 11 00 00 00       	mov    $0x11,%ecx
f010357d:	89 c7                	mov    %eax,%edi
f010357f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103581:	8b 35 80 ff 16 f0    	mov    0xf016ff80,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103587:	89 35 a0 07 17 f0    	mov    %esi,0xf01707a0
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno)
f010358d:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103591:	75 0e                	jne    f01035a1 <trap+0x92>
	{
		case(T_PGFLT):
		page_fault_handler(tf);
f0103593:	83 ec 0c             	sub    $0xc,%esp
f0103596:	56                   	push   %esi
f0103597:	e8 32 ff ff ff       	call   f01034ce <page_fault_handler>
f010359c:	83 c4 10             	add    $0x10,%esp
f010359f:	eb 3b                	jmp    f01035dc <trap+0xcd>
		return;
	}	
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01035a1:	83 ec 0c             	sub    $0xc,%esp
f01035a4:	56                   	push   %esi
f01035a5:	e8 b1 fd ff ff       	call   f010335b <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01035aa:	83 c4 10             	add    $0x10,%esp
f01035ad:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01035b2:	75 17                	jne    f01035cb <trap+0xbc>
		panic("unhandled trap in kernel");
f01035b4:	83 ec 04             	sub    $0x4,%esp
f01035b7:	68 52 58 10 f0       	push   $0xf0105852
f01035bc:	68 af 00 00 00       	push   $0xaf
f01035c1:	68 24 58 10 f0       	push   $0xf0105824
f01035c6:	e8 d5 ca ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f01035cb:	83 ec 0c             	sub    $0xc,%esp
f01035ce:	ff 35 80 ff 16 f0    	pushl  0xf016ff80
f01035d4:	e8 2f f8 ff ff       	call   f0102e08 <env_destroy>
f01035d9:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01035dc:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f01035e1:	85 c0                	test   %eax,%eax
f01035e3:	74 06                	je     f01035eb <trap+0xdc>
f01035e5:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01035e9:	74 19                	je     f0103604 <trap+0xf5>
f01035eb:	68 d4 59 10 f0       	push   $0xf01059d4
f01035f0:	68 05 53 10 f0       	push   $0xf0105305
f01035f5:	68 d8 00 00 00       	push   $0xd8
f01035fa:	68 24 58 10 f0       	push   $0xf0105824
f01035ff:	e8 9c ca ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103604:	83 ec 0c             	sub    $0xc,%esp
f0103607:	50                   	push   %eax
f0103608:	e8 4b f8 ff ff       	call   f0102e58 <env_run>
f010360d:	90                   	nop

f010360e <TH_DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(TH_DIVIDE, 0)	// fault
f010360e:	6a 00                	push   $0x0
f0103610:	6a 00                	push   $0x0
f0103612:	eb 5e                	jmp    f0103672 <_alltraps>

f0103614 <TH_DEBUG>:
TRAPHANDLER_NOEC(TH_DEBUG, 1)	// fault/trap
f0103614:	6a 00                	push   $0x0
f0103616:	6a 01                	push   $0x1
f0103618:	eb 58                	jmp    f0103672 <_alltraps>

f010361a <TH_NMI>:
TRAPHANDLER_NOEC(TH_NMI, 2)	//
f010361a:	6a 00                	push   $0x0
f010361c:	6a 02                	push   $0x2
f010361e:	eb 52                	jmp    f0103672 <_alltraps>

f0103620 <TH_BRKPT>:
TRAPHANDLER_NOEC(TH_BRKPT, 3)	// trap
f0103620:	6a 00                	push   $0x0
f0103622:	6a 03                	push   $0x3
f0103624:	eb 4c                	jmp    f0103672 <_alltraps>

f0103626 <TH_OFLOW>:
TRAPHANDLER_NOEC(TH_OFLOW, 4)	// trap
f0103626:	6a 00                	push   $0x0
f0103628:	6a 04                	push   $0x4
f010362a:	eb 46                	jmp    f0103672 <_alltraps>

f010362c <TH_BOUND>:
TRAPHANDLER_NOEC(TH_BOUND, 5)	// fault
f010362c:	6a 00                	push   $0x0
f010362e:	6a 05                	push   $0x5
f0103630:	eb 40                	jmp    f0103672 <_alltraps>

f0103632 <TH_ILLOP>:
TRAPHANDLER_NOEC(TH_ILLOP, 6)	// fault
f0103632:	6a 00                	push   $0x0
f0103634:	6a 06                	push   $0x6
f0103636:	eb 3a                	jmp    f0103672 <_alltraps>

f0103638 <TH_DEVICE>:
TRAPHANDLER_NOEC(TH_DEVICE, 7)	// fault
f0103638:	6a 00                	push   $0x0
f010363a:	6a 07                	push   $0x7
f010363c:	eb 34                	jmp    f0103672 <_alltraps>

f010363e <TH_DBLFLT>:
TRAPHANDLER     (TH_DBLFLT, 8)	// abort
f010363e:	6a 08                	push   $0x8
f0103640:	eb 30                	jmp    f0103672 <_alltraps>

f0103642 <TH_TSS>:
//TRAPHANDLER_NOEC(TH_COPROC, 9) // abort	
TRAPHANDLER     (TH_TSS, 10)	// fault
f0103642:	6a 0a                	push   $0xa
f0103644:	eb 2c                	jmp    f0103672 <_alltraps>

f0103646 <TH_SEGNP>:
TRAPHANDLER     (TH_SEGNP, 11)	// fault
f0103646:	6a 0b                	push   $0xb
f0103648:	eb 28                	jmp    f0103672 <_alltraps>

f010364a <TH_STACK>:
TRAPHANDLER     (TH_STACK, 12)	// fault
f010364a:	6a 0c                	push   $0xc
f010364c:	eb 24                	jmp    f0103672 <_alltraps>

f010364e <TH_GPFLT>:
TRAPHANDLER     (TH_GPFLT, 13)	// fault/abort
f010364e:	6a 0d                	push   $0xd
f0103650:	eb 20                	jmp    f0103672 <_alltraps>

f0103652 <TH_PGFLT>:
TRAPHANDLER     (TH_PGFLT, 14)	// fault
f0103652:	6a 0e                	push   $0xe
f0103654:	eb 1c                	jmp    f0103672 <_alltraps>

f0103656 <TH_FPERR>:
//TRAPHANDLER_NOEC(TH_RES, 15)	
TRAPHANDLER_NOEC(TH_FPERR, 16)	// fault
f0103656:	6a 00                	push   $0x0
f0103658:	6a 10                	push   $0x10
f010365a:	eb 16                	jmp    f0103672 <_alltraps>

f010365c <TH_ALIGN>:
TRAPHANDLER     (TH_ALIGN, 17)	//
f010365c:	6a 11                	push   $0x11
f010365e:	eb 12                	jmp    f0103672 <_alltraps>

f0103660 <TH_MCHK>:
TRAPHANDLER_NOEC(TH_MCHK, 18)	//
f0103660:	6a 00                	push   $0x0
f0103662:	6a 12                	push   $0x12
f0103664:	eb 0c                	jmp    f0103672 <_alltraps>

f0103666 <TH_SIMDERR>:
TRAPHANDLER_NOEC(TH_SIMDERR, 19) //
f0103666:	6a 00                	push   $0x0
f0103668:	6a 13                	push   $0x13
f010366a:	eb 06                	jmp    f0103672 <_alltraps>

f010366c <TH_SYSCALL>:

TRAPHANDLER_NOEC(TH_SYSCALL, 48) // trap
f010366c:	6a 00                	push   $0x0
f010366e:	6a 30                	push   $0x30
f0103670:	eb 00                	jmp    f0103672 <_alltraps>

f0103672 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

.text
_alltraps:
	pushl	%ds
f0103672:	1e                   	push   %ds
	pushl	%es
f0103673:	06                   	push   %es
	pushal
f0103674:	60                   	pusha  
	mov	$GD_KD, %eax
f0103675:	b8 10 00 00 00       	mov    $0x10,%eax
	mov	%ax, %es
f010367a:	8e c0                	mov    %eax,%es
	mov	%ax, %ds
f010367c:	8e d8                	mov    %eax,%ds
	pushl	%esp
f010367e:	54                   	push   %esp
	call	trap
f010367f:	e8 8b fe ff ff       	call   f010350f <trap>

f0103684 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103684:	55                   	push   %ebp
f0103685:	89 e5                	mov    %esp,%ebp
f0103687:	83 ec 0c             	sub    $0xc,%esp
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	panic("syscall not implemented");
f010368a:	68 50 5a 10 f0       	push   $0xf0105a50
f010368f:	6a 49                	push   $0x49
f0103691:	68 68 5a 10 f0       	push   $0xf0105a68
f0103696:	e8 05 ca ff ff       	call   f01000a0 <_panic>

f010369b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010369b:	55                   	push   %ebp
f010369c:	89 e5                	mov    %esp,%ebp
f010369e:	57                   	push   %edi
f010369f:	56                   	push   %esi
f01036a0:	53                   	push   %ebx
f01036a1:	83 ec 14             	sub    $0x14,%esp
f01036a4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01036a7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01036aa:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01036ad:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01036b0:	8b 1a                	mov    (%edx),%ebx
f01036b2:	8b 01                	mov    (%ecx),%eax
f01036b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01036b7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01036be:	eb 7f                	jmp    f010373f <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01036c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01036c3:	01 d8                	add    %ebx,%eax
f01036c5:	89 c6                	mov    %eax,%esi
f01036c7:	c1 ee 1f             	shr    $0x1f,%esi
f01036ca:	01 c6                	add    %eax,%esi
f01036cc:	d1 fe                	sar    %esi
f01036ce:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01036d1:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01036d4:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01036d7:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01036d9:	eb 03                	jmp    f01036de <stab_binsearch+0x43>
			m--;
f01036db:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01036de:	39 c3                	cmp    %eax,%ebx
f01036e0:	7f 0d                	jg     f01036ef <stab_binsearch+0x54>
f01036e2:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01036e6:	83 ea 0c             	sub    $0xc,%edx
f01036e9:	39 f9                	cmp    %edi,%ecx
f01036eb:	75 ee                	jne    f01036db <stab_binsearch+0x40>
f01036ed:	eb 05                	jmp    f01036f4 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01036ef:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01036f2:	eb 4b                	jmp    f010373f <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01036f4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01036f7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01036fa:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01036fe:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103701:	76 11                	jbe    f0103714 <stab_binsearch+0x79>
			*region_left = m;
f0103703:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103706:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103708:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010370b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103712:	eb 2b                	jmp    f010373f <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103714:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103717:	73 14                	jae    f010372d <stab_binsearch+0x92>
			*region_right = m - 1;
f0103719:	83 e8 01             	sub    $0x1,%eax
f010371c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010371f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103722:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103724:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010372b:	eb 12                	jmp    f010373f <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010372d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103730:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103732:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103736:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103738:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010373f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103742:	0f 8e 78 ff ff ff    	jle    f01036c0 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103748:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010374c:	75 0f                	jne    f010375d <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010374e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103751:	8b 00                	mov    (%eax),%eax
f0103753:	83 e8 01             	sub    $0x1,%eax
f0103756:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103759:	89 06                	mov    %eax,(%esi)
f010375b:	eb 2c                	jmp    f0103789 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010375d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103760:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103762:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103765:	8b 0e                	mov    (%esi),%ecx
f0103767:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010376a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010376d:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103770:	eb 03                	jmp    f0103775 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103772:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103775:	39 c8                	cmp    %ecx,%eax
f0103777:	7e 0b                	jle    f0103784 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103779:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010377d:	83 ea 0c             	sub    $0xc,%edx
f0103780:	39 df                	cmp    %ebx,%edi
f0103782:	75 ee                	jne    f0103772 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103784:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103787:	89 06                	mov    %eax,(%esi)
	}
}
f0103789:	83 c4 14             	add    $0x14,%esp
f010378c:	5b                   	pop    %ebx
f010378d:	5e                   	pop    %esi
f010378e:	5f                   	pop    %edi
f010378f:	5d                   	pop    %ebp
f0103790:	c3                   	ret    

f0103791 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103791:	55                   	push   %ebp
f0103792:	89 e5                	mov    %esp,%ebp
f0103794:	57                   	push   %edi
f0103795:	56                   	push   %esi
f0103796:	53                   	push   %ebx
f0103797:	83 ec 3c             	sub    $0x3c,%esp
f010379a:	8b 75 08             	mov    0x8(%ebp),%esi
f010379d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01037a0:	c7 03 77 5a 10 f0    	movl   $0xf0105a77,(%ebx)
	info->eip_line = 0;
f01037a6:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01037ad:	c7 43 08 77 5a 10 f0 	movl   $0xf0105a77,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01037b4:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01037bb:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01037be:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01037c5:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01037cb:	77 21                	ja     f01037ee <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01037cd:	a1 00 00 20 00       	mov    0x200000,%eax
f01037d2:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f01037d5:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01037da:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f01037e0:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01037e3:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f01037e9:	89 7d c0             	mov    %edi,-0x40(%ebp)
f01037ec:	eb 1a                	jmp    f0103808 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01037ee:	c7 45 c0 41 fd 10 f0 	movl   $0xf010fd41,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01037f5:	c7 45 b8 59 d3 10 f0 	movl   $0xf010d359,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01037fc:	b8 58 d3 10 f0       	mov    $0xf010d358,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103801:	c7 45 bc 90 5c 10 f0 	movl   $0xf0105c90,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103808:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010380b:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f010380e:	0f 83 9d 01 00 00    	jae    f01039b1 <debuginfo_eip+0x220>
f0103814:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103818:	0f 85 9a 01 00 00    	jne    f01039b8 <debuginfo_eip+0x227>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010381e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103825:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103828:	29 f8                	sub    %edi,%eax
f010382a:	c1 f8 02             	sar    $0x2,%eax
f010382d:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103833:	83 e8 01             	sub    $0x1,%eax
f0103836:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103839:	56                   	push   %esi
f010383a:	6a 64                	push   $0x64
f010383c:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010383f:	89 c1                	mov    %eax,%ecx
f0103841:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103844:	89 f8                	mov    %edi,%eax
f0103846:	e8 50 fe ff ff       	call   f010369b <stab_binsearch>
	if (lfile == 0)
f010384b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010384e:	83 c4 08             	add    $0x8,%esp
f0103851:	85 c0                	test   %eax,%eax
f0103853:	0f 84 66 01 00 00    	je     f01039bf <debuginfo_eip+0x22e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103859:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010385c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010385f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103862:	56                   	push   %esi
f0103863:	6a 24                	push   $0x24
f0103865:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103868:	89 c1                	mov    %eax,%ecx
f010386a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010386d:	89 f8                	mov    %edi,%eax
f010386f:	e8 27 fe ff ff       	call   f010369b <stab_binsearch>

	if (lfun <= rfun) {
f0103874:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103877:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010387a:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f010387d:	83 c4 08             	add    $0x8,%esp
f0103880:	39 d0                	cmp    %edx,%eax
f0103882:	7f 2b                	jg     f01038af <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103884:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103887:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f010388a:	8b 11                	mov    (%ecx),%edx
f010388c:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010388f:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103892:	39 fa                	cmp    %edi,%edx
f0103894:	73 06                	jae    f010389c <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103896:	03 55 b8             	add    -0x48(%ebp),%edx
f0103899:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010389c:	8b 51 08             	mov    0x8(%ecx),%edx
f010389f:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01038a2:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01038a4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01038a7:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01038aa:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01038ad:	eb 0f                	jmp    f01038be <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01038af:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01038b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01038b5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01038b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01038bb:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01038be:	83 ec 08             	sub    $0x8,%esp
f01038c1:	6a 3a                	push   $0x3a
f01038c3:	ff 73 08             	pushl  0x8(%ebx)
f01038c6:	e8 82 08 00 00       	call   f010414d <strfind>
f01038cb:	2b 43 08             	sub    0x8(%ebx),%eax
f01038ce:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01038d1:	83 c4 08             	add    $0x8,%esp
f01038d4:	56                   	push   %esi
f01038d5:	6a 44                	push   $0x44
f01038d7:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01038da:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01038dd:	8b 75 bc             	mov    -0x44(%ebp),%esi
f01038e0:	89 f0                	mov    %esi,%eax
f01038e2:	e8 b4 fd ff ff       	call   f010369b <stab_binsearch>
	if(lline > rline)
f01038e7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01038ea:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01038ed:	83 c4 10             	add    $0x10,%esp
f01038f0:	39 c2                	cmp    %eax,%edx
f01038f2:	0f 8f ce 00 00 00    	jg     f01039c6 <debuginfo_eip+0x235>
	return -1;
	info->eip_line =  stabs[rline].n_desc;	
f01038f8:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01038fb:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103900:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103903:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103906:	89 d0                	mov    %edx,%eax
f0103908:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010390b:	8d 14 96             	lea    (%esi,%edx,4),%edx
f010390e:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103912:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103915:	eb 0a                	jmp    f0103921 <debuginfo_eip+0x190>
f0103917:	83 e8 01             	sub    $0x1,%eax
f010391a:	83 ea 0c             	sub    $0xc,%edx
f010391d:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103921:	39 c7                	cmp    %eax,%edi
f0103923:	7e 05                	jle    f010392a <debuginfo_eip+0x199>
f0103925:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103928:	eb 47                	jmp    f0103971 <debuginfo_eip+0x1e0>
	       && stabs[lline].n_type != N_SOL
f010392a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010392e:	80 f9 84             	cmp    $0x84,%cl
f0103931:	75 0e                	jne    f0103941 <debuginfo_eip+0x1b0>
f0103933:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103936:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010393a:	74 1c                	je     f0103958 <debuginfo_eip+0x1c7>
f010393c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010393f:	eb 17                	jmp    f0103958 <debuginfo_eip+0x1c7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103941:	80 f9 64             	cmp    $0x64,%cl
f0103944:	75 d1                	jne    f0103917 <debuginfo_eip+0x186>
f0103946:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010394a:	74 cb                	je     f0103917 <debuginfo_eip+0x186>
f010394c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010394f:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103953:	74 03                	je     f0103958 <debuginfo_eip+0x1c7>
f0103955:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103958:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010395b:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010395e:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103961:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103964:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103967:	29 f8                	sub    %edi,%eax
f0103969:	39 c2                	cmp    %eax,%edx
f010396b:	73 04                	jae    f0103971 <debuginfo_eip+0x1e0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010396d:	01 fa                	add    %edi,%edx
f010396f:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103971:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103974:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103977:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010397c:	39 f2                	cmp    %esi,%edx
f010397e:	7d 52                	jge    f01039d2 <debuginfo_eip+0x241>
		for (lline = lfun + 1;
f0103980:	83 c2 01             	add    $0x1,%edx
f0103983:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103986:	89 d0                	mov    %edx,%eax
f0103988:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010398b:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010398e:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103991:	eb 04                	jmp    f0103997 <debuginfo_eip+0x206>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103993:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103997:	39 c6                	cmp    %eax,%esi
f0103999:	7e 32                	jle    f01039cd <debuginfo_eip+0x23c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010399b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010399f:	83 c0 01             	add    $0x1,%eax
f01039a2:	83 c2 0c             	add    $0xc,%edx
f01039a5:	80 f9 a0             	cmp    $0xa0,%cl
f01039a8:	74 e9                	je     f0103993 <debuginfo_eip+0x202>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01039aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01039af:	eb 21                	jmp    f01039d2 <debuginfo_eip+0x241>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01039b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039b6:	eb 1a                	jmp    f01039d2 <debuginfo_eip+0x241>
f01039b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039bd:	eb 13                	jmp    f01039d2 <debuginfo_eip+0x241>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01039bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039c4:	eb 0c                	jmp    f01039d2 <debuginfo_eip+0x241>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline > rline)
	return -1;
f01039c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039cb:	eb 05                	jmp    f01039d2 <debuginfo_eip+0x241>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01039cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039d2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039d5:	5b                   	pop    %ebx
f01039d6:	5e                   	pop    %esi
f01039d7:	5f                   	pop    %edi
f01039d8:	5d                   	pop    %ebp
f01039d9:	c3                   	ret    

f01039da <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01039da:	55                   	push   %ebp
f01039db:	89 e5                	mov    %esp,%ebp
f01039dd:	57                   	push   %edi
f01039de:	56                   	push   %esi
f01039df:	53                   	push   %ebx
f01039e0:	83 ec 1c             	sub    $0x1c,%esp
f01039e3:	89 c7                	mov    %eax,%edi
f01039e5:	89 d6                	mov    %edx,%esi
f01039e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ea:	8b 55 0c             	mov    0xc(%ebp),%edx
f01039ed:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01039f0:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01039f3:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01039f6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01039fb:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01039fe:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103a01:	39 d3                	cmp    %edx,%ebx
f0103a03:	72 05                	jb     f0103a0a <printnum+0x30>
f0103a05:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103a08:	77 45                	ja     f0103a4f <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103a0a:	83 ec 0c             	sub    $0xc,%esp
f0103a0d:	ff 75 18             	pushl  0x18(%ebp)
f0103a10:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a13:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103a16:	53                   	push   %ebx
f0103a17:	ff 75 10             	pushl  0x10(%ebp)
f0103a1a:	83 ec 08             	sub    $0x8,%esp
f0103a1d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103a20:	ff 75 e0             	pushl  -0x20(%ebp)
f0103a23:	ff 75 dc             	pushl  -0x24(%ebp)
f0103a26:	ff 75 d8             	pushl  -0x28(%ebp)
f0103a29:	e8 42 09 00 00       	call   f0104370 <__udivdi3>
f0103a2e:	83 c4 18             	add    $0x18,%esp
f0103a31:	52                   	push   %edx
f0103a32:	50                   	push   %eax
f0103a33:	89 f2                	mov    %esi,%edx
f0103a35:	89 f8                	mov    %edi,%eax
f0103a37:	e8 9e ff ff ff       	call   f01039da <printnum>
f0103a3c:	83 c4 20             	add    $0x20,%esp
f0103a3f:	eb 18                	jmp    f0103a59 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103a41:	83 ec 08             	sub    $0x8,%esp
f0103a44:	56                   	push   %esi
f0103a45:	ff 75 18             	pushl  0x18(%ebp)
f0103a48:	ff d7                	call   *%edi
f0103a4a:	83 c4 10             	add    $0x10,%esp
f0103a4d:	eb 03                	jmp    f0103a52 <printnum+0x78>
f0103a4f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103a52:	83 eb 01             	sub    $0x1,%ebx
f0103a55:	85 db                	test   %ebx,%ebx
f0103a57:	7f e8                	jg     f0103a41 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103a59:	83 ec 08             	sub    $0x8,%esp
f0103a5c:	56                   	push   %esi
f0103a5d:	83 ec 04             	sub    $0x4,%esp
f0103a60:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103a63:	ff 75 e0             	pushl  -0x20(%ebp)
f0103a66:	ff 75 dc             	pushl  -0x24(%ebp)
f0103a69:	ff 75 d8             	pushl  -0x28(%ebp)
f0103a6c:	e8 2f 0a 00 00       	call   f01044a0 <__umoddi3>
f0103a71:	83 c4 14             	add    $0x14,%esp
f0103a74:	0f be 80 81 5a 10 f0 	movsbl -0xfefa57f(%eax),%eax
f0103a7b:	50                   	push   %eax
f0103a7c:	ff d7                	call   *%edi
}
f0103a7e:	83 c4 10             	add    $0x10,%esp
f0103a81:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a84:	5b                   	pop    %ebx
f0103a85:	5e                   	pop    %esi
f0103a86:	5f                   	pop    %edi
f0103a87:	5d                   	pop    %ebp
f0103a88:	c3                   	ret    

f0103a89 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103a89:	55                   	push   %ebp
f0103a8a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103a8c:	83 fa 01             	cmp    $0x1,%edx
f0103a8f:	7e 0e                	jle    f0103a9f <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103a91:	8b 10                	mov    (%eax),%edx
f0103a93:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103a96:	89 08                	mov    %ecx,(%eax)
f0103a98:	8b 02                	mov    (%edx),%eax
f0103a9a:	8b 52 04             	mov    0x4(%edx),%edx
f0103a9d:	eb 22                	jmp    f0103ac1 <getuint+0x38>
	else if (lflag)
f0103a9f:	85 d2                	test   %edx,%edx
f0103aa1:	74 10                	je     f0103ab3 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103aa3:	8b 10                	mov    (%eax),%edx
f0103aa5:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103aa8:	89 08                	mov    %ecx,(%eax)
f0103aaa:	8b 02                	mov    (%edx),%eax
f0103aac:	ba 00 00 00 00       	mov    $0x0,%edx
f0103ab1:	eb 0e                	jmp    f0103ac1 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103ab3:	8b 10                	mov    (%eax),%edx
f0103ab5:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103ab8:	89 08                	mov    %ecx,(%eax)
f0103aba:	8b 02                	mov    (%edx),%eax
f0103abc:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103ac1:	5d                   	pop    %ebp
f0103ac2:	c3                   	ret    

f0103ac3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103ac3:	55                   	push   %ebp
f0103ac4:	89 e5                	mov    %esp,%ebp
f0103ac6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103ac9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103acd:	8b 10                	mov    (%eax),%edx
f0103acf:	3b 50 04             	cmp    0x4(%eax),%edx
f0103ad2:	73 0a                	jae    f0103ade <sprintputch+0x1b>
		*b->buf++ = ch;
f0103ad4:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103ad7:	89 08                	mov    %ecx,(%eax)
f0103ad9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103adc:	88 02                	mov    %al,(%edx)
}
f0103ade:	5d                   	pop    %ebp
f0103adf:	c3                   	ret    

f0103ae0 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103ae0:	55                   	push   %ebp
f0103ae1:	89 e5                	mov    %esp,%ebp
f0103ae3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103ae6:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103ae9:	50                   	push   %eax
f0103aea:	ff 75 10             	pushl  0x10(%ebp)
f0103aed:	ff 75 0c             	pushl  0xc(%ebp)
f0103af0:	ff 75 08             	pushl  0x8(%ebp)
f0103af3:	e8 05 00 00 00       	call   f0103afd <vprintfmt>
	va_end(ap);
}
f0103af8:	83 c4 10             	add    $0x10,%esp
f0103afb:	c9                   	leave  
f0103afc:	c3                   	ret    

f0103afd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103afd:	55                   	push   %ebp
f0103afe:	89 e5                	mov    %esp,%ebp
f0103b00:	57                   	push   %edi
f0103b01:	56                   	push   %esi
f0103b02:	53                   	push   %ebx
f0103b03:	83 ec 2c             	sub    $0x2c,%esp
f0103b06:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b09:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b0c:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103b0f:	eb 12                	jmp    f0103b23 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103b11:	85 c0                	test   %eax,%eax
f0103b13:	0f 84 89 03 00 00    	je     f0103ea2 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103b19:	83 ec 08             	sub    $0x8,%esp
f0103b1c:	53                   	push   %ebx
f0103b1d:	50                   	push   %eax
f0103b1e:	ff d6                	call   *%esi
f0103b20:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103b23:	83 c7 01             	add    $0x1,%edi
f0103b26:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103b2a:	83 f8 25             	cmp    $0x25,%eax
f0103b2d:	75 e2                	jne    f0103b11 <vprintfmt+0x14>
f0103b2f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103b33:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103b3a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103b41:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103b48:	ba 00 00 00 00       	mov    $0x0,%edx
f0103b4d:	eb 07                	jmp    f0103b56 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b4f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103b52:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b56:	8d 47 01             	lea    0x1(%edi),%eax
f0103b59:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103b5c:	0f b6 07             	movzbl (%edi),%eax
f0103b5f:	0f b6 c8             	movzbl %al,%ecx
f0103b62:	83 e8 23             	sub    $0x23,%eax
f0103b65:	3c 55                	cmp    $0x55,%al
f0103b67:	0f 87 1a 03 00 00    	ja     f0103e87 <vprintfmt+0x38a>
f0103b6d:	0f b6 c0             	movzbl %al,%eax
f0103b70:	ff 24 85 0c 5b 10 f0 	jmp    *-0xfefa4f4(,%eax,4)
f0103b77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103b7a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103b7e:	eb d6                	jmp    f0103b56 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b80:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b83:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b88:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103b8b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103b8e:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103b92:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103b95:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103b98:	83 fa 09             	cmp    $0x9,%edx
f0103b9b:	77 39                	ja     f0103bd6 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103b9d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103ba0:	eb e9                	jmp    f0103b8b <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103ba2:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ba5:	8d 48 04             	lea    0x4(%eax),%ecx
f0103ba8:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103bab:	8b 00                	mov    (%eax),%eax
f0103bad:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bb0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103bb3:	eb 27                	jmp    f0103bdc <vprintfmt+0xdf>
f0103bb5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103bb8:	85 c0                	test   %eax,%eax
f0103bba:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103bbf:	0f 49 c8             	cmovns %eax,%ecx
f0103bc2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bc5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103bc8:	eb 8c                	jmp    f0103b56 <vprintfmt+0x59>
f0103bca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103bcd:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103bd4:	eb 80                	jmp    f0103b56 <vprintfmt+0x59>
f0103bd6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103bd9:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103bdc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103be0:	0f 89 70 ff ff ff    	jns    f0103b56 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103be6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103be9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103bec:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103bf3:	e9 5e ff ff ff       	jmp    f0103b56 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103bf8:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bfb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103bfe:	e9 53 ff ff ff       	jmp    f0103b56 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103c03:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c06:	8d 50 04             	lea    0x4(%eax),%edx
f0103c09:	89 55 14             	mov    %edx,0x14(%ebp)
f0103c0c:	83 ec 08             	sub    $0x8,%esp
f0103c0f:	53                   	push   %ebx
f0103c10:	ff 30                	pushl  (%eax)
f0103c12:	ff d6                	call   *%esi
			break;
f0103c14:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c17:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103c1a:	e9 04 ff ff ff       	jmp    f0103b23 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103c1f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c22:	8d 50 04             	lea    0x4(%eax),%edx
f0103c25:	89 55 14             	mov    %edx,0x14(%ebp)
f0103c28:	8b 00                	mov    (%eax),%eax
f0103c2a:	99                   	cltd   
f0103c2b:	31 d0                	xor    %edx,%eax
f0103c2d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103c2f:	83 f8 06             	cmp    $0x6,%eax
f0103c32:	7f 0b                	jg     f0103c3f <vprintfmt+0x142>
f0103c34:	8b 14 85 64 5c 10 f0 	mov    -0xfefa39c(,%eax,4),%edx
f0103c3b:	85 d2                	test   %edx,%edx
f0103c3d:	75 18                	jne    f0103c57 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103c3f:	50                   	push   %eax
f0103c40:	68 99 5a 10 f0       	push   $0xf0105a99
f0103c45:	53                   	push   %ebx
f0103c46:	56                   	push   %esi
f0103c47:	e8 94 fe ff ff       	call   f0103ae0 <printfmt>
f0103c4c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c4f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103c52:	e9 cc fe ff ff       	jmp    f0103b23 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103c57:	52                   	push   %edx
f0103c58:	68 17 53 10 f0       	push   $0xf0105317
f0103c5d:	53                   	push   %ebx
f0103c5e:	56                   	push   %esi
f0103c5f:	e8 7c fe ff ff       	call   f0103ae0 <printfmt>
f0103c64:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c67:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c6a:	e9 b4 fe ff ff       	jmp    f0103b23 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103c6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c72:	8d 50 04             	lea    0x4(%eax),%edx
f0103c75:	89 55 14             	mov    %edx,0x14(%ebp)
f0103c78:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103c7a:	85 ff                	test   %edi,%edi
f0103c7c:	b8 92 5a 10 f0       	mov    $0xf0105a92,%eax
f0103c81:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103c84:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103c88:	0f 8e 94 00 00 00    	jle    f0103d22 <vprintfmt+0x225>
f0103c8e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103c92:	0f 84 98 00 00 00    	je     f0103d30 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c98:	83 ec 08             	sub    $0x8,%esp
f0103c9b:	ff 75 d0             	pushl  -0x30(%ebp)
f0103c9e:	57                   	push   %edi
f0103c9f:	e8 5f 03 00 00       	call   f0104003 <strnlen>
f0103ca4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103ca7:	29 c1                	sub    %eax,%ecx
f0103ca9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103cac:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103caf:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103cb3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103cb6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103cb9:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103cbb:	eb 0f                	jmp    f0103ccc <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103cbd:	83 ec 08             	sub    $0x8,%esp
f0103cc0:	53                   	push   %ebx
f0103cc1:	ff 75 e0             	pushl  -0x20(%ebp)
f0103cc4:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103cc6:	83 ef 01             	sub    $0x1,%edi
f0103cc9:	83 c4 10             	add    $0x10,%esp
f0103ccc:	85 ff                	test   %edi,%edi
f0103cce:	7f ed                	jg     f0103cbd <vprintfmt+0x1c0>
f0103cd0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103cd3:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103cd6:	85 c9                	test   %ecx,%ecx
f0103cd8:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cdd:	0f 49 c1             	cmovns %ecx,%eax
f0103ce0:	29 c1                	sub    %eax,%ecx
f0103ce2:	89 75 08             	mov    %esi,0x8(%ebp)
f0103ce5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103ce8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103ceb:	89 cb                	mov    %ecx,%ebx
f0103ced:	eb 4d                	jmp    f0103d3c <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103cef:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103cf3:	74 1b                	je     f0103d10 <vprintfmt+0x213>
f0103cf5:	0f be c0             	movsbl %al,%eax
f0103cf8:	83 e8 20             	sub    $0x20,%eax
f0103cfb:	83 f8 5e             	cmp    $0x5e,%eax
f0103cfe:	76 10                	jbe    f0103d10 <vprintfmt+0x213>
					putch('?', putdat);
f0103d00:	83 ec 08             	sub    $0x8,%esp
f0103d03:	ff 75 0c             	pushl  0xc(%ebp)
f0103d06:	6a 3f                	push   $0x3f
f0103d08:	ff 55 08             	call   *0x8(%ebp)
f0103d0b:	83 c4 10             	add    $0x10,%esp
f0103d0e:	eb 0d                	jmp    f0103d1d <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103d10:	83 ec 08             	sub    $0x8,%esp
f0103d13:	ff 75 0c             	pushl  0xc(%ebp)
f0103d16:	52                   	push   %edx
f0103d17:	ff 55 08             	call   *0x8(%ebp)
f0103d1a:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103d1d:	83 eb 01             	sub    $0x1,%ebx
f0103d20:	eb 1a                	jmp    f0103d3c <vprintfmt+0x23f>
f0103d22:	89 75 08             	mov    %esi,0x8(%ebp)
f0103d25:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103d28:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d2b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103d2e:	eb 0c                	jmp    f0103d3c <vprintfmt+0x23f>
f0103d30:	89 75 08             	mov    %esi,0x8(%ebp)
f0103d33:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103d36:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d39:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103d3c:	83 c7 01             	add    $0x1,%edi
f0103d3f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103d43:	0f be d0             	movsbl %al,%edx
f0103d46:	85 d2                	test   %edx,%edx
f0103d48:	74 23                	je     f0103d6d <vprintfmt+0x270>
f0103d4a:	85 f6                	test   %esi,%esi
f0103d4c:	78 a1                	js     f0103cef <vprintfmt+0x1f2>
f0103d4e:	83 ee 01             	sub    $0x1,%esi
f0103d51:	79 9c                	jns    f0103cef <vprintfmt+0x1f2>
f0103d53:	89 df                	mov    %ebx,%edi
f0103d55:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d58:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d5b:	eb 18                	jmp    f0103d75 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103d5d:	83 ec 08             	sub    $0x8,%esp
f0103d60:	53                   	push   %ebx
f0103d61:	6a 20                	push   $0x20
f0103d63:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103d65:	83 ef 01             	sub    $0x1,%edi
f0103d68:	83 c4 10             	add    $0x10,%esp
f0103d6b:	eb 08                	jmp    f0103d75 <vprintfmt+0x278>
f0103d6d:	89 df                	mov    %ebx,%edi
f0103d6f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d72:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d75:	85 ff                	test   %edi,%edi
f0103d77:	7f e4                	jg     f0103d5d <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d79:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d7c:	e9 a2 fd ff ff       	jmp    f0103b23 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103d81:	83 fa 01             	cmp    $0x1,%edx
f0103d84:	7e 16                	jle    f0103d9c <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103d86:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d89:	8d 50 08             	lea    0x8(%eax),%edx
f0103d8c:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d8f:	8b 50 04             	mov    0x4(%eax),%edx
f0103d92:	8b 00                	mov    (%eax),%eax
f0103d94:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d97:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103d9a:	eb 32                	jmp    f0103dce <vprintfmt+0x2d1>
	else if (lflag)
f0103d9c:	85 d2                	test   %edx,%edx
f0103d9e:	74 18                	je     f0103db8 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103da0:	8b 45 14             	mov    0x14(%ebp),%eax
f0103da3:	8d 50 04             	lea    0x4(%eax),%edx
f0103da6:	89 55 14             	mov    %edx,0x14(%ebp)
f0103da9:	8b 00                	mov    (%eax),%eax
f0103dab:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103dae:	89 c1                	mov    %eax,%ecx
f0103db0:	c1 f9 1f             	sar    $0x1f,%ecx
f0103db3:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103db6:	eb 16                	jmp    f0103dce <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103db8:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dbb:	8d 50 04             	lea    0x4(%eax),%edx
f0103dbe:	89 55 14             	mov    %edx,0x14(%ebp)
f0103dc1:	8b 00                	mov    (%eax),%eax
f0103dc3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103dc6:	89 c1                	mov    %eax,%ecx
f0103dc8:	c1 f9 1f             	sar    $0x1f,%ecx
f0103dcb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103dce:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103dd1:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103dd4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103dd9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103ddd:	79 74                	jns    f0103e53 <vprintfmt+0x356>
				putch('-', putdat);
f0103ddf:	83 ec 08             	sub    $0x8,%esp
f0103de2:	53                   	push   %ebx
f0103de3:	6a 2d                	push   $0x2d
f0103de5:	ff d6                	call   *%esi
				num = -(long long) num;
f0103de7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103dea:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103ded:	f7 d8                	neg    %eax
f0103def:	83 d2 00             	adc    $0x0,%edx
f0103df2:	f7 da                	neg    %edx
f0103df4:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103df7:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103dfc:	eb 55                	jmp    f0103e53 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103dfe:	8d 45 14             	lea    0x14(%ebp),%eax
f0103e01:	e8 83 fc ff ff       	call   f0103a89 <getuint>
			base = 10;
f0103e06:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103e0b:	eb 46                	jmp    f0103e53 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
		        num = getuint(&ap, lflag);
f0103e0d:	8d 45 14             	lea    0x14(%ebp),%eax
f0103e10:	e8 74 fc ff ff       	call   f0103a89 <getuint>
			base=8;
f0103e15:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103e1a:	eb 37                	jmp    f0103e53 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0103e1c:	83 ec 08             	sub    $0x8,%esp
f0103e1f:	53                   	push   %ebx
f0103e20:	6a 30                	push   $0x30
f0103e22:	ff d6                	call   *%esi
			putch('x', putdat);
f0103e24:	83 c4 08             	add    $0x8,%esp
f0103e27:	53                   	push   %ebx
f0103e28:	6a 78                	push   $0x78
f0103e2a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103e2c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e2f:	8d 50 04             	lea    0x4(%eax),%edx
f0103e32:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103e35:	8b 00                	mov    (%eax),%eax
f0103e37:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103e3c:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103e3f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103e44:	eb 0d                	jmp    f0103e53 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103e46:	8d 45 14             	lea    0x14(%ebp),%eax
f0103e49:	e8 3b fc ff ff       	call   f0103a89 <getuint>
			base = 16;
f0103e4e:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103e53:	83 ec 0c             	sub    $0xc,%esp
f0103e56:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103e5a:	57                   	push   %edi
f0103e5b:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e5e:	51                   	push   %ecx
f0103e5f:	52                   	push   %edx
f0103e60:	50                   	push   %eax
f0103e61:	89 da                	mov    %ebx,%edx
f0103e63:	89 f0                	mov    %esi,%eax
f0103e65:	e8 70 fb ff ff       	call   f01039da <printnum>
			break;
f0103e6a:	83 c4 20             	add    $0x20,%esp
f0103e6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e70:	e9 ae fc ff ff       	jmp    f0103b23 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103e75:	83 ec 08             	sub    $0x8,%esp
f0103e78:	53                   	push   %ebx
f0103e79:	51                   	push   %ecx
f0103e7a:	ff d6                	call   *%esi
			break;
f0103e7c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e7f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103e82:	e9 9c fc ff ff       	jmp    f0103b23 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103e87:	83 ec 08             	sub    $0x8,%esp
f0103e8a:	53                   	push   %ebx
f0103e8b:	6a 25                	push   $0x25
f0103e8d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103e8f:	83 c4 10             	add    $0x10,%esp
f0103e92:	eb 03                	jmp    f0103e97 <vprintfmt+0x39a>
f0103e94:	83 ef 01             	sub    $0x1,%edi
f0103e97:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103e9b:	75 f7                	jne    f0103e94 <vprintfmt+0x397>
f0103e9d:	e9 81 fc ff ff       	jmp    f0103b23 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103ea2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ea5:	5b                   	pop    %ebx
f0103ea6:	5e                   	pop    %esi
f0103ea7:	5f                   	pop    %edi
f0103ea8:	5d                   	pop    %ebp
f0103ea9:	c3                   	ret    

f0103eaa <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103eaa:	55                   	push   %ebp
f0103eab:	89 e5                	mov    %esp,%ebp
f0103ead:	83 ec 18             	sub    $0x18,%esp
f0103eb0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103eb3:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103eb6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103eb9:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103ebd:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103ec0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103ec7:	85 c0                	test   %eax,%eax
f0103ec9:	74 26                	je     f0103ef1 <vsnprintf+0x47>
f0103ecb:	85 d2                	test   %edx,%edx
f0103ecd:	7e 22                	jle    f0103ef1 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103ecf:	ff 75 14             	pushl  0x14(%ebp)
f0103ed2:	ff 75 10             	pushl  0x10(%ebp)
f0103ed5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103ed8:	50                   	push   %eax
f0103ed9:	68 c3 3a 10 f0       	push   $0xf0103ac3
f0103ede:	e8 1a fc ff ff       	call   f0103afd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103ee3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103ee6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103ee9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103eec:	83 c4 10             	add    $0x10,%esp
f0103eef:	eb 05                	jmp    f0103ef6 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103ef1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103ef6:	c9                   	leave  
f0103ef7:	c3                   	ret    

f0103ef8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103ef8:	55                   	push   %ebp
f0103ef9:	89 e5                	mov    %esp,%ebp
f0103efb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103efe:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103f01:	50                   	push   %eax
f0103f02:	ff 75 10             	pushl  0x10(%ebp)
f0103f05:	ff 75 0c             	pushl  0xc(%ebp)
f0103f08:	ff 75 08             	pushl  0x8(%ebp)
f0103f0b:	e8 9a ff ff ff       	call   f0103eaa <vsnprintf>
	va_end(ap);

	return rc;
}
f0103f10:	c9                   	leave  
f0103f11:	c3                   	ret    

f0103f12 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103f12:	55                   	push   %ebp
f0103f13:	89 e5                	mov    %esp,%ebp
f0103f15:	57                   	push   %edi
f0103f16:	56                   	push   %esi
f0103f17:	53                   	push   %ebx
f0103f18:	83 ec 0c             	sub    $0xc,%esp
f0103f1b:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103f1e:	85 c0                	test   %eax,%eax
f0103f20:	74 11                	je     f0103f33 <readline+0x21>
		cprintf("%s", prompt);
f0103f22:	83 ec 08             	sub    $0x8,%esp
f0103f25:	50                   	push   %eax
f0103f26:	68 17 53 10 f0       	push   $0xf0105317
f0103f2b:	e8 f1 ef ff ff       	call   f0102f21 <cprintf>
f0103f30:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103f33:	83 ec 0c             	sub    $0xc,%esp
f0103f36:	6a 00                	push   $0x0
f0103f38:	e8 f9 c6 ff ff       	call   f0100636 <iscons>
f0103f3d:	89 c7                	mov    %eax,%edi
f0103f3f:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103f42:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103f47:	e8 d9 c6 ff ff       	call   f0100625 <getchar>
f0103f4c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103f4e:	85 c0                	test   %eax,%eax
f0103f50:	79 18                	jns    f0103f6a <readline+0x58>
			cprintf("read error: %e\n", c);
f0103f52:	83 ec 08             	sub    $0x8,%esp
f0103f55:	50                   	push   %eax
f0103f56:	68 80 5c 10 f0       	push   $0xf0105c80
f0103f5b:	e8 c1 ef ff ff       	call   f0102f21 <cprintf>
			return NULL;
f0103f60:	83 c4 10             	add    $0x10,%esp
f0103f63:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f68:	eb 79                	jmp    f0103fe3 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103f6a:	83 f8 08             	cmp    $0x8,%eax
f0103f6d:	0f 94 c2             	sete   %dl
f0103f70:	83 f8 7f             	cmp    $0x7f,%eax
f0103f73:	0f 94 c0             	sete   %al
f0103f76:	08 c2                	or     %al,%dl
f0103f78:	74 1a                	je     f0103f94 <readline+0x82>
f0103f7a:	85 f6                	test   %esi,%esi
f0103f7c:	7e 16                	jle    f0103f94 <readline+0x82>
			if (echoing)
f0103f7e:	85 ff                	test   %edi,%edi
f0103f80:	74 0d                	je     f0103f8f <readline+0x7d>
				cputchar('\b');
f0103f82:	83 ec 0c             	sub    $0xc,%esp
f0103f85:	6a 08                	push   $0x8
f0103f87:	e8 89 c6 ff ff       	call   f0100615 <cputchar>
f0103f8c:	83 c4 10             	add    $0x10,%esp
			i--;
f0103f8f:	83 ee 01             	sub    $0x1,%esi
f0103f92:	eb b3                	jmp    f0103f47 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103f94:	83 fb 1f             	cmp    $0x1f,%ebx
f0103f97:	7e 23                	jle    f0103fbc <readline+0xaa>
f0103f99:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103f9f:	7f 1b                	jg     f0103fbc <readline+0xaa>
			if (echoing)
f0103fa1:	85 ff                	test   %edi,%edi
f0103fa3:	74 0c                	je     f0103fb1 <readline+0x9f>
				cputchar(c);
f0103fa5:	83 ec 0c             	sub    $0xc,%esp
f0103fa8:	53                   	push   %ebx
f0103fa9:	e8 67 c6 ff ff       	call   f0100615 <cputchar>
f0103fae:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103fb1:	88 9e 40 08 17 f0    	mov    %bl,-0xfe8f7c0(%esi)
f0103fb7:	8d 76 01             	lea    0x1(%esi),%esi
f0103fba:	eb 8b                	jmp    f0103f47 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103fbc:	83 fb 0a             	cmp    $0xa,%ebx
f0103fbf:	74 05                	je     f0103fc6 <readline+0xb4>
f0103fc1:	83 fb 0d             	cmp    $0xd,%ebx
f0103fc4:	75 81                	jne    f0103f47 <readline+0x35>
			if (echoing)
f0103fc6:	85 ff                	test   %edi,%edi
f0103fc8:	74 0d                	je     f0103fd7 <readline+0xc5>
				cputchar('\n');
f0103fca:	83 ec 0c             	sub    $0xc,%esp
f0103fcd:	6a 0a                	push   $0xa
f0103fcf:	e8 41 c6 ff ff       	call   f0100615 <cputchar>
f0103fd4:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103fd7:	c6 86 40 08 17 f0 00 	movb   $0x0,-0xfe8f7c0(%esi)
			return buf;
f0103fde:	b8 40 08 17 f0       	mov    $0xf0170840,%eax
		}
	}
}
f0103fe3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103fe6:	5b                   	pop    %ebx
f0103fe7:	5e                   	pop    %esi
f0103fe8:	5f                   	pop    %edi
f0103fe9:	5d                   	pop    %ebp
f0103fea:	c3                   	ret    

f0103feb <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103feb:	55                   	push   %ebp
f0103fec:	89 e5                	mov    %esp,%ebp
f0103fee:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103ff1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ff6:	eb 03                	jmp    f0103ffb <strlen+0x10>
		n++;
f0103ff8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103ffb:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103fff:	75 f7                	jne    f0103ff8 <strlen+0xd>
		n++;
	return n;
}
f0104001:	5d                   	pop    %ebp
f0104002:	c3                   	ret    

f0104003 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104003:	55                   	push   %ebp
f0104004:	89 e5                	mov    %esp,%ebp
f0104006:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104009:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010400c:	ba 00 00 00 00       	mov    $0x0,%edx
f0104011:	eb 03                	jmp    f0104016 <strnlen+0x13>
		n++;
f0104013:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104016:	39 c2                	cmp    %eax,%edx
f0104018:	74 08                	je     f0104022 <strnlen+0x1f>
f010401a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010401e:	75 f3                	jne    f0104013 <strnlen+0x10>
f0104020:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104022:	5d                   	pop    %ebp
f0104023:	c3                   	ret    

f0104024 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104024:	55                   	push   %ebp
f0104025:	89 e5                	mov    %esp,%ebp
f0104027:	53                   	push   %ebx
f0104028:	8b 45 08             	mov    0x8(%ebp),%eax
f010402b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010402e:	89 c2                	mov    %eax,%edx
f0104030:	83 c2 01             	add    $0x1,%edx
f0104033:	83 c1 01             	add    $0x1,%ecx
f0104036:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010403a:	88 5a ff             	mov    %bl,-0x1(%edx)
f010403d:	84 db                	test   %bl,%bl
f010403f:	75 ef                	jne    f0104030 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104041:	5b                   	pop    %ebx
f0104042:	5d                   	pop    %ebp
f0104043:	c3                   	ret    

f0104044 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104044:	55                   	push   %ebp
f0104045:	89 e5                	mov    %esp,%ebp
f0104047:	53                   	push   %ebx
f0104048:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010404b:	53                   	push   %ebx
f010404c:	e8 9a ff ff ff       	call   f0103feb <strlen>
f0104051:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104054:	ff 75 0c             	pushl  0xc(%ebp)
f0104057:	01 d8                	add    %ebx,%eax
f0104059:	50                   	push   %eax
f010405a:	e8 c5 ff ff ff       	call   f0104024 <strcpy>
	return dst;
}
f010405f:	89 d8                	mov    %ebx,%eax
f0104061:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104064:	c9                   	leave  
f0104065:	c3                   	ret    

f0104066 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104066:	55                   	push   %ebp
f0104067:	89 e5                	mov    %esp,%ebp
f0104069:	56                   	push   %esi
f010406a:	53                   	push   %ebx
f010406b:	8b 75 08             	mov    0x8(%ebp),%esi
f010406e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104071:	89 f3                	mov    %esi,%ebx
f0104073:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104076:	89 f2                	mov    %esi,%edx
f0104078:	eb 0f                	jmp    f0104089 <strncpy+0x23>
		*dst++ = *src;
f010407a:	83 c2 01             	add    $0x1,%edx
f010407d:	0f b6 01             	movzbl (%ecx),%eax
f0104080:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104083:	80 39 01             	cmpb   $0x1,(%ecx)
f0104086:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104089:	39 da                	cmp    %ebx,%edx
f010408b:	75 ed                	jne    f010407a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010408d:	89 f0                	mov    %esi,%eax
f010408f:	5b                   	pop    %ebx
f0104090:	5e                   	pop    %esi
f0104091:	5d                   	pop    %ebp
f0104092:	c3                   	ret    

f0104093 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104093:	55                   	push   %ebp
f0104094:	89 e5                	mov    %esp,%ebp
f0104096:	56                   	push   %esi
f0104097:	53                   	push   %ebx
f0104098:	8b 75 08             	mov    0x8(%ebp),%esi
f010409b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010409e:	8b 55 10             	mov    0x10(%ebp),%edx
f01040a1:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01040a3:	85 d2                	test   %edx,%edx
f01040a5:	74 21                	je     f01040c8 <strlcpy+0x35>
f01040a7:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01040ab:	89 f2                	mov    %esi,%edx
f01040ad:	eb 09                	jmp    f01040b8 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01040af:	83 c2 01             	add    $0x1,%edx
f01040b2:	83 c1 01             	add    $0x1,%ecx
f01040b5:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01040b8:	39 c2                	cmp    %eax,%edx
f01040ba:	74 09                	je     f01040c5 <strlcpy+0x32>
f01040bc:	0f b6 19             	movzbl (%ecx),%ebx
f01040bf:	84 db                	test   %bl,%bl
f01040c1:	75 ec                	jne    f01040af <strlcpy+0x1c>
f01040c3:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01040c5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01040c8:	29 f0                	sub    %esi,%eax
}
f01040ca:	5b                   	pop    %ebx
f01040cb:	5e                   	pop    %esi
f01040cc:	5d                   	pop    %ebp
f01040cd:	c3                   	ret    

f01040ce <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01040ce:	55                   	push   %ebp
f01040cf:	89 e5                	mov    %esp,%ebp
f01040d1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01040d4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01040d7:	eb 06                	jmp    f01040df <strcmp+0x11>
		p++, q++;
f01040d9:	83 c1 01             	add    $0x1,%ecx
f01040dc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01040df:	0f b6 01             	movzbl (%ecx),%eax
f01040e2:	84 c0                	test   %al,%al
f01040e4:	74 04                	je     f01040ea <strcmp+0x1c>
f01040e6:	3a 02                	cmp    (%edx),%al
f01040e8:	74 ef                	je     f01040d9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01040ea:	0f b6 c0             	movzbl %al,%eax
f01040ed:	0f b6 12             	movzbl (%edx),%edx
f01040f0:	29 d0                	sub    %edx,%eax
}
f01040f2:	5d                   	pop    %ebp
f01040f3:	c3                   	ret    

f01040f4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01040f4:	55                   	push   %ebp
f01040f5:	89 e5                	mov    %esp,%ebp
f01040f7:	53                   	push   %ebx
f01040f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01040fb:	8b 55 0c             	mov    0xc(%ebp),%edx
f01040fe:	89 c3                	mov    %eax,%ebx
f0104100:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104103:	eb 06                	jmp    f010410b <strncmp+0x17>
		n--, p++, q++;
f0104105:	83 c0 01             	add    $0x1,%eax
f0104108:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010410b:	39 d8                	cmp    %ebx,%eax
f010410d:	74 15                	je     f0104124 <strncmp+0x30>
f010410f:	0f b6 08             	movzbl (%eax),%ecx
f0104112:	84 c9                	test   %cl,%cl
f0104114:	74 04                	je     f010411a <strncmp+0x26>
f0104116:	3a 0a                	cmp    (%edx),%cl
f0104118:	74 eb                	je     f0104105 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010411a:	0f b6 00             	movzbl (%eax),%eax
f010411d:	0f b6 12             	movzbl (%edx),%edx
f0104120:	29 d0                	sub    %edx,%eax
f0104122:	eb 05                	jmp    f0104129 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104124:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104129:	5b                   	pop    %ebx
f010412a:	5d                   	pop    %ebp
f010412b:	c3                   	ret    

f010412c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010412c:	55                   	push   %ebp
f010412d:	89 e5                	mov    %esp,%ebp
f010412f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104132:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104136:	eb 07                	jmp    f010413f <strchr+0x13>
		if (*s == c)
f0104138:	38 ca                	cmp    %cl,%dl
f010413a:	74 0f                	je     f010414b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010413c:	83 c0 01             	add    $0x1,%eax
f010413f:	0f b6 10             	movzbl (%eax),%edx
f0104142:	84 d2                	test   %dl,%dl
f0104144:	75 f2                	jne    f0104138 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104146:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010414b:	5d                   	pop    %ebp
f010414c:	c3                   	ret    

f010414d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010414d:	55                   	push   %ebp
f010414e:	89 e5                	mov    %esp,%ebp
f0104150:	8b 45 08             	mov    0x8(%ebp),%eax
f0104153:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104157:	eb 03                	jmp    f010415c <strfind+0xf>
f0104159:	83 c0 01             	add    $0x1,%eax
f010415c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010415f:	38 ca                	cmp    %cl,%dl
f0104161:	74 04                	je     f0104167 <strfind+0x1a>
f0104163:	84 d2                	test   %dl,%dl
f0104165:	75 f2                	jne    f0104159 <strfind+0xc>
			break;
	return (char *) s;
}
f0104167:	5d                   	pop    %ebp
f0104168:	c3                   	ret    

f0104169 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104169:	55                   	push   %ebp
f010416a:	89 e5                	mov    %esp,%ebp
f010416c:	57                   	push   %edi
f010416d:	56                   	push   %esi
f010416e:	53                   	push   %ebx
f010416f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104172:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104175:	85 c9                	test   %ecx,%ecx
f0104177:	74 36                	je     f01041af <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104179:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010417f:	75 28                	jne    f01041a9 <memset+0x40>
f0104181:	f6 c1 03             	test   $0x3,%cl
f0104184:	75 23                	jne    f01041a9 <memset+0x40>
		c &= 0xFF;
f0104186:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010418a:	89 d3                	mov    %edx,%ebx
f010418c:	c1 e3 08             	shl    $0x8,%ebx
f010418f:	89 d6                	mov    %edx,%esi
f0104191:	c1 e6 18             	shl    $0x18,%esi
f0104194:	89 d0                	mov    %edx,%eax
f0104196:	c1 e0 10             	shl    $0x10,%eax
f0104199:	09 f0                	or     %esi,%eax
f010419b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010419d:	89 d8                	mov    %ebx,%eax
f010419f:	09 d0                	or     %edx,%eax
f01041a1:	c1 e9 02             	shr    $0x2,%ecx
f01041a4:	fc                   	cld    
f01041a5:	f3 ab                	rep stos %eax,%es:(%edi)
f01041a7:	eb 06                	jmp    f01041af <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01041a9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01041ac:	fc                   	cld    
f01041ad:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01041af:	89 f8                	mov    %edi,%eax
f01041b1:	5b                   	pop    %ebx
f01041b2:	5e                   	pop    %esi
f01041b3:	5f                   	pop    %edi
f01041b4:	5d                   	pop    %ebp
f01041b5:	c3                   	ret    

f01041b6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01041b6:	55                   	push   %ebp
f01041b7:	89 e5                	mov    %esp,%ebp
f01041b9:	57                   	push   %edi
f01041ba:	56                   	push   %esi
f01041bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01041be:	8b 75 0c             	mov    0xc(%ebp),%esi
f01041c1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01041c4:	39 c6                	cmp    %eax,%esi
f01041c6:	73 35                	jae    f01041fd <memmove+0x47>
f01041c8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01041cb:	39 d0                	cmp    %edx,%eax
f01041cd:	73 2e                	jae    f01041fd <memmove+0x47>
		s += n;
		d += n;
f01041cf:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041d2:	89 d6                	mov    %edx,%esi
f01041d4:	09 fe                	or     %edi,%esi
f01041d6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01041dc:	75 13                	jne    f01041f1 <memmove+0x3b>
f01041de:	f6 c1 03             	test   $0x3,%cl
f01041e1:	75 0e                	jne    f01041f1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01041e3:	83 ef 04             	sub    $0x4,%edi
f01041e6:	8d 72 fc             	lea    -0x4(%edx),%esi
f01041e9:	c1 e9 02             	shr    $0x2,%ecx
f01041ec:	fd                   	std    
f01041ed:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041ef:	eb 09                	jmp    f01041fa <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01041f1:	83 ef 01             	sub    $0x1,%edi
f01041f4:	8d 72 ff             	lea    -0x1(%edx),%esi
f01041f7:	fd                   	std    
f01041f8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01041fa:	fc                   	cld    
f01041fb:	eb 1d                	jmp    f010421a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041fd:	89 f2                	mov    %esi,%edx
f01041ff:	09 c2                	or     %eax,%edx
f0104201:	f6 c2 03             	test   $0x3,%dl
f0104204:	75 0f                	jne    f0104215 <memmove+0x5f>
f0104206:	f6 c1 03             	test   $0x3,%cl
f0104209:	75 0a                	jne    f0104215 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010420b:	c1 e9 02             	shr    $0x2,%ecx
f010420e:	89 c7                	mov    %eax,%edi
f0104210:	fc                   	cld    
f0104211:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104213:	eb 05                	jmp    f010421a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104215:	89 c7                	mov    %eax,%edi
f0104217:	fc                   	cld    
f0104218:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010421a:	5e                   	pop    %esi
f010421b:	5f                   	pop    %edi
f010421c:	5d                   	pop    %ebp
f010421d:	c3                   	ret    

f010421e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010421e:	55                   	push   %ebp
f010421f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104221:	ff 75 10             	pushl  0x10(%ebp)
f0104224:	ff 75 0c             	pushl  0xc(%ebp)
f0104227:	ff 75 08             	pushl  0x8(%ebp)
f010422a:	e8 87 ff ff ff       	call   f01041b6 <memmove>
}
f010422f:	c9                   	leave  
f0104230:	c3                   	ret    

f0104231 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104231:	55                   	push   %ebp
f0104232:	89 e5                	mov    %esp,%ebp
f0104234:	56                   	push   %esi
f0104235:	53                   	push   %ebx
f0104236:	8b 45 08             	mov    0x8(%ebp),%eax
f0104239:	8b 55 0c             	mov    0xc(%ebp),%edx
f010423c:	89 c6                	mov    %eax,%esi
f010423e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104241:	eb 1a                	jmp    f010425d <memcmp+0x2c>
		if (*s1 != *s2)
f0104243:	0f b6 08             	movzbl (%eax),%ecx
f0104246:	0f b6 1a             	movzbl (%edx),%ebx
f0104249:	38 d9                	cmp    %bl,%cl
f010424b:	74 0a                	je     f0104257 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010424d:	0f b6 c1             	movzbl %cl,%eax
f0104250:	0f b6 db             	movzbl %bl,%ebx
f0104253:	29 d8                	sub    %ebx,%eax
f0104255:	eb 0f                	jmp    f0104266 <memcmp+0x35>
		s1++, s2++;
f0104257:	83 c0 01             	add    $0x1,%eax
f010425a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010425d:	39 f0                	cmp    %esi,%eax
f010425f:	75 e2                	jne    f0104243 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104261:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104266:	5b                   	pop    %ebx
f0104267:	5e                   	pop    %esi
f0104268:	5d                   	pop    %ebp
f0104269:	c3                   	ret    

f010426a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010426a:	55                   	push   %ebp
f010426b:	89 e5                	mov    %esp,%ebp
f010426d:	53                   	push   %ebx
f010426e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104271:	89 c1                	mov    %eax,%ecx
f0104273:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104276:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010427a:	eb 0a                	jmp    f0104286 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010427c:	0f b6 10             	movzbl (%eax),%edx
f010427f:	39 da                	cmp    %ebx,%edx
f0104281:	74 07                	je     f010428a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104283:	83 c0 01             	add    $0x1,%eax
f0104286:	39 c8                	cmp    %ecx,%eax
f0104288:	72 f2                	jb     f010427c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010428a:	5b                   	pop    %ebx
f010428b:	5d                   	pop    %ebp
f010428c:	c3                   	ret    

f010428d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010428d:	55                   	push   %ebp
f010428e:	89 e5                	mov    %esp,%ebp
f0104290:	57                   	push   %edi
f0104291:	56                   	push   %esi
f0104292:	53                   	push   %ebx
f0104293:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104296:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104299:	eb 03                	jmp    f010429e <strtol+0x11>
		s++;
f010429b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010429e:	0f b6 01             	movzbl (%ecx),%eax
f01042a1:	3c 20                	cmp    $0x20,%al
f01042a3:	74 f6                	je     f010429b <strtol+0xe>
f01042a5:	3c 09                	cmp    $0x9,%al
f01042a7:	74 f2                	je     f010429b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01042a9:	3c 2b                	cmp    $0x2b,%al
f01042ab:	75 0a                	jne    f01042b7 <strtol+0x2a>
		s++;
f01042ad:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01042b0:	bf 00 00 00 00       	mov    $0x0,%edi
f01042b5:	eb 11                	jmp    f01042c8 <strtol+0x3b>
f01042b7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01042bc:	3c 2d                	cmp    $0x2d,%al
f01042be:	75 08                	jne    f01042c8 <strtol+0x3b>
		s++, neg = 1;
f01042c0:	83 c1 01             	add    $0x1,%ecx
f01042c3:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01042c8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01042ce:	75 15                	jne    f01042e5 <strtol+0x58>
f01042d0:	80 39 30             	cmpb   $0x30,(%ecx)
f01042d3:	75 10                	jne    f01042e5 <strtol+0x58>
f01042d5:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01042d9:	75 7c                	jne    f0104357 <strtol+0xca>
		s += 2, base = 16;
f01042db:	83 c1 02             	add    $0x2,%ecx
f01042de:	bb 10 00 00 00       	mov    $0x10,%ebx
f01042e3:	eb 16                	jmp    f01042fb <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01042e5:	85 db                	test   %ebx,%ebx
f01042e7:	75 12                	jne    f01042fb <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01042e9:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01042ee:	80 39 30             	cmpb   $0x30,(%ecx)
f01042f1:	75 08                	jne    f01042fb <strtol+0x6e>
		s++, base = 8;
f01042f3:	83 c1 01             	add    $0x1,%ecx
f01042f6:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01042fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104300:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104303:	0f b6 11             	movzbl (%ecx),%edx
f0104306:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104309:	89 f3                	mov    %esi,%ebx
f010430b:	80 fb 09             	cmp    $0x9,%bl
f010430e:	77 08                	ja     f0104318 <strtol+0x8b>
			dig = *s - '0';
f0104310:	0f be d2             	movsbl %dl,%edx
f0104313:	83 ea 30             	sub    $0x30,%edx
f0104316:	eb 22                	jmp    f010433a <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104318:	8d 72 9f             	lea    -0x61(%edx),%esi
f010431b:	89 f3                	mov    %esi,%ebx
f010431d:	80 fb 19             	cmp    $0x19,%bl
f0104320:	77 08                	ja     f010432a <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104322:	0f be d2             	movsbl %dl,%edx
f0104325:	83 ea 57             	sub    $0x57,%edx
f0104328:	eb 10                	jmp    f010433a <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010432a:	8d 72 bf             	lea    -0x41(%edx),%esi
f010432d:	89 f3                	mov    %esi,%ebx
f010432f:	80 fb 19             	cmp    $0x19,%bl
f0104332:	77 16                	ja     f010434a <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104334:	0f be d2             	movsbl %dl,%edx
f0104337:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010433a:	3b 55 10             	cmp    0x10(%ebp),%edx
f010433d:	7d 0b                	jge    f010434a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010433f:	83 c1 01             	add    $0x1,%ecx
f0104342:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104346:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104348:	eb b9                	jmp    f0104303 <strtol+0x76>

	if (endptr)
f010434a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010434e:	74 0d                	je     f010435d <strtol+0xd0>
		*endptr = (char *) s;
f0104350:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104353:	89 0e                	mov    %ecx,(%esi)
f0104355:	eb 06                	jmp    f010435d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104357:	85 db                	test   %ebx,%ebx
f0104359:	74 98                	je     f01042f3 <strtol+0x66>
f010435b:	eb 9e                	jmp    f01042fb <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010435d:	89 c2                	mov    %eax,%edx
f010435f:	f7 da                	neg    %edx
f0104361:	85 ff                	test   %edi,%edi
f0104363:	0f 45 c2             	cmovne %edx,%eax
}
f0104366:	5b                   	pop    %ebx
f0104367:	5e                   	pop    %esi
f0104368:	5f                   	pop    %edi
f0104369:	5d                   	pop    %ebp
f010436a:	c3                   	ret    
f010436b:	66 90                	xchg   %ax,%ax
f010436d:	66 90                	xchg   %ax,%ax
f010436f:	90                   	nop

f0104370 <__udivdi3>:
f0104370:	55                   	push   %ebp
f0104371:	57                   	push   %edi
f0104372:	56                   	push   %esi
f0104373:	53                   	push   %ebx
f0104374:	83 ec 1c             	sub    $0x1c,%esp
f0104377:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010437b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010437f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104383:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104387:	85 f6                	test   %esi,%esi
f0104389:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010438d:	89 ca                	mov    %ecx,%edx
f010438f:	89 f8                	mov    %edi,%eax
f0104391:	75 3d                	jne    f01043d0 <__udivdi3+0x60>
f0104393:	39 cf                	cmp    %ecx,%edi
f0104395:	0f 87 c5 00 00 00    	ja     f0104460 <__udivdi3+0xf0>
f010439b:	85 ff                	test   %edi,%edi
f010439d:	89 fd                	mov    %edi,%ebp
f010439f:	75 0b                	jne    f01043ac <__udivdi3+0x3c>
f01043a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01043a6:	31 d2                	xor    %edx,%edx
f01043a8:	f7 f7                	div    %edi
f01043aa:	89 c5                	mov    %eax,%ebp
f01043ac:	89 c8                	mov    %ecx,%eax
f01043ae:	31 d2                	xor    %edx,%edx
f01043b0:	f7 f5                	div    %ebp
f01043b2:	89 c1                	mov    %eax,%ecx
f01043b4:	89 d8                	mov    %ebx,%eax
f01043b6:	89 cf                	mov    %ecx,%edi
f01043b8:	f7 f5                	div    %ebp
f01043ba:	89 c3                	mov    %eax,%ebx
f01043bc:	89 d8                	mov    %ebx,%eax
f01043be:	89 fa                	mov    %edi,%edx
f01043c0:	83 c4 1c             	add    $0x1c,%esp
f01043c3:	5b                   	pop    %ebx
f01043c4:	5e                   	pop    %esi
f01043c5:	5f                   	pop    %edi
f01043c6:	5d                   	pop    %ebp
f01043c7:	c3                   	ret    
f01043c8:	90                   	nop
f01043c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01043d0:	39 ce                	cmp    %ecx,%esi
f01043d2:	77 74                	ja     f0104448 <__udivdi3+0xd8>
f01043d4:	0f bd fe             	bsr    %esi,%edi
f01043d7:	83 f7 1f             	xor    $0x1f,%edi
f01043da:	0f 84 98 00 00 00    	je     f0104478 <__udivdi3+0x108>
f01043e0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01043e5:	89 f9                	mov    %edi,%ecx
f01043e7:	89 c5                	mov    %eax,%ebp
f01043e9:	29 fb                	sub    %edi,%ebx
f01043eb:	d3 e6                	shl    %cl,%esi
f01043ed:	89 d9                	mov    %ebx,%ecx
f01043ef:	d3 ed                	shr    %cl,%ebp
f01043f1:	89 f9                	mov    %edi,%ecx
f01043f3:	d3 e0                	shl    %cl,%eax
f01043f5:	09 ee                	or     %ebp,%esi
f01043f7:	89 d9                	mov    %ebx,%ecx
f01043f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01043fd:	89 d5                	mov    %edx,%ebp
f01043ff:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104403:	d3 ed                	shr    %cl,%ebp
f0104405:	89 f9                	mov    %edi,%ecx
f0104407:	d3 e2                	shl    %cl,%edx
f0104409:	89 d9                	mov    %ebx,%ecx
f010440b:	d3 e8                	shr    %cl,%eax
f010440d:	09 c2                	or     %eax,%edx
f010440f:	89 d0                	mov    %edx,%eax
f0104411:	89 ea                	mov    %ebp,%edx
f0104413:	f7 f6                	div    %esi
f0104415:	89 d5                	mov    %edx,%ebp
f0104417:	89 c3                	mov    %eax,%ebx
f0104419:	f7 64 24 0c          	mull   0xc(%esp)
f010441d:	39 d5                	cmp    %edx,%ebp
f010441f:	72 10                	jb     f0104431 <__udivdi3+0xc1>
f0104421:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104425:	89 f9                	mov    %edi,%ecx
f0104427:	d3 e6                	shl    %cl,%esi
f0104429:	39 c6                	cmp    %eax,%esi
f010442b:	73 07                	jae    f0104434 <__udivdi3+0xc4>
f010442d:	39 d5                	cmp    %edx,%ebp
f010442f:	75 03                	jne    f0104434 <__udivdi3+0xc4>
f0104431:	83 eb 01             	sub    $0x1,%ebx
f0104434:	31 ff                	xor    %edi,%edi
f0104436:	89 d8                	mov    %ebx,%eax
f0104438:	89 fa                	mov    %edi,%edx
f010443a:	83 c4 1c             	add    $0x1c,%esp
f010443d:	5b                   	pop    %ebx
f010443e:	5e                   	pop    %esi
f010443f:	5f                   	pop    %edi
f0104440:	5d                   	pop    %ebp
f0104441:	c3                   	ret    
f0104442:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104448:	31 ff                	xor    %edi,%edi
f010444a:	31 db                	xor    %ebx,%ebx
f010444c:	89 d8                	mov    %ebx,%eax
f010444e:	89 fa                	mov    %edi,%edx
f0104450:	83 c4 1c             	add    $0x1c,%esp
f0104453:	5b                   	pop    %ebx
f0104454:	5e                   	pop    %esi
f0104455:	5f                   	pop    %edi
f0104456:	5d                   	pop    %ebp
f0104457:	c3                   	ret    
f0104458:	90                   	nop
f0104459:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104460:	89 d8                	mov    %ebx,%eax
f0104462:	f7 f7                	div    %edi
f0104464:	31 ff                	xor    %edi,%edi
f0104466:	89 c3                	mov    %eax,%ebx
f0104468:	89 d8                	mov    %ebx,%eax
f010446a:	89 fa                	mov    %edi,%edx
f010446c:	83 c4 1c             	add    $0x1c,%esp
f010446f:	5b                   	pop    %ebx
f0104470:	5e                   	pop    %esi
f0104471:	5f                   	pop    %edi
f0104472:	5d                   	pop    %ebp
f0104473:	c3                   	ret    
f0104474:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104478:	39 ce                	cmp    %ecx,%esi
f010447a:	72 0c                	jb     f0104488 <__udivdi3+0x118>
f010447c:	31 db                	xor    %ebx,%ebx
f010447e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104482:	0f 87 34 ff ff ff    	ja     f01043bc <__udivdi3+0x4c>
f0104488:	bb 01 00 00 00       	mov    $0x1,%ebx
f010448d:	e9 2a ff ff ff       	jmp    f01043bc <__udivdi3+0x4c>
f0104492:	66 90                	xchg   %ax,%ax
f0104494:	66 90                	xchg   %ax,%ax
f0104496:	66 90                	xchg   %ax,%ax
f0104498:	66 90                	xchg   %ax,%ax
f010449a:	66 90                	xchg   %ax,%ax
f010449c:	66 90                	xchg   %ax,%ax
f010449e:	66 90                	xchg   %ax,%ax

f01044a0 <__umoddi3>:
f01044a0:	55                   	push   %ebp
f01044a1:	57                   	push   %edi
f01044a2:	56                   	push   %esi
f01044a3:	53                   	push   %ebx
f01044a4:	83 ec 1c             	sub    $0x1c,%esp
f01044a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01044ab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01044af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01044b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01044b7:	85 d2                	test   %edx,%edx
f01044b9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01044bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01044c1:	89 f3                	mov    %esi,%ebx
f01044c3:	89 3c 24             	mov    %edi,(%esp)
f01044c6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01044ca:	75 1c                	jne    f01044e8 <__umoddi3+0x48>
f01044cc:	39 f7                	cmp    %esi,%edi
f01044ce:	76 50                	jbe    f0104520 <__umoddi3+0x80>
f01044d0:	89 c8                	mov    %ecx,%eax
f01044d2:	89 f2                	mov    %esi,%edx
f01044d4:	f7 f7                	div    %edi
f01044d6:	89 d0                	mov    %edx,%eax
f01044d8:	31 d2                	xor    %edx,%edx
f01044da:	83 c4 1c             	add    $0x1c,%esp
f01044dd:	5b                   	pop    %ebx
f01044de:	5e                   	pop    %esi
f01044df:	5f                   	pop    %edi
f01044e0:	5d                   	pop    %ebp
f01044e1:	c3                   	ret    
f01044e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01044e8:	39 f2                	cmp    %esi,%edx
f01044ea:	89 d0                	mov    %edx,%eax
f01044ec:	77 52                	ja     f0104540 <__umoddi3+0xa0>
f01044ee:	0f bd ea             	bsr    %edx,%ebp
f01044f1:	83 f5 1f             	xor    $0x1f,%ebp
f01044f4:	75 5a                	jne    f0104550 <__umoddi3+0xb0>
f01044f6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01044fa:	0f 82 e0 00 00 00    	jb     f01045e0 <__umoddi3+0x140>
f0104500:	39 0c 24             	cmp    %ecx,(%esp)
f0104503:	0f 86 d7 00 00 00    	jbe    f01045e0 <__umoddi3+0x140>
f0104509:	8b 44 24 08          	mov    0x8(%esp),%eax
f010450d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104511:	83 c4 1c             	add    $0x1c,%esp
f0104514:	5b                   	pop    %ebx
f0104515:	5e                   	pop    %esi
f0104516:	5f                   	pop    %edi
f0104517:	5d                   	pop    %ebp
f0104518:	c3                   	ret    
f0104519:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104520:	85 ff                	test   %edi,%edi
f0104522:	89 fd                	mov    %edi,%ebp
f0104524:	75 0b                	jne    f0104531 <__umoddi3+0x91>
f0104526:	b8 01 00 00 00       	mov    $0x1,%eax
f010452b:	31 d2                	xor    %edx,%edx
f010452d:	f7 f7                	div    %edi
f010452f:	89 c5                	mov    %eax,%ebp
f0104531:	89 f0                	mov    %esi,%eax
f0104533:	31 d2                	xor    %edx,%edx
f0104535:	f7 f5                	div    %ebp
f0104537:	89 c8                	mov    %ecx,%eax
f0104539:	f7 f5                	div    %ebp
f010453b:	89 d0                	mov    %edx,%eax
f010453d:	eb 99                	jmp    f01044d8 <__umoddi3+0x38>
f010453f:	90                   	nop
f0104540:	89 c8                	mov    %ecx,%eax
f0104542:	89 f2                	mov    %esi,%edx
f0104544:	83 c4 1c             	add    $0x1c,%esp
f0104547:	5b                   	pop    %ebx
f0104548:	5e                   	pop    %esi
f0104549:	5f                   	pop    %edi
f010454a:	5d                   	pop    %ebp
f010454b:	c3                   	ret    
f010454c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104550:	8b 34 24             	mov    (%esp),%esi
f0104553:	bf 20 00 00 00       	mov    $0x20,%edi
f0104558:	89 e9                	mov    %ebp,%ecx
f010455a:	29 ef                	sub    %ebp,%edi
f010455c:	d3 e0                	shl    %cl,%eax
f010455e:	89 f9                	mov    %edi,%ecx
f0104560:	89 f2                	mov    %esi,%edx
f0104562:	d3 ea                	shr    %cl,%edx
f0104564:	89 e9                	mov    %ebp,%ecx
f0104566:	09 c2                	or     %eax,%edx
f0104568:	89 d8                	mov    %ebx,%eax
f010456a:	89 14 24             	mov    %edx,(%esp)
f010456d:	89 f2                	mov    %esi,%edx
f010456f:	d3 e2                	shl    %cl,%edx
f0104571:	89 f9                	mov    %edi,%ecx
f0104573:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104577:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010457b:	d3 e8                	shr    %cl,%eax
f010457d:	89 e9                	mov    %ebp,%ecx
f010457f:	89 c6                	mov    %eax,%esi
f0104581:	d3 e3                	shl    %cl,%ebx
f0104583:	89 f9                	mov    %edi,%ecx
f0104585:	89 d0                	mov    %edx,%eax
f0104587:	d3 e8                	shr    %cl,%eax
f0104589:	89 e9                	mov    %ebp,%ecx
f010458b:	09 d8                	or     %ebx,%eax
f010458d:	89 d3                	mov    %edx,%ebx
f010458f:	89 f2                	mov    %esi,%edx
f0104591:	f7 34 24             	divl   (%esp)
f0104594:	89 d6                	mov    %edx,%esi
f0104596:	d3 e3                	shl    %cl,%ebx
f0104598:	f7 64 24 04          	mull   0x4(%esp)
f010459c:	39 d6                	cmp    %edx,%esi
f010459e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01045a2:	89 d1                	mov    %edx,%ecx
f01045a4:	89 c3                	mov    %eax,%ebx
f01045a6:	72 08                	jb     f01045b0 <__umoddi3+0x110>
f01045a8:	75 11                	jne    f01045bb <__umoddi3+0x11b>
f01045aa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01045ae:	73 0b                	jae    f01045bb <__umoddi3+0x11b>
f01045b0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01045b4:	1b 14 24             	sbb    (%esp),%edx
f01045b7:	89 d1                	mov    %edx,%ecx
f01045b9:	89 c3                	mov    %eax,%ebx
f01045bb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01045bf:	29 da                	sub    %ebx,%edx
f01045c1:	19 ce                	sbb    %ecx,%esi
f01045c3:	89 f9                	mov    %edi,%ecx
f01045c5:	89 f0                	mov    %esi,%eax
f01045c7:	d3 e0                	shl    %cl,%eax
f01045c9:	89 e9                	mov    %ebp,%ecx
f01045cb:	d3 ea                	shr    %cl,%edx
f01045cd:	89 e9                	mov    %ebp,%ecx
f01045cf:	d3 ee                	shr    %cl,%esi
f01045d1:	09 d0                	or     %edx,%eax
f01045d3:	89 f2                	mov    %esi,%edx
f01045d5:	83 c4 1c             	add    $0x1c,%esp
f01045d8:	5b                   	pop    %ebx
f01045d9:	5e                   	pop    %esi
f01045da:	5f                   	pop    %edi
f01045db:	5d                   	pop    %ebp
f01045dc:	c3                   	ret    
f01045dd:	8d 76 00             	lea    0x0(%esi),%esi
f01045e0:	29 f9                	sub    %edi,%ecx
f01045e2:	19 d6                	sbb    %edx,%esi
f01045e4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01045e8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01045ec:	e9 18 ff ff ff       	jmp    f0104509 <__umoddi3+0x69>
