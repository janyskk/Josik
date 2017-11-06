
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

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
f0100046:	b8 50 2c 17 f0       	mov    $0xf0172c50,%eax
f010004b:	2d 26 1d 17 f0       	sub    $0xf0171d26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 1d 17 f0       	push   $0xf0171d26
f0100058:	e8 5d 43 00 00       	call   f01043ba <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 48 10 f0       	push   $0xf0104860
f010006f:	e8 74 2f 00 00       	call   f0102fe8 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 f8 0f 00 00       	call   f0101071 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 b5 29 00 00       	call   f0102a33 <env_init>
	trap_init();
f010007e:	e8 d6 2f 00 00       	call   f0103059 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 46 44 14 f0       	push   $0xf0144446
f010008d:	e8 4f 2b 00 00       	call   f0102be1 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 88 1f 17 f0    	pushl  0xf0171f88
f010009b:	e8 7f 2e 00 00       	call   f0102f1f <env_run>

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
f01000a8:	83 3d 40 2c 17 f0 00 	cmpl   $0x0,0xf0172c40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 2c 17 f0    	mov    %esi,0xf0172c40

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
f01000c5:	68 7b 48 10 f0       	push   $0xf010487b
f01000ca:	e8 19 2f 00 00       	call   f0102fe8 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 e9 2e 00 00       	call   f0102fc2 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 94 58 10 f0 	movl   $0xf0105894,(%esp)
f01000e0:	e8 03 2f 00 00       	call   f0102fe8 <cprintf>
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
f0100107:	68 93 48 10 f0       	push   $0xf0104893
f010010c:	e8 d7 2e 00 00       	call   f0102fe8 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 a5 2e 00 00       	call   f0102fc2 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 94 58 10 f0 	movl   $0xf0105894,(%esp)
f0100124:	e8 bf 2e 00 00       	call   f0102fe8 <cprintf>
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
f010015f:	8b 0d 64 1f 17 f0    	mov    0xf0171f64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 1f 17 f0    	mov    %edx,0xf0171f64
f010016e:	88 81 60 1d 17 f0    	mov    %al,-0xfe8e2a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 1f 17 f0 00 	movl   $0x0,0xf0171f64
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
f01001b5:	83 0d 40 1d 17 f0 40 	orl    $0x40,0xf0171d40
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
f01001cd:	8b 0d 40 1d 17 f0    	mov    0xf0171d40,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 00 4a 10 f0 	movzbl -0xfefb600(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 40 1d 17 f0       	mov    %eax,0xf0171d40
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 40 1d 17 f0    	mov    0xf0171d40,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 40 1d 17 f0    	mov    %ecx,0xf0171d40
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 00 4a 10 f0 	movzbl -0xfefb600(%edx),%eax
f0100226:	0b 05 40 1d 17 f0    	or     0xf0171d40,%eax
f010022c:	0f b6 8a 00 49 10 f0 	movzbl -0xfefb700(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 40 1d 17 f0       	mov    %eax,0xf0171d40

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d e0 48 10 f0 	mov    -0xfefb720(,%ecx,4),%ecx
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
f010027d:	68 ad 48 10 f0       	push   $0xf01048ad
f0100282:	e8 61 2d 00 00       	call   f0102fe8 <cprintf>
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
f0100369:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 68 1f 17 f0 	addw   $0x50,0xf0171f68
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
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
f01003f3:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 68 1f 17 f0 	mov    %dx,0xf0171f68
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 68 1f 17 f0 	cmpw   $0x7cf,0xf0171f68
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 6c 1f 17 f0       	mov    0xf0171f6c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 d1 3f 00 00       	call   f0104407 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
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
f0100457:	66 83 2d 68 1f 17 f0 	subw   $0x50,0xf0171f68
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 70 1f 17 f0    	mov    0xf0171f70,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 68 1f 17 f0 	movzwl 0xf0171f68,%ebx
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
f0100495:	80 3d 74 1f 17 f0 00 	cmpb   $0x0,0xf0171f74
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
f01004d3:	a1 60 1f 17 f0       	mov    0xf0171f60,%eax
f01004d8:	3b 05 64 1f 17 f0    	cmp    0xf0171f64,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 60 1f 17 f0    	mov    %edx,0xf0171f60
f01004e9:	0f b6 88 60 1d 17 f0 	movzbl -0xfe8e2a0(%eax),%ecx
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
f01004fa:	c7 05 60 1f 17 f0 00 	movl   $0x0,0xf0171f60
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
f0100533:	c7 05 70 1f 17 f0 b4 	movl   $0x3b4,0xf0171f70
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
f010054b:	c7 05 70 1f 17 f0 d4 	movl   $0x3d4,0xf0171f70
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
f010055a:	8b 3d 70 1f 17 f0    	mov    0xf0171f70,%edi
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
f010057f:	89 35 6c 1f 17 f0    	mov    %esi,0xf0171f6c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
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
f01005eb:	0f 95 05 74 1f 17 f0 	setne  0xf0171f74
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
f0100600:	68 b9 48 10 f0       	push   $0xf01048b9
f0100605:	e8 de 29 00 00       	call   f0102fe8 <cprintf>
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
f0100646:	68 00 4b 10 f0       	push   $0xf0104b00
f010064b:	68 1e 4b 10 f0       	push   $0xf0104b1e
f0100650:	68 23 4b 10 f0       	push   $0xf0104b23
f0100655:	e8 8e 29 00 00       	call   f0102fe8 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 f8 4b 10 f0       	push   $0xf0104bf8
f0100662:	68 2c 4b 10 f0       	push   $0xf0104b2c
f0100667:	68 23 4b 10 f0       	push   $0xf0104b23
f010066c:	e8 77 29 00 00       	call   f0102fe8 <cprintf>
f0100671:	83 c4 0c             	add    $0xc,%esp
f0100674:	68 35 4b 10 f0       	push   $0xf0104b35
f0100679:	68 52 4b 10 f0       	push   $0xf0104b52
f010067e:	68 23 4b 10 f0       	push   $0xf0104b23
f0100683:	e8 60 29 00 00       	call   f0102fe8 <cprintf>
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
f0100695:	68 5c 4b 10 f0       	push   $0xf0104b5c
f010069a:	e8 49 29 00 00       	call   f0102fe8 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010069f:	83 c4 08             	add    $0x8,%esp
f01006a2:	68 0c 00 10 00       	push   $0x10000c
f01006a7:	68 20 4c 10 f0       	push   $0xf0104c20
f01006ac:	e8 37 29 00 00       	call   f0102fe8 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 0c 00 10 00       	push   $0x10000c
f01006b9:	68 0c 00 10 f0       	push   $0xf010000c
f01006be:	68 48 4c 10 f0       	push   $0xf0104c48
f01006c3:	e8 20 29 00 00       	call   f0102fe8 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 41 48 10 00       	push   $0x104841
f01006d0:	68 41 48 10 f0       	push   $0xf0104841
f01006d5:	68 6c 4c 10 f0       	push   $0xf0104c6c
f01006da:	e8 09 29 00 00       	call   f0102fe8 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 26 1d 17 00       	push   $0x171d26
f01006e7:	68 26 1d 17 f0       	push   $0xf0171d26
f01006ec:	68 90 4c 10 f0       	push   $0xf0104c90
f01006f1:	e8 f2 28 00 00       	call   f0102fe8 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006f6:	83 c4 0c             	add    $0xc,%esp
f01006f9:	68 50 2c 17 00       	push   $0x172c50
f01006fe:	68 50 2c 17 f0       	push   $0xf0172c50
f0100703:	68 b4 4c 10 f0       	push   $0xf0104cb4
f0100708:	e8 db 28 00 00       	call   f0102fe8 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010070d:	b8 4f 30 17 f0       	mov    $0xf017304f,%eax
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
f010072e:	68 d8 4c 10 f0       	push   $0xf0104cd8
f0100733:	e8 b0 28 00 00       	call   f0102fe8 <cprintf>
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
f010074a:	68 75 4b 10 f0       	push   $0xf0104b75
f010074f:	e8 94 28 00 00       	call   f0102fe8 <cprintf>
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
f0100764:	68 86 4b 10 f0       	push   $0xf0104b86
f0100769:	e8 7a 28 00 00       	call   f0102fe8 <cprintf>
f010076e:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100771:	83 c6 1c             	add    $0x1c,%esi
f0100774:	83 c4 10             	add    $0x10,%esp

    int argno = 0;
    for(; argno < 5; argno++){
      cprintf("%08x ", *(ebpp+2+argno));
f0100777:	83 ec 08             	sub    $0x8,%esp
f010077a:	ff 33                	pushl  (%ebx)
f010077c:	68 a1 4b 10 f0       	push   $0xf0104ba1
f0100781:	e8 62 28 00 00       	call   f0102fe8 <cprintf>
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
f0100798:	e8 cc 31 00 00       	call   f0103969 <debuginfo_eip>
f010079d:	83 c4 10             	add    $0x10,%esp
f01007a0:	85 c0                	test   %eax,%eax
f01007a2:	75 2a                	jne    f01007ce <mon_backtrace+0x8f>
      cprintf("\n\t%s:%d: ", info.eip_file, info.eip_line);
f01007a4:	83 ec 04             	sub    $0x4,%esp
f01007a7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007aa:	ff 75 d0             	pushl  -0x30(%ebp)
f01007ad:	68 a7 4b 10 f0       	push   $0xf0104ba7
f01007b2:	e8 31 28 00 00       	call   f0102fe8 <cprintf>
      cprintf("%.*s+%d", info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f01007b7:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01007ba:	57                   	push   %edi
f01007bb:	ff 75 d8             	pushl  -0x28(%ebp)
f01007be:	ff 75 dc             	pushl  -0x24(%ebp)
f01007c1:	68 b1 4b 10 f0       	push   $0xf0104bb1
f01007c6:	e8 1d 28 00 00       	call   f0102fe8 <cprintf>
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
f01007da:	68 94 58 10 f0       	push   $0xf0105894
f01007df:	e8 04 28 00 00       	call   f0102fe8 <cprintf>
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
f01007fa:	68 04 4d 10 f0       	push   $0xf0104d04
f01007ff:	e8 e4 27 00 00       	call   f0102fe8 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100804:	c7 04 24 28 4d 10 f0 	movl   $0xf0104d28,(%esp)
f010080b:	e8 d8 27 00 00       	call   f0102fe8 <cprintf>

	if (tf != NULL)
f0100810:	83 c4 10             	add    $0x10,%esp
f0100813:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100817:	74 0e                	je     f0100827 <monitor+0x36>
		print_trapframe(tf);
f0100819:	83 ec 0c             	sub    $0xc,%esp
f010081c:	ff 75 08             	pushl  0x8(%ebp)
f010081f:	e8 fe 2b 00 00       	call   f0103422 <print_trapframe>
f0100824:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100827:	83 ec 0c             	sub    $0xc,%esp
f010082a:	68 b9 4b 10 f0       	push   $0xf0104bb9
f010082f:	e8 2f 39 00 00       	call   f0104163 <readline>
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
f0100863:	68 bd 4b 10 f0       	push   $0xf0104bbd
f0100868:	e8 10 3b 00 00       	call   f010437d <strchr>
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
f0100883:	68 c2 4b 10 f0       	push   $0xf0104bc2
f0100888:	e8 5b 27 00 00       	call   f0102fe8 <cprintf>
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
f01008ac:	68 bd 4b 10 f0       	push   $0xf0104bbd
f01008b1:	e8 c7 3a 00 00       	call   f010437d <strchr>
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
f01008da:	ff 34 85 60 4d 10 f0 	pushl  -0xfefb2a0(,%eax,4)
f01008e1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e4:	e8 36 3a 00 00       	call   f010431f <strcmp>
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
f01008fe:	ff 14 85 68 4d 10 f0 	call   *-0xfefb298(,%eax,4)
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
f010091f:	68 df 4b 10 f0       	push   $0xf0104bdf
f0100924:	e8 bf 26 00 00       	call   f0102fe8 <cprintf>
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
f0100944:	e8 38 26 00 00       	call   f0102f81 <mc146818_read>
f0100949:	89 c6                	mov    %eax,%esi
f010094b:	83 c3 01             	add    $0x1,%ebx
f010094e:	89 1c 24             	mov    %ebx,(%esp)
f0100951:	e8 2b 26 00 00       	call   f0102f81 <mc146818_read>
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
f0100978:	3b 0d 44 2c 17 f0    	cmp    0xf0172c44,%ecx
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
f0100987:	68 84 4d 10 f0       	push   $0xf0104d84
f010098c:	68 55 03 00 00       	push   $0x355
f0100991:	68 ad 55 10 f0       	push   $0xf01055ad
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
f01009cc:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) 
f01009ce:	83 3d 78 1f 17 f0 00 	cmpl   $0x0,0xf0171f78
f01009d5:	75 0f                	jne    f01009e6 <boot_alloc+0x20>
	{
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009d7:	b8 4f 3c 17 f0       	mov    $0xf0173c4f,%eax
f01009dc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009e1:	a3 78 1f 17 f0       	mov    %eax,0xf0171f78
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here

	result=nextfree;
f01009e6:	a1 78 1f 17 f0       	mov    0xf0171f78,%eax

	if(n)
f01009eb:	85 d2                	test   %edx,%edx
f01009ed:	74 4f                	je     f0100a3e <boot_alloc+0x78>
	{

		nextfree = ROUNDUP(nextfree+n,PGSIZE);
f01009ef:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009f6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009fc:	89 15 78 1f 17 f0    	mov    %edx,0xf0171f78
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100a02:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100a08:	77 12                	ja     f0100a1c <boot_alloc+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100a0a:	52                   	push   %edx
f0100a0b:	68 a8 4d 10 f0       	push   $0xf0104da8
f0100a10:	6a 73                	push   $0x73
f0100a12:	68 ad 55 10 f0       	push   $0xf01055ad
f0100a17:	e8 84 f6 ff ff       	call   f01000a0 <_panic>
		
		if(PADDR(nextfree)>=PTSIZE)
f0100a1c:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100a22:	81 fa ff ff 3f 00    	cmp    $0x3fffff,%edx
f0100a28:	76 14                	jbe    f0100a3e <boot_alloc+0x78>
		{
			panic("Trying to exceed the RAM.");
f0100a2a:	83 ec 04             	sub    $0x4,%esp
f0100a2d:	68 b9 55 10 f0       	push   $0xf01055b9
f0100a32:	6a 75                	push   $0x75
f0100a34:	68 ad 55 10 f0       	push   $0xf01055ad
f0100a39:	e8 62 f6 ff ff       	call   f01000a0 <_panic>
		}
	}
	

	return result;
}
f0100a3e:	c9                   	leave  
f0100a3f:	c3                   	ret    

f0100a40 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a40:	55                   	push   %ebp
f0100a41:	89 e5                	mov    %esp,%ebp
f0100a43:	57                   	push   %edi
f0100a44:	56                   	push   %esi
f0100a45:	53                   	push   %ebx
f0100a46:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a49:	84 c0                	test   %al,%al
f0100a4b:	0f 85 81 02 00 00    	jne    f0100cd2 <check_page_free_list+0x292>
f0100a51:	e9 8e 02 00 00       	jmp    f0100ce4 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a56:	83 ec 04             	sub    $0x4,%esp
f0100a59:	68 cc 4d 10 f0       	push   $0xf0104dcc
f0100a5e:	68 8f 02 00 00       	push   $0x28f
f0100a63:	68 ad 55 10 f0       	push   $0xf01055ad
f0100a68:	e8 33 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a6d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a70:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a73:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a76:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a79:	89 c2                	mov    %eax,%edx
f0100a7b:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0100a81:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a87:	0f 95 c2             	setne  %dl
f0100a8a:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a8d:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a91:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a93:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a97:	8b 00                	mov    (%eax),%eax
f0100a99:	85 c0                	test   %eax,%eax
f0100a9b:	75 dc                	jne    f0100a79 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a9d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100aa0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100aa6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aa9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100aac:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100aae:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ab1:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ab6:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100abb:	8b 1d 80 1f 17 f0    	mov    0xf0171f80,%ebx
f0100ac1:	eb 53                	jmp    f0100b16 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ac3:	89 d8                	mov    %ebx,%eax
f0100ac5:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0100acb:	c1 f8 03             	sar    $0x3,%eax
f0100ace:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ad1:	89 c2                	mov    %eax,%edx
f0100ad3:	c1 ea 16             	shr    $0x16,%edx
f0100ad6:	39 f2                	cmp    %esi,%edx
f0100ad8:	73 3a                	jae    f0100b14 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ada:	89 c2                	mov    %eax,%edx
f0100adc:	c1 ea 0c             	shr    $0xc,%edx
f0100adf:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100ae5:	72 12                	jb     f0100af9 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ae7:	50                   	push   %eax
f0100ae8:	68 84 4d 10 f0       	push   $0xf0104d84
f0100aed:	6a 56                	push   $0x56
f0100aef:	68 d3 55 10 f0       	push   $0xf01055d3
f0100af4:	e8 a7 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100af9:	83 ec 04             	sub    $0x4,%esp
f0100afc:	68 80 00 00 00       	push   $0x80
f0100b01:	68 97 00 00 00       	push   $0x97
f0100b06:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b0b:	50                   	push   %eax
f0100b0c:	e8 a9 38 00 00       	call   f01043ba <memset>
f0100b11:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b14:	8b 1b                	mov    (%ebx),%ebx
f0100b16:	85 db                	test   %ebx,%ebx
f0100b18:	75 a9                	jne    f0100ac3 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b1a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b1f:	e8 a2 fe ff ff       	call   f01009c6 <boot_alloc>
f0100b24:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b27:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b2d:	8b 0d 4c 2c 17 f0    	mov    0xf0172c4c,%ecx
		assert(pp < pages + npages);
f0100b33:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f0100b38:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b3b:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b3e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b41:	be 00 00 00 00       	mov    $0x0,%esi
f0100b46:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b49:	e9 30 01 00 00       	jmp    f0100c7e <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b4e:	39 ca                	cmp    %ecx,%edx
f0100b50:	73 19                	jae    f0100b6b <check_page_free_list+0x12b>
f0100b52:	68 e1 55 10 f0       	push   $0xf01055e1
f0100b57:	68 ed 55 10 f0       	push   $0xf01055ed
f0100b5c:	68 a9 02 00 00       	push   $0x2a9
f0100b61:	68 ad 55 10 f0       	push   $0xf01055ad
f0100b66:	e8 35 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b6b:	39 fa                	cmp    %edi,%edx
f0100b6d:	72 19                	jb     f0100b88 <check_page_free_list+0x148>
f0100b6f:	68 02 56 10 f0       	push   $0xf0105602
f0100b74:	68 ed 55 10 f0       	push   $0xf01055ed
f0100b79:	68 aa 02 00 00       	push   $0x2aa
f0100b7e:	68 ad 55 10 f0       	push   $0xf01055ad
f0100b83:	e8 18 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b88:	89 d0                	mov    %edx,%eax
f0100b8a:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b8d:	a8 07                	test   $0x7,%al
f0100b8f:	74 19                	je     f0100baa <check_page_free_list+0x16a>
f0100b91:	68 f0 4d 10 f0       	push   $0xf0104df0
f0100b96:	68 ed 55 10 f0       	push   $0xf01055ed
f0100b9b:	68 ab 02 00 00       	push   $0x2ab
f0100ba0:	68 ad 55 10 f0       	push   $0xf01055ad
f0100ba5:	e8 f6 f4 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100baa:	c1 f8 03             	sar    $0x3,%eax
f0100bad:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100bb0:	85 c0                	test   %eax,%eax
f0100bb2:	75 19                	jne    f0100bcd <check_page_free_list+0x18d>
f0100bb4:	68 16 56 10 f0       	push   $0xf0105616
f0100bb9:	68 ed 55 10 f0       	push   $0xf01055ed
f0100bbe:	68 ae 02 00 00       	push   $0x2ae
f0100bc3:	68 ad 55 10 f0       	push   $0xf01055ad
f0100bc8:	e8 d3 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bcd:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bd2:	75 19                	jne    f0100bed <check_page_free_list+0x1ad>
f0100bd4:	68 27 56 10 f0       	push   $0xf0105627
f0100bd9:	68 ed 55 10 f0       	push   $0xf01055ed
f0100bde:	68 af 02 00 00       	push   $0x2af
f0100be3:	68 ad 55 10 f0       	push   $0xf01055ad
f0100be8:	e8 b3 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bed:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bf2:	75 19                	jne    f0100c0d <check_page_free_list+0x1cd>
f0100bf4:	68 24 4e 10 f0       	push   $0xf0104e24
f0100bf9:	68 ed 55 10 f0       	push   $0xf01055ed
f0100bfe:	68 b0 02 00 00       	push   $0x2b0
f0100c03:	68 ad 55 10 f0       	push   $0xf01055ad
f0100c08:	e8 93 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c0d:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c12:	75 19                	jne    f0100c2d <check_page_free_list+0x1ed>
f0100c14:	68 40 56 10 f0       	push   $0xf0105640
f0100c19:	68 ed 55 10 f0       	push   $0xf01055ed
f0100c1e:	68 b1 02 00 00       	push   $0x2b1
f0100c23:	68 ad 55 10 f0       	push   $0xf01055ad
f0100c28:	e8 73 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c2d:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c32:	76 3f                	jbe    f0100c73 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c34:	89 c3                	mov    %eax,%ebx
f0100c36:	c1 eb 0c             	shr    $0xc,%ebx
f0100c39:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c3c:	77 12                	ja     f0100c50 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c3e:	50                   	push   %eax
f0100c3f:	68 84 4d 10 f0       	push   $0xf0104d84
f0100c44:	6a 56                	push   $0x56
f0100c46:	68 d3 55 10 f0       	push   $0xf01055d3
f0100c4b:	e8 50 f4 ff ff       	call   f01000a0 <_panic>
f0100c50:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c55:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c58:	76 1e                	jbe    f0100c78 <check_page_free_list+0x238>
f0100c5a:	68 48 4e 10 f0       	push   $0xf0104e48
f0100c5f:	68 ed 55 10 f0       	push   $0xf01055ed
f0100c64:	68 b2 02 00 00       	push   $0x2b2
f0100c69:	68 ad 55 10 f0       	push   $0xf01055ad
f0100c6e:	e8 2d f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c73:	83 c6 01             	add    $0x1,%esi
f0100c76:	eb 04                	jmp    f0100c7c <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c78:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c7c:	8b 12                	mov    (%edx),%edx
f0100c7e:	85 d2                	test   %edx,%edx
f0100c80:	0f 85 c8 fe ff ff    	jne    f0100b4e <check_page_free_list+0x10e>
f0100c86:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c89:	85 f6                	test   %esi,%esi
f0100c8b:	7f 19                	jg     f0100ca6 <check_page_free_list+0x266>
f0100c8d:	68 5a 56 10 f0       	push   $0xf010565a
f0100c92:	68 ed 55 10 f0       	push   $0xf01055ed
f0100c97:	68 ba 02 00 00       	push   $0x2ba
f0100c9c:	68 ad 55 10 f0       	push   $0xf01055ad
f0100ca1:	e8 fa f3 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100ca6:	85 db                	test   %ebx,%ebx
f0100ca8:	7f 19                	jg     f0100cc3 <check_page_free_list+0x283>
f0100caa:	68 6c 56 10 f0       	push   $0xf010566c
f0100caf:	68 ed 55 10 f0       	push   $0xf01055ed
f0100cb4:	68 bb 02 00 00       	push   $0x2bb
f0100cb9:	68 ad 55 10 f0       	push   $0xf01055ad
f0100cbe:	e8 dd f3 ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100cc3:	83 ec 0c             	sub    $0xc,%esp
f0100cc6:	68 90 4e 10 f0       	push   $0xf0104e90
f0100ccb:	e8 18 23 00 00       	call   f0102fe8 <cprintf>
}
f0100cd0:	eb 29                	jmp    f0100cfb <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cd2:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0100cd7:	85 c0                	test   %eax,%eax
f0100cd9:	0f 85 8e fd ff ff    	jne    f0100a6d <check_page_free_list+0x2d>
f0100cdf:	e9 72 fd ff ff       	jmp    f0100a56 <check_page_free_list+0x16>
f0100ce4:	83 3d 80 1f 17 f0 00 	cmpl   $0x0,0xf0171f80
f0100ceb:	0f 84 65 fd ff ff    	je     f0100a56 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cf1:	be 00 04 00 00       	mov    $0x400,%esi
f0100cf6:	e9 c0 fd ff ff       	jmp    f0100abb <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100cfb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cfe:	5b                   	pop    %ebx
f0100cff:	5e                   	pop    %esi
f0100d00:	5f                   	pop    %edi
f0100d01:	5d                   	pop    %ebp
f0100d02:	c3                   	ret    

f0100d03 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d03:	55                   	push   %ebp
f0100d04:	89 e5                	mov    %esp,%ebp
f0100d06:	56                   	push   %esi
f0100d07:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = npages -1; i >= 1; i--) 
f0100d08:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f0100d0d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100d10:	8d 34 c5 f8 ff ff ff 	lea    -0x8(,%eax,8),%esi
f0100d17:	eb 6e                	jmp    f0100d87 <page_init+0x84>
	{
		
		if((i >= PGNUM(IOPHYSMEM) && i < PGNUM(EXTPHYSMEM)) || (i >= PGNUM(EXTPHYSMEM) && i< PGNUM(PADDR(boot_alloc(0))))) 
f0100d19:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100d1f:	83 f8 5f             	cmp    $0x5f,%eax
f0100d22:	76 5d                	jbe    f0100d81 <page_init+0x7e>
f0100d24:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100d2a:	76 32                	jbe    f0100d5e <page_init+0x5b>
f0100d2c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d31:	e8 90 fc ff ff       	call   f01009c6 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d36:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d3b:	77 15                	ja     f0100d52 <page_init+0x4f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d3d:	50                   	push   %eax
f0100d3e:	68 a8 4d 10 f0       	push   $0xf0104da8
f0100d43:	68 32 01 00 00       	push   $0x132
f0100d48:	68 ad 55 10 f0       	push   $0xf01055ad
f0100d4d:	e8 4e f3 ff ff       	call   f01000a0 <_panic>
f0100d52:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d57:	c1 e8 0c             	shr    $0xc,%eax
f0100d5a:	39 c3                	cmp    %eax,%ebx
f0100d5c:	72 23                	jb     f0100d81 <page_init+0x7e>
			continue;
		
		else
		{
			pages[i].pp_ref=0;
f0100d5e:	89 f0                	mov    %esi,%eax
f0100d60:	03 05 4c 2c 17 f0    	add    0xf0172c4c,%eax
f0100d66:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100d6c:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
f0100d72:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100d74:	89 f0                	mov    %esi,%eax
f0100d76:	03 05 4c 2c 17 f0    	add    0xf0172c4c,%eax
f0100d7c:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = npages -1; i >= 1; i--) 
f0100d81:	83 eb 01             	sub    $0x1,%ebx
f0100d84:	83 ee 08             	sub    $0x8,%esi
f0100d87:	85 db                	test   %ebx,%ebx
f0100d89:	75 8e                	jne    f0100d19 <page_init+0x16>
			pages[i].pp_ref=0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d8b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d8e:	5b                   	pop    %ebx
f0100d8f:	5e                   	pop    %esi
f0100d90:	5d                   	pop    %ebp
f0100d91:	c3                   	ret    

f0100d92 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d92:	55                   	push   %ebp
f0100d93:	89 e5                	mov    %esp,%ebp
f0100d95:	53                   	push   %ebx
f0100d96:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	
	if(!page_free_list)
f0100d99:	8b 1d 80 1f 17 f0    	mov    0xf0171f80,%ebx
f0100d9f:	85 db                	test   %ebx,%ebx
f0100da1:	74 58                	je     f0100dfb <page_alloc+0x69>
		return NULL;	

	struct PageInfo * pa_page = page_free_list;		

	page_free_list = pa_page->pp_link;
f0100da3:	8b 03                	mov    (%ebx),%eax
f0100da5:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80

	pa_page->pp_link = NULL;
f0100daa:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if(alloc_flags & ALLOC_ZERO)
f0100db0:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100db4:	74 45                	je     f0100dfb <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100db6:	89 d8                	mov    %ebx,%eax
f0100db8:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0100dbe:	c1 f8 03             	sar    $0x3,%eax
f0100dc1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dc4:	89 c2                	mov    %eax,%edx
f0100dc6:	c1 ea 0c             	shr    $0xc,%edx
f0100dc9:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100dcf:	72 12                	jb     f0100de3 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dd1:	50                   	push   %eax
f0100dd2:	68 84 4d 10 f0       	push   $0xf0104d84
f0100dd7:	6a 56                	push   $0x56
f0100dd9:	68 d3 55 10 f0       	push   $0xf01055d3
f0100dde:	e8 bd f2 ff ff       	call   f01000a0 <_panic>
	{
		memset(page2kva(pa_page),'\0',PGSIZE);
f0100de3:	83 ec 04             	sub    $0x4,%esp
f0100de6:	68 00 10 00 00       	push   $0x1000
f0100deb:	6a 00                	push   $0x0
f0100ded:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100df2:	50                   	push   %eax
f0100df3:	e8 c2 35 00 00       	call   f01043ba <memset>
f0100df8:	83 c4 10             	add    $0x10,%esp
	}
	
	return pa_page;
}
f0100dfb:	89 d8                	mov    %ebx,%eax
f0100dfd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e00:	c9                   	leave  
f0100e01:	c3                   	ret    

f0100e02 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e02:	55                   	push   %ebp
f0100e03:	89 e5                	mov    %esp,%ebp
f0100e05:	83 ec 08             	sub    $0x8,%esp
f0100e08:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_link || pp->pp_ref)
f0100e0b:	83 38 00             	cmpl   $0x0,(%eax)
f0100e0e:	75 07                	jne    f0100e17 <page_free+0x15>
f0100e10:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e15:	74 17                	je     f0100e2e <page_free+0x2c>
		panic("Trying to free page in use!");
f0100e17:	83 ec 04             	sub    $0x4,%esp
f0100e1a:	68 7d 56 10 f0       	push   $0xf010567d
f0100e1f:	68 68 01 00 00       	push   $0x168
f0100e24:	68 ad 55 10 f0       	push   $0xf01055ad
f0100e29:	e8 72 f2 ff ff       	call   f01000a0 <_panic>

	pp->pp_link=page_free_list;
f0100e2e:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
f0100e34:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;	
f0100e36:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80

	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100e3b:	c9                   	leave  
f0100e3c:	c3                   	ret    

f0100e3d <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e3d:	55                   	push   %ebp
f0100e3e:	89 e5                	mov    %esp,%ebp
f0100e40:	83 ec 08             	sub    $0x8,%esp
f0100e43:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e46:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e4a:	83 e8 01             	sub    $0x1,%eax
f0100e4d:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e51:	66 85 c0             	test   %ax,%ax
f0100e54:	75 0c                	jne    f0100e62 <page_decref+0x25>
		page_free(pp);
f0100e56:	83 ec 0c             	sub    $0xc,%esp
f0100e59:	52                   	push   %edx
f0100e5a:	e8 a3 ff ff ff       	call   f0100e02 <page_free>
f0100e5f:	83 c4 10             	add    $0x10,%esp
}
f0100e62:	c9                   	leave  
f0100e63:	c3                   	ret    

f0100e64 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e64:	55                   	push   %ebp
f0100e65:	89 e5                	mov    %esp,%ebp
f0100e67:	56                   	push   %esi
f0100e68:	53                   	push   %ebx
f0100e69:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	
	pde_t *pde = &pgdir[PDX(va)];
f0100e6c:	89 f3                	mov    %esi,%ebx
f0100e6e:	c1 eb 16             	shr    $0x16,%ebx
f0100e71:	c1 e3 02             	shl    $0x2,%ebx
f0100e74:	03 5d 08             	add    0x8(%ebp),%ebx

	if(!(*pde & PTE_P))
f0100e77:	f6 03 01             	testb  $0x1,(%ebx)
f0100e7a:	75 2d                	jne    f0100ea9 <pgdir_walk+0x45>
	{
		if(!create)
f0100e7c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e80:	74 62                	je     f0100ee4 <pgdir_walk+0x80>
			return NULL;

		struct PageInfo *pp = page_alloc(ALLOC_ZERO);
f0100e82:	83 ec 0c             	sub    $0xc,%esp
f0100e85:	6a 01                	push   $0x1
f0100e87:	e8 06 ff ff ff       	call   f0100d92 <page_alloc>

		if(!pp)
f0100e8c:	83 c4 10             	add    $0x10,%esp
f0100e8f:	85 c0                	test   %eax,%eax
f0100e91:	74 58                	je     f0100eeb <pgdir_walk+0x87>
			return NULL;

		pp->pp_ref++;
f0100e93:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		*pde = page2pa(pp)|PTE_P|PTE_W|PTE_U;
f0100e98:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0100e9e:	c1 f8 03             	sar    $0x3,%eax
f0100ea1:	c1 e0 0c             	shl    $0xc,%eax
f0100ea4:	83 c8 07             	or     $0x7,%eax
f0100ea7:	89 03                	mov    %eax,(%ebx)
	}

	pte_t *pte = KADDR(PTE_ADDR(*pde));
f0100ea9:	8b 03                	mov    (%ebx),%eax
f0100eab:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb0:	89 c2                	mov    %eax,%edx
f0100eb2:	c1 ea 0c             	shr    $0xc,%edx
f0100eb5:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100ebb:	72 15                	jb     f0100ed2 <pgdir_walk+0x6e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ebd:	50                   	push   %eax
f0100ebe:	68 84 4d 10 f0       	push   $0xf0104d84
f0100ec3:	68 a8 01 00 00       	push   $0x1a8
f0100ec8:	68 ad 55 10 f0       	push   $0xf01055ad
f0100ecd:	e8 ce f1 ff ff       	call   f01000a0 <_panic>
	pte = &pte[PTX(va)];
f0100ed2:	c1 ee 0a             	shr    $0xa,%esi
f0100ed5:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
	
	return pte;
f0100edb:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100ee2:	eb 0c                	jmp    f0100ef0 <pgdir_walk+0x8c>
	pde_t *pde = &pgdir[PDX(va)];

	if(!(*pde & PTE_P))
	{
		if(!create)
			return NULL;
f0100ee4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ee9:	eb 05                	jmp    f0100ef0 <pgdir_walk+0x8c>

		struct PageInfo *pp = page_alloc(ALLOC_ZERO);

		if(!pp)
			return NULL;
f0100eeb:	b8 00 00 00 00       	mov    $0x0,%eax

	pte_t *pte = KADDR(PTE_ADDR(*pde));
	pte = &pte[PTX(va)];
	
	return pte;
}
f0100ef0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ef3:	5b                   	pop    %ebx
f0100ef4:	5e                   	pop    %esi
f0100ef5:	5d                   	pop    %ebp
f0100ef6:	c3                   	ret    

f0100ef7 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ef7:	55                   	push   %ebp
f0100ef8:	89 e5                	mov    %esp,%ebp
f0100efa:	57                   	push   %edi
f0100efb:	56                   	push   %esi
f0100efc:	53                   	push   %ebx
f0100efd:	83 ec 1c             	sub    $0x1c,%esp
f0100f00:	89 c7                	mov    %eax,%edi
f0100f02:	89 d6                	mov    %edx,%esi
f0100f04:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in

	for(int i=0;i<size;i+=PGSIZE)
f0100f07:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		pte_t *pte = pgdir_walk(pgdir,(void*)(va+i),1);
		*pte = (pa+i)|perm|PTE_P;
f0100f0c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f0f:	83 c8 01             	or     $0x1,%eax
f0100f12:	89 45 e0             	mov    %eax,-0x20(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in

	for(int i=0;i<size;i+=PGSIZE)
f0100f15:	eb 22                	jmp    f0100f39 <boot_map_region+0x42>
	{
		pte_t *pte = pgdir_walk(pgdir,(void*)(va+i),1);
f0100f17:	83 ec 04             	sub    $0x4,%esp
f0100f1a:	6a 01                	push   $0x1
f0100f1c:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f0100f1f:	50                   	push   %eax
f0100f20:	57                   	push   %edi
f0100f21:	e8 3e ff ff ff       	call   f0100e64 <pgdir_walk>
		*pte = (pa+i)|perm|PTE_P;
f0100f26:	89 da                	mov    %ebx,%edx
f0100f28:	03 55 08             	add    0x8(%ebp),%edx
f0100f2b:	0b 55 e0             	or     -0x20(%ebp),%edx
f0100f2e:	89 10                	mov    %edx,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in

	for(int i=0;i<size;i+=PGSIZE)
f0100f30:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f36:	83 c4 10             	add    $0x10,%esp
f0100f39:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100f3c:	77 d9                	ja     f0100f17 <boot_map_region+0x20>
	{
		pte_t *pte = pgdir_walk(pgdir,(void*)(va+i),1);
		*pte = (pa+i)|perm|PTE_P;
	}
}
f0100f3e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f41:	5b                   	pop    %ebx
f0100f42:	5e                   	pop    %esi
f0100f43:	5f                   	pop    %edi
f0100f44:	5d                   	pop    %ebp
f0100f45:	c3                   	ret    

f0100f46 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f46:	55                   	push   %ebp
f0100f47:	89 e5                	mov    %esp,%ebp
f0100f49:	83 ec 0c             	sub    $0xc,%esp
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,0);
f0100f4c:	6a 00                	push   $0x0
f0100f4e:	ff 75 0c             	pushl  0xc(%ebp)
f0100f51:	ff 75 08             	pushl  0x8(%ebp)
f0100f54:	e8 0b ff ff ff       	call   f0100e64 <pgdir_walk>

	if((!pte) || !(*pte & PTE_P))
f0100f59:	83 c4 10             	add    $0x10,%esp
f0100f5c:	85 c0                	test   %eax,%eax
f0100f5e:	74 30                	je     f0100f90 <page_lookup+0x4a>
f0100f60:	8b 00                	mov    (%eax),%eax
f0100f62:	a8 01                	test   $0x1,%al
f0100f64:	74 31                	je     f0100f97 <page_lookup+0x51>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f66:	c1 e8 0c             	shr    $0xc,%eax
f0100f69:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0100f6f:	72 14                	jb     f0100f85 <page_lookup+0x3f>
		panic("pa2page called with invalid pa");
f0100f71:	83 ec 04             	sub    $0x4,%esp
f0100f74:	68 b4 4e 10 f0       	push   $0xf0104eb4
f0100f79:	6a 4f                	push   $0x4f
f0100f7b:	68 d3 55 10 f0       	push   $0xf01055d3
f0100f80:	e8 1b f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f85:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f0100f8b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		return NULL;

	if(pte_store)
		pte_store = &pte;	

	return pa2page(PTE_ADDR(*pte));
f0100f8e:	eb 0c                	jmp    f0100f9c <page_lookup+0x56>
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,0);

	if((!pte) || !(*pte & PTE_P))
		return NULL;
f0100f90:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f95:	eb 05                	jmp    f0100f9c <page_lookup+0x56>
f0100f97:	b8 00 00 00 00       	mov    $0x0,%eax

	if(pte_store)
		pte_store = &pte;	

	return pa2page(PTE_ADDR(*pte));
}
f0100f9c:	c9                   	leave  
f0100f9d:	c3                   	ret    

f0100f9e <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f9e:	55                   	push   %ebp
f0100f9f:	89 e5                	mov    %esp,%ebp
f0100fa1:	56                   	push   %esi
f0100fa2:	53                   	push   %ebx
f0100fa3:	83 ec 14             	sub    $0x14,%esp
f0100fa6:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fa9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,0);
f0100fac:	6a 00                	push   $0x0
f0100fae:	53                   	push   %ebx
f0100faf:	56                   	push   %esi
f0100fb0:	e8 af fe ff ff       	call   f0100e64 <pgdir_walk>
f0100fb5:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(*pte & PTE_P)
f0100fb8:	83 c4 10             	add    $0x10,%esp
f0100fbb:	f6 00 01             	testb  $0x1,(%eax)
f0100fbe:	74 25                	je     f0100fe5 <page_remove+0x47>
	{
		page_decref(page_lookup(pgdir,va,&pte));
f0100fc0:	83 ec 04             	sub    $0x4,%esp
f0100fc3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fc6:	50                   	push   %eax
f0100fc7:	53                   	push   %ebx
f0100fc8:	56                   	push   %esi
f0100fc9:	e8 78 ff ff ff       	call   f0100f46 <page_lookup>
f0100fce:	89 04 24             	mov    %eax,(%esp)
f0100fd1:	e8 67 fe ff ff       	call   f0100e3d <page_decref>
		*pte = 0;
f0100fd6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fd9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fdf:	0f 01 3b             	invlpg (%ebx)
f0100fe2:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir,va);
	}
}
f0100fe5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fe8:	5b                   	pop    %ebx
f0100fe9:	5e                   	pop    %esi
f0100fea:	5d                   	pop    %ebp
f0100feb:	c3                   	ret    

f0100fec <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100fec:	55                   	push   %ebp
f0100fed:	89 e5                	mov    %esp,%ebp
f0100fef:	57                   	push   %edi
f0100ff0:	56                   	push   %esi
f0100ff1:	53                   	push   %ebx
f0100ff2:	83 ec 10             	sub    $0x10,%esp
f0100ff5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ff8:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,1);
f0100ffb:	6a 01                	push   $0x1
f0100ffd:	57                   	push   %edi
f0100ffe:	ff 75 08             	pushl  0x8(%ebp)
f0101001:	e8 5e fe ff ff       	call   f0100e64 <pgdir_walk>
	
	if(!pte)
f0101006:	83 c4 10             	add    $0x10,%esp
f0101009:	85 c0                	test   %eax,%eax
f010100b:	74 57                	je     f0101064 <page_insert+0x78>
f010100d:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	
	if(*pte & PTE_P)
f010100f:	8b 00                	mov    (%eax),%eax
f0101011:	a8 01                	test   $0x1,%al
f0101013:	74 2d                	je     f0101042 <page_insert+0x56>
	{
		if(PTE_ADDR(*pte) != page2pa(pp))
f0101015:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010101a:	89 da                	mov    %ebx,%edx
f010101c:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101022:	c1 fa 03             	sar    $0x3,%edx
f0101025:	c1 e2 0c             	shl    $0xc,%edx
f0101028:	39 d0                	cmp    %edx,%eax
f010102a:	74 11                	je     f010103d <page_insert+0x51>
			page_remove(pgdir,va);
f010102c:	83 ec 08             	sub    $0x8,%esp
f010102f:	57                   	push   %edi
f0101030:	ff 75 08             	pushl  0x8(%ebp)
f0101033:	e8 66 ff ff ff       	call   f0100f9e <page_remove>
f0101038:	83 c4 10             	add    $0x10,%esp
f010103b:	eb 05                	jmp    f0101042 <page_insert+0x56>
		else
			pp->pp_ref--;
f010103d:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
		
	}

	pp->pp_ref++;
f0101042:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)

	*pte = page2pa(pp)|perm|PTE_P;	
f0101047:	2b 1d 4c 2c 17 f0    	sub    0xf0172c4c,%ebx
f010104d:	c1 fb 03             	sar    $0x3,%ebx
f0101050:	c1 e3 0c             	shl    $0xc,%ebx
f0101053:	8b 45 14             	mov    0x14(%ebp),%eax
f0101056:	83 c8 01             	or     $0x1,%eax
f0101059:	09 c3                	or     %eax,%ebx
f010105b:	89 1e                	mov    %ebx,(%esi)

	return 0;
f010105d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101062:	eb 05                	jmp    f0101069 <page_insert+0x7d>
	// Fill this function in

	pte_t *pte = pgdir_walk(pgdir,va,1);
	
	if(!pte)
		return -E_NO_MEM;
f0101064:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	pp->pp_ref++;

	*pte = page2pa(pp)|perm|PTE_P;	

	return 0;
}
f0101069:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010106c:	5b                   	pop    %ebx
f010106d:	5e                   	pop    %esi
f010106e:	5f                   	pop    %edi
f010106f:	5d                   	pop    %ebp
f0101070:	c3                   	ret    

f0101071 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101071:	55                   	push   %ebp
f0101072:	89 e5                	mov    %esp,%ebp
f0101074:	57                   	push   %edi
f0101075:	56                   	push   %esi
f0101076:	53                   	push   %ebx
f0101077:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f010107a:	b8 15 00 00 00       	mov    $0x15,%eax
f010107f:	e8 b5 f8 ff ff       	call   f0100939 <nvram_read>
f0101084:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101086:	b8 17 00 00 00       	mov    $0x17,%eax
f010108b:	e8 a9 f8 ff ff       	call   f0100939 <nvram_read>
f0101090:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101092:	b8 34 00 00 00       	mov    $0x34,%eax
f0101097:	e8 9d f8 ff ff       	call   f0100939 <nvram_read>
f010109c:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010109f:	85 c0                	test   %eax,%eax
f01010a1:	74 07                	je     f01010aa <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01010a3:	05 00 40 00 00       	add    $0x4000,%eax
f01010a8:	eb 0b                	jmp    f01010b5 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01010aa:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01010b0:	85 f6                	test   %esi,%esi
f01010b2:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01010b5:	89 c2                	mov    %eax,%edx
f01010b7:	c1 ea 02             	shr    $0x2,%edx
f01010ba:	89 15 44 2c 17 f0    	mov    %edx,0xf0172c44
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010c0:	89 c2                	mov    %eax,%edx
f01010c2:	29 da                	sub    %ebx,%edx
f01010c4:	52                   	push   %edx
f01010c5:	53                   	push   %ebx
f01010c6:	50                   	push   %eax
f01010c7:	68 d4 4e 10 f0       	push   $0xf0104ed4
f01010cc:	e8 17 1f 00 00       	call   f0102fe8 <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010d1:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010d6:	e8 eb f8 ff ff       	call   f01009c6 <boot_alloc>
f01010db:	a3 48 2c 17 f0       	mov    %eax,0xf0172c48
	memset(kern_pgdir, 0, PGSIZE);
f01010e0:	83 c4 0c             	add    $0xc,%esp
f01010e3:	68 00 10 00 00       	push   $0x1000
f01010e8:	6a 00                	push   $0x0
f01010ea:	50                   	push   %eax
f01010eb:	e8 ca 32 00 00       	call   f01043ba <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010f0:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010f5:	83 c4 10             	add    $0x10,%esp
f01010f8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010fd:	77 15                	ja     f0101114 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010ff:	50                   	push   %eax
f0101100:	68 a8 4d 10 f0       	push   $0xf0104da8
f0101105:	68 9f 00 00 00       	push   $0x9f
f010110a:	68 ad 55 10 f0       	push   $0xf01055ad
f010110f:	e8 8c ef ff ff       	call   f01000a0 <_panic>
f0101114:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010111a:	83 ca 05             	or     $0x5,%edx
f010111d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages=(struct PageInfo*)boot_alloc(npages*sizeof(struct PageInfo));
f0101123:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f0101128:	c1 e0 03             	shl    $0x3,%eax
f010112b:	e8 96 f8 ff ff       	call   f01009c6 <boot_alloc>
f0101130:	a3 4c 2c 17 f0       	mov    %eax,0xf0172c4c

	memset(pages,0,npages*sizeof(struct PageInfo));
f0101135:	83 ec 04             	sub    $0x4,%esp
f0101138:	8b 3d 44 2c 17 f0    	mov    0xf0172c44,%edi
f010113e:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101145:	52                   	push   %edx
f0101146:	6a 00                	push   $0x0
f0101148:	50                   	push   %eax
f0101149:	e8 6c 32 00 00       	call   f01043ba <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f010114e:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101153:	e8 6e f8 ff ff       	call   f01009c6 <boot_alloc>
f0101158:	a3 88 1f 17 f0       	mov    %eax,0xf0171f88
 
        memset(envs,0,NENV*sizeof(struct Env));
f010115d:	83 c4 0c             	add    $0xc,%esp
f0101160:	68 00 80 01 00       	push   $0x18000
f0101165:	6a 00                	push   $0x0
f0101167:	50                   	push   %eax
f0101168:	e8 4d 32 00 00       	call   f01043ba <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010116d:	e8 91 fb ff ff       	call   f0100d03 <page_init>

	check_page_free_list(1);
f0101172:	b8 01 00 00 00       	mov    $0x1,%eax
f0101177:	e8 c4 f8 ff ff       	call   f0100a40 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010117c:	83 c4 10             	add    $0x10,%esp
f010117f:	83 3d 4c 2c 17 f0 00 	cmpl   $0x0,0xf0172c4c
f0101186:	75 17                	jne    f010119f <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f0101188:	83 ec 04             	sub    $0x4,%esp
f010118b:	68 99 56 10 f0       	push   $0xf0105699
f0101190:	68 ce 02 00 00       	push   $0x2ce
f0101195:	68 ad 55 10 f0       	push   $0xf01055ad
f010119a:	e8 01 ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010119f:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f01011a4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011a9:	eb 05                	jmp    f01011b0 <mem_init+0x13f>
		++nfree;
f01011ab:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011ae:	8b 00                	mov    (%eax),%eax
f01011b0:	85 c0                	test   %eax,%eax
f01011b2:	75 f7                	jne    f01011ab <mem_init+0x13a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
//	cprintf("pagealloc(0):%p\n",page_alloc(0));
	assert((pp0 = page_alloc(0)));
f01011b4:	83 ec 0c             	sub    $0xc,%esp
f01011b7:	6a 00                	push   $0x0
f01011b9:	e8 d4 fb ff ff       	call   f0100d92 <page_alloc>
f01011be:	89 c7                	mov    %eax,%edi
f01011c0:	83 c4 10             	add    $0x10,%esp
f01011c3:	85 c0                	test   %eax,%eax
f01011c5:	75 19                	jne    f01011e0 <mem_init+0x16f>
f01011c7:	68 b4 56 10 f0       	push   $0xf01056b4
f01011cc:	68 ed 55 10 f0       	push   $0xf01055ed
f01011d1:	68 d7 02 00 00       	push   $0x2d7
f01011d6:	68 ad 55 10 f0       	push   $0xf01055ad
f01011db:	e8 c0 ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01011e0:	83 ec 0c             	sub    $0xc,%esp
f01011e3:	6a 00                	push   $0x0
f01011e5:	e8 a8 fb ff ff       	call   f0100d92 <page_alloc>
f01011ea:	89 c6                	mov    %eax,%esi
f01011ec:	83 c4 10             	add    $0x10,%esp
f01011ef:	85 c0                	test   %eax,%eax
f01011f1:	75 19                	jne    f010120c <mem_init+0x19b>
f01011f3:	68 ca 56 10 f0       	push   $0xf01056ca
f01011f8:	68 ed 55 10 f0       	push   $0xf01055ed
f01011fd:	68 d8 02 00 00       	push   $0x2d8
f0101202:	68 ad 55 10 f0       	push   $0xf01055ad
f0101207:	e8 94 ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010120c:	83 ec 0c             	sub    $0xc,%esp
f010120f:	6a 00                	push   $0x0
f0101211:	e8 7c fb ff ff       	call   f0100d92 <page_alloc>
f0101216:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101219:	83 c4 10             	add    $0x10,%esp
f010121c:	85 c0                	test   %eax,%eax
f010121e:	75 19                	jne    f0101239 <mem_init+0x1c8>
f0101220:	68 e0 56 10 f0       	push   $0xf01056e0
f0101225:	68 ed 55 10 f0       	push   $0xf01055ed
f010122a:	68 d9 02 00 00       	push   $0x2d9
f010122f:	68 ad 55 10 f0       	push   $0xf01055ad
f0101234:	e8 67 ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101239:	39 f7                	cmp    %esi,%edi
f010123b:	75 19                	jne    f0101256 <mem_init+0x1e5>
f010123d:	68 f6 56 10 f0       	push   $0xf01056f6
f0101242:	68 ed 55 10 f0       	push   $0xf01055ed
f0101247:	68 dc 02 00 00       	push   $0x2dc
f010124c:	68 ad 55 10 f0       	push   $0xf01055ad
f0101251:	e8 4a ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101256:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101259:	39 c6                	cmp    %eax,%esi
f010125b:	74 04                	je     f0101261 <mem_init+0x1f0>
f010125d:	39 c7                	cmp    %eax,%edi
f010125f:	75 19                	jne    f010127a <mem_init+0x209>
f0101261:	68 10 4f 10 f0       	push   $0xf0104f10
f0101266:	68 ed 55 10 f0       	push   $0xf01055ed
f010126b:	68 dd 02 00 00       	push   $0x2dd
f0101270:	68 ad 55 10 f0       	push   $0xf01055ad
f0101275:	e8 26 ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010127a:	8b 0d 4c 2c 17 f0    	mov    0xf0172c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101280:	8b 15 44 2c 17 f0    	mov    0xf0172c44,%edx
f0101286:	c1 e2 0c             	shl    $0xc,%edx
f0101289:	89 f8                	mov    %edi,%eax
f010128b:	29 c8                	sub    %ecx,%eax
f010128d:	c1 f8 03             	sar    $0x3,%eax
f0101290:	c1 e0 0c             	shl    $0xc,%eax
f0101293:	39 d0                	cmp    %edx,%eax
f0101295:	72 19                	jb     f01012b0 <mem_init+0x23f>
f0101297:	68 08 57 10 f0       	push   $0xf0105708
f010129c:	68 ed 55 10 f0       	push   $0xf01055ed
f01012a1:	68 de 02 00 00       	push   $0x2de
f01012a6:	68 ad 55 10 f0       	push   $0xf01055ad
f01012ab:	e8 f0 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012b0:	89 f0                	mov    %esi,%eax
f01012b2:	29 c8                	sub    %ecx,%eax
f01012b4:	c1 f8 03             	sar    $0x3,%eax
f01012b7:	c1 e0 0c             	shl    $0xc,%eax
f01012ba:	39 c2                	cmp    %eax,%edx
f01012bc:	77 19                	ja     f01012d7 <mem_init+0x266>
f01012be:	68 25 57 10 f0       	push   $0xf0105725
f01012c3:	68 ed 55 10 f0       	push   $0xf01055ed
f01012c8:	68 df 02 00 00       	push   $0x2df
f01012cd:	68 ad 55 10 f0       	push   $0xf01055ad
f01012d2:	e8 c9 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012da:	29 c8                	sub    %ecx,%eax
f01012dc:	c1 f8 03             	sar    $0x3,%eax
f01012df:	c1 e0 0c             	shl    $0xc,%eax
f01012e2:	39 c2                	cmp    %eax,%edx
f01012e4:	77 19                	ja     f01012ff <mem_init+0x28e>
f01012e6:	68 42 57 10 f0       	push   $0xf0105742
f01012eb:	68 ed 55 10 f0       	push   $0xf01055ed
f01012f0:	68 e0 02 00 00       	push   $0x2e0
f01012f5:	68 ad 55 10 f0       	push   $0xf01055ad
f01012fa:	e8 a1 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012ff:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0101304:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101307:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f010130e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101311:	83 ec 0c             	sub    $0xc,%esp
f0101314:	6a 00                	push   $0x0
f0101316:	e8 77 fa ff ff       	call   f0100d92 <page_alloc>
f010131b:	83 c4 10             	add    $0x10,%esp
f010131e:	85 c0                	test   %eax,%eax
f0101320:	74 19                	je     f010133b <mem_init+0x2ca>
f0101322:	68 5f 57 10 f0       	push   $0xf010575f
f0101327:	68 ed 55 10 f0       	push   $0xf01055ed
f010132c:	68 e7 02 00 00       	push   $0x2e7
f0101331:	68 ad 55 10 f0       	push   $0xf01055ad
f0101336:	e8 65 ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010133b:	83 ec 0c             	sub    $0xc,%esp
f010133e:	57                   	push   %edi
f010133f:	e8 be fa ff ff       	call   f0100e02 <page_free>
	page_free(pp1);
f0101344:	89 34 24             	mov    %esi,(%esp)
f0101347:	e8 b6 fa ff ff       	call   f0100e02 <page_free>
	page_free(pp2);
f010134c:	83 c4 04             	add    $0x4,%esp
f010134f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101352:	e8 ab fa ff ff       	call   f0100e02 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101357:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010135e:	e8 2f fa ff ff       	call   f0100d92 <page_alloc>
f0101363:	89 c6                	mov    %eax,%esi
f0101365:	83 c4 10             	add    $0x10,%esp
f0101368:	85 c0                	test   %eax,%eax
f010136a:	75 19                	jne    f0101385 <mem_init+0x314>
f010136c:	68 b4 56 10 f0       	push   $0xf01056b4
f0101371:	68 ed 55 10 f0       	push   $0xf01055ed
f0101376:	68 ee 02 00 00       	push   $0x2ee
f010137b:	68 ad 55 10 f0       	push   $0xf01055ad
f0101380:	e8 1b ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101385:	83 ec 0c             	sub    $0xc,%esp
f0101388:	6a 00                	push   $0x0
f010138a:	e8 03 fa ff ff       	call   f0100d92 <page_alloc>
f010138f:	89 c7                	mov    %eax,%edi
f0101391:	83 c4 10             	add    $0x10,%esp
f0101394:	85 c0                	test   %eax,%eax
f0101396:	75 19                	jne    f01013b1 <mem_init+0x340>
f0101398:	68 ca 56 10 f0       	push   $0xf01056ca
f010139d:	68 ed 55 10 f0       	push   $0xf01055ed
f01013a2:	68 ef 02 00 00       	push   $0x2ef
f01013a7:	68 ad 55 10 f0       	push   $0xf01055ad
f01013ac:	e8 ef ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01013b1:	83 ec 0c             	sub    $0xc,%esp
f01013b4:	6a 00                	push   $0x0
f01013b6:	e8 d7 f9 ff ff       	call   f0100d92 <page_alloc>
f01013bb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013be:	83 c4 10             	add    $0x10,%esp
f01013c1:	85 c0                	test   %eax,%eax
f01013c3:	75 19                	jne    f01013de <mem_init+0x36d>
f01013c5:	68 e0 56 10 f0       	push   $0xf01056e0
f01013ca:	68 ed 55 10 f0       	push   $0xf01055ed
f01013cf:	68 f0 02 00 00       	push   $0x2f0
f01013d4:	68 ad 55 10 f0       	push   $0xf01055ad
f01013d9:	e8 c2 ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013de:	39 fe                	cmp    %edi,%esi
f01013e0:	75 19                	jne    f01013fb <mem_init+0x38a>
f01013e2:	68 f6 56 10 f0       	push   $0xf01056f6
f01013e7:	68 ed 55 10 f0       	push   $0xf01055ed
f01013ec:	68 f2 02 00 00       	push   $0x2f2
f01013f1:	68 ad 55 10 f0       	push   $0xf01055ad
f01013f6:	e8 a5 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013fb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013fe:	39 c7                	cmp    %eax,%edi
f0101400:	74 04                	je     f0101406 <mem_init+0x395>
f0101402:	39 c6                	cmp    %eax,%esi
f0101404:	75 19                	jne    f010141f <mem_init+0x3ae>
f0101406:	68 10 4f 10 f0       	push   $0xf0104f10
f010140b:	68 ed 55 10 f0       	push   $0xf01055ed
f0101410:	68 f3 02 00 00       	push   $0x2f3
f0101415:	68 ad 55 10 f0       	push   $0xf01055ad
f010141a:	e8 81 ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f010141f:	83 ec 0c             	sub    $0xc,%esp
f0101422:	6a 00                	push   $0x0
f0101424:	e8 69 f9 ff ff       	call   f0100d92 <page_alloc>
f0101429:	83 c4 10             	add    $0x10,%esp
f010142c:	85 c0                	test   %eax,%eax
f010142e:	74 19                	je     f0101449 <mem_init+0x3d8>
f0101430:	68 5f 57 10 f0       	push   $0xf010575f
f0101435:	68 ed 55 10 f0       	push   $0xf01055ed
f010143a:	68 f4 02 00 00       	push   $0x2f4
f010143f:	68 ad 55 10 f0       	push   $0xf01055ad
f0101444:	e8 57 ec ff ff       	call   f01000a0 <_panic>
f0101449:	89 f0                	mov    %esi,%eax
f010144b:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101451:	c1 f8 03             	sar    $0x3,%eax
f0101454:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101457:	89 c2                	mov    %eax,%edx
f0101459:	c1 ea 0c             	shr    $0xc,%edx
f010145c:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0101462:	72 12                	jb     f0101476 <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101464:	50                   	push   %eax
f0101465:	68 84 4d 10 f0       	push   $0xf0104d84
f010146a:	6a 56                	push   $0x56
f010146c:	68 d3 55 10 f0       	push   $0xf01055d3
f0101471:	e8 2a ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101476:	83 ec 04             	sub    $0x4,%esp
f0101479:	68 00 10 00 00       	push   $0x1000
f010147e:	6a 01                	push   $0x1
f0101480:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101485:	50                   	push   %eax
f0101486:	e8 2f 2f 00 00       	call   f01043ba <memset>
	page_free(pp0);
f010148b:	89 34 24             	mov    %esi,(%esp)
f010148e:	e8 6f f9 ff ff       	call   f0100e02 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101493:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010149a:	e8 f3 f8 ff ff       	call   f0100d92 <page_alloc>
f010149f:	83 c4 10             	add    $0x10,%esp
f01014a2:	85 c0                	test   %eax,%eax
f01014a4:	75 19                	jne    f01014bf <mem_init+0x44e>
f01014a6:	68 6e 57 10 f0       	push   $0xf010576e
f01014ab:	68 ed 55 10 f0       	push   $0xf01055ed
f01014b0:	68 f9 02 00 00       	push   $0x2f9
f01014b5:	68 ad 55 10 f0       	push   $0xf01055ad
f01014ba:	e8 e1 eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01014bf:	39 c6                	cmp    %eax,%esi
f01014c1:	74 19                	je     f01014dc <mem_init+0x46b>
f01014c3:	68 8c 57 10 f0       	push   $0xf010578c
f01014c8:	68 ed 55 10 f0       	push   $0xf01055ed
f01014cd:	68 fa 02 00 00       	push   $0x2fa
f01014d2:	68 ad 55 10 f0       	push   $0xf01055ad
f01014d7:	e8 c4 eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014dc:	89 f0                	mov    %esi,%eax
f01014de:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01014e4:	c1 f8 03             	sar    $0x3,%eax
f01014e7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014ea:	89 c2                	mov    %eax,%edx
f01014ec:	c1 ea 0c             	shr    $0xc,%edx
f01014ef:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01014f5:	72 12                	jb     f0101509 <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014f7:	50                   	push   %eax
f01014f8:	68 84 4d 10 f0       	push   $0xf0104d84
f01014fd:	6a 56                	push   $0x56
f01014ff:	68 d3 55 10 f0       	push   $0xf01055d3
f0101504:	e8 97 eb ff ff       	call   f01000a0 <_panic>
f0101509:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010150f:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101515:	80 38 00             	cmpb   $0x0,(%eax)
f0101518:	74 19                	je     f0101533 <mem_init+0x4c2>
f010151a:	68 9c 57 10 f0       	push   $0xf010579c
f010151f:	68 ed 55 10 f0       	push   $0xf01055ed
f0101524:	68 fd 02 00 00       	push   $0x2fd
f0101529:	68 ad 55 10 f0       	push   $0xf01055ad
f010152e:	e8 6d eb ff ff       	call   f01000a0 <_panic>
f0101533:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101536:	39 d0                	cmp    %edx,%eax
f0101538:	75 db                	jne    f0101515 <mem_init+0x4a4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010153a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010153d:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80

	// free the pages we took
	page_free(pp0);
f0101542:	83 ec 0c             	sub    $0xc,%esp
f0101545:	56                   	push   %esi
f0101546:	e8 b7 f8 ff ff       	call   f0100e02 <page_free>
	page_free(pp1);
f010154b:	89 3c 24             	mov    %edi,(%esp)
f010154e:	e8 af f8 ff ff       	call   f0100e02 <page_free>
	page_free(pp2);
f0101553:	83 c4 04             	add    $0x4,%esp
f0101556:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101559:	e8 a4 f8 ff ff       	call   f0100e02 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010155e:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0101563:	83 c4 10             	add    $0x10,%esp
f0101566:	eb 05                	jmp    f010156d <mem_init+0x4fc>
		--nfree;
f0101568:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010156b:	8b 00                	mov    (%eax),%eax
f010156d:	85 c0                	test   %eax,%eax
f010156f:	75 f7                	jne    f0101568 <mem_init+0x4f7>
		--nfree;
	assert(nfree == 0);
f0101571:	85 db                	test   %ebx,%ebx
f0101573:	74 19                	je     f010158e <mem_init+0x51d>
f0101575:	68 a6 57 10 f0       	push   $0xf01057a6
f010157a:	68 ed 55 10 f0       	push   $0xf01055ed
f010157f:	68 0a 03 00 00       	push   $0x30a
f0101584:	68 ad 55 10 f0       	push   $0xf01055ad
f0101589:	e8 12 eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010158e:	83 ec 0c             	sub    $0xc,%esp
f0101591:	68 30 4f 10 f0       	push   $0xf0104f30
f0101596:	e8 4d 1a 00 00       	call   f0102fe8 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010159b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a2:	e8 eb f7 ff ff       	call   f0100d92 <page_alloc>
f01015a7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015aa:	83 c4 10             	add    $0x10,%esp
f01015ad:	85 c0                	test   %eax,%eax
f01015af:	75 19                	jne    f01015ca <mem_init+0x559>
f01015b1:	68 b4 56 10 f0       	push   $0xf01056b4
f01015b6:	68 ed 55 10 f0       	push   $0xf01055ed
f01015bb:	68 69 03 00 00       	push   $0x369
f01015c0:	68 ad 55 10 f0       	push   $0xf01055ad
f01015c5:	e8 d6 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01015ca:	83 ec 0c             	sub    $0xc,%esp
f01015cd:	6a 00                	push   $0x0
f01015cf:	e8 be f7 ff ff       	call   f0100d92 <page_alloc>
f01015d4:	89 c3                	mov    %eax,%ebx
f01015d6:	83 c4 10             	add    $0x10,%esp
f01015d9:	85 c0                	test   %eax,%eax
f01015db:	75 19                	jne    f01015f6 <mem_init+0x585>
f01015dd:	68 ca 56 10 f0       	push   $0xf01056ca
f01015e2:	68 ed 55 10 f0       	push   $0xf01055ed
f01015e7:	68 6a 03 00 00       	push   $0x36a
f01015ec:	68 ad 55 10 f0       	push   $0xf01055ad
f01015f1:	e8 aa ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01015f6:	83 ec 0c             	sub    $0xc,%esp
f01015f9:	6a 00                	push   $0x0
f01015fb:	e8 92 f7 ff ff       	call   f0100d92 <page_alloc>
f0101600:	89 c6                	mov    %eax,%esi
f0101602:	83 c4 10             	add    $0x10,%esp
f0101605:	85 c0                	test   %eax,%eax
f0101607:	75 19                	jne    f0101622 <mem_init+0x5b1>
f0101609:	68 e0 56 10 f0       	push   $0xf01056e0
f010160e:	68 ed 55 10 f0       	push   $0xf01055ed
f0101613:	68 6b 03 00 00       	push   $0x36b
f0101618:	68 ad 55 10 f0       	push   $0xf01055ad
f010161d:	e8 7e ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101622:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101625:	75 19                	jne    f0101640 <mem_init+0x5cf>
f0101627:	68 f6 56 10 f0       	push   $0xf01056f6
f010162c:	68 ed 55 10 f0       	push   $0xf01055ed
f0101631:	68 6e 03 00 00       	push   $0x36e
f0101636:	68 ad 55 10 f0       	push   $0xf01055ad
f010163b:	e8 60 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101640:	39 c3                	cmp    %eax,%ebx
f0101642:	74 05                	je     f0101649 <mem_init+0x5d8>
f0101644:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101647:	75 19                	jne    f0101662 <mem_init+0x5f1>
f0101649:	68 10 4f 10 f0       	push   $0xf0104f10
f010164e:	68 ed 55 10 f0       	push   $0xf01055ed
f0101653:	68 6f 03 00 00       	push   $0x36f
f0101658:	68 ad 55 10 f0       	push   $0xf01055ad
f010165d:	e8 3e ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101662:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0101667:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010166a:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f0101671:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101674:	83 ec 0c             	sub    $0xc,%esp
f0101677:	6a 00                	push   $0x0
f0101679:	e8 14 f7 ff ff       	call   f0100d92 <page_alloc>
f010167e:	83 c4 10             	add    $0x10,%esp
f0101681:	85 c0                	test   %eax,%eax
f0101683:	74 19                	je     f010169e <mem_init+0x62d>
f0101685:	68 5f 57 10 f0       	push   $0xf010575f
f010168a:	68 ed 55 10 f0       	push   $0xf01055ed
f010168f:	68 76 03 00 00       	push   $0x376
f0101694:	68 ad 55 10 f0       	push   $0xf01055ad
f0101699:	e8 02 ea ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010169e:	83 ec 04             	sub    $0x4,%esp
f01016a1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016a4:	50                   	push   %eax
f01016a5:	6a 00                	push   $0x0
f01016a7:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01016ad:	e8 94 f8 ff ff       	call   f0100f46 <page_lookup>
f01016b2:	83 c4 10             	add    $0x10,%esp
f01016b5:	85 c0                	test   %eax,%eax
f01016b7:	74 19                	je     f01016d2 <mem_init+0x661>
f01016b9:	68 50 4f 10 f0       	push   $0xf0104f50
f01016be:	68 ed 55 10 f0       	push   $0xf01055ed
f01016c3:	68 79 03 00 00       	push   $0x379
f01016c8:	68 ad 55 10 f0       	push   $0xf01055ad
f01016cd:	e8 ce e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016d2:	6a 02                	push   $0x2
f01016d4:	6a 00                	push   $0x0
f01016d6:	53                   	push   %ebx
f01016d7:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01016dd:	e8 0a f9 ff ff       	call   f0100fec <page_insert>
f01016e2:	83 c4 10             	add    $0x10,%esp
f01016e5:	85 c0                	test   %eax,%eax
f01016e7:	78 19                	js     f0101702 <mem_init+0x691>
f01016e9:	68 88 4f 10 f0       	push   $0xf0104f88
f01016ee:	68 ed 55 10 f0       	push   $0xf01055ed
f01016f3:	68 7c 03 00 00       	push   $0x37c
f01016f8:	68 ad 55 10 f0       	push   $0xf01055ad
f01016fd:	e8 9e e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101702:	83 ec 0c             	sub    $0xc,%esp
f0101705:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101708:	e8 f5 f6 ff ff       	call   f0100e02 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010170d:	6a 02                	push   $0x2
f010170f:	6a 00                	push   $0x0
f0101711:	53                   	push   %ebx
f0101712:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101718:	e8 cf f8 ff ff       	call   f0100fec <page_insert>
f010171d:	83 c4 20             	add    $0x20,%esp
f0101720:	85 c0                	test   %eax,%eax
f0101722:	74 19                	je     f010173d <mem_init+0x6cc>
f0101724:	68 b8 4f 10 f0       	push   $0xf0104fb8
f0101729:	68 ed 55 10 f0       	push   $0xf01055ed
f010172e:	68 80 03 00 00       	push   $0x380
f0101733:	68 ad 55 10 f0       	push   $0xf01055ad
f0101738:	e8 63 e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010173d:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101743:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0101748:	89 c1                	mov    %eax,%ecx
f010174a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010174d:	8b 17                	mov    (%edi),%edx
f010174f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101755:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101758:	29 c8                	sub    %ecx,%eax
f010175a:	c1 f8 03             	sar    $0x3,%eax
f010175d:	c1 e0 0c             	shl    $0xc,%eax
f0101760:	39 c2                	cmp    %eax,%edx
f0101762:	74 19                	je     f010177d <mem_init+0x70c>
f0101764:	68 e8 4f 10 f0       	push   $0xf0104fe8
f0101769:	68 ed 55 10 f0       	push   $0xf01055ed
f010176e:	68 81 03 00 00       	push   $0x381
f0101773:	68 ad 55 10 f0       	push   $0xf01055ad
f0101778:	e8 23 e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010177d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101782:	89 f8                	mov    %edi,%eax
f0101784:	e8 d9 f1 ff ff       	call   f0100962 <check_va2pa>
f0101789:	89 da                	mov    %ebx,%edx
f010178b:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010178e:	c1 fa 03             	sar    $0x3,%edx
f0101791:	c1 e2 0c             	shl    $0xc,%edx
f0101794:	39 d0                	cmp    %edx,%eax
f0101796:	74 19                	je     f01017b1 <mem_init+0x740>
f0101798:	68 10 50 10 f0       	push   $0xf0105010
f010179d:	68 ed 55 10 f0       	push   $0xf01055ed
f01017a2:	68 82 03 00 00       	push   $0x382
f01017a7:	68 ad 55 10 f0       	push   $0xf01055ad
f01017ac:	e8 ef e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01017b1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017b6:	74 19                	je     f01017d1 <mem_init+0x760>
f01017b8:	68 b1 57 10 f0       	push   $0xf01057b1
f01017bd:	68 ed 55 10 f0       	push   $0xf01055ed
f01017c2:	68 83 03 00 00       	push   $0x383
f01017c7:	68 ad 55 10 f0       	push   $0xf01055ad
f01017cc:	e8 cf e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01017d1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017d4:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017d9:	74 19                	je     f01017f4 <mem_init+0x783>
f01017db:	68 c2 57 10 f0       	push   $0xf01057c2
f01017e0:	68 ed 55 10 f0       	push   $0xf01055ed
f01017e5:	68 84 03 00 00       	push   $0x384
f01017ea:	68 ad 55 10 f0       	push   $0xf01055ad
f01017ef:	e8 ac e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017f4:	6a 02                	push   $0x2
f01017f6:	68 00 10 00 00       	push   $0x1000
f01017fb:	56                   	push   %esi
f01017fc:	57                   	push   %edi
f01017fd:	e8 ea f7 ff ff       	call   f0100fec <page_insert>
f0101802:	83 c4 10             	add    $0x10,%esp
f0101805:	85 c0                	test   %eax,%eax
f0101807:	74 19                	je     f0101822 <mem_init+0x7b1>
f0101809:	68 40 50 10 f0       	push   $0xf0105040
f010180e:	68 ed 55 10 f0       	push   $0xf01055ed
f0101813:	68 87 03 00 00       	push   $0x387
f0101818:	68 ad 55 10 f0       	push   $0xf01055ad
f010181d:	e8 7e e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101822:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101827:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f010182c:	e8 31 f1 ff ff       	call   f0100962 <check_va2pa>
f0101831:	89 f2                	mov    %esi,%edx
f0101833:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101839:	c1 fa 03             	sar    $0x3,%edx
f010183c:	c1 e2 0c             	shl    $0xc,%edx
f010183f:	39 d0                	cmp    %edx,%eax
f0101841:	74 19                	je     f010185c <mem_init+0x7eb>
f0101843:	68 7c 50 10 f0       	push   $0xf010507c
f0101848:	68 ed 55 10 f0       	push   $0xf01055ed
f010184d:	68 88 03 00 00       	push   $0x388
f0101852:	68 ad 55 10 f0       	push   $0xf01055ad
f0101857:	e8 44 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010185c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101861:	74 19                	je     f010187c <mem_init+0x80b>
f0101863:	68 d3 57 10 f0       	push   $0xf01057d3
f0101868:	68 ed 55 10 f0       	push   $0xf01055ed
f010186d:	68 89 03 00 00       	push   $0x389
f0101872:	68 ad 55 10 f0       	push   $0xf01055ad
f0101877:	e8 24 e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010187c:	83 ec 0c             	sub    $0xc,%esp
f010187f:	6a 00                	push   $0x0
f0101881:	e8 0c f5 ff ff       	call   f0100d92 <page_alloc>
f0101886:	83 c4 10             	add    $0x10,%esp
f0101889:	85 c0                	test   %eax,%eax
f010188b:	74 19                	je     f01018a6 <mem_init+0x835>
f010188d:	68 5f 57 10 f0       	push   $0xf010575f
f0101892:	68 ed 55 10 f0       	push   $0xf01055ed
f0101897:	68 8c 03 00 00       	push   $0x38c
f010189c:	68 ad 55 10 f0       	push   $0xf01055ad
f01018a1:	e8 fa e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018a6:	6a 02                	push   $0x2
f01018a8:	68 00 10 00 00       	push   $0x1000
f01018ad:	56                   	push   %esi
f01018ae:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01018b4:	e8 33 f7 ff ff       	call   f0100fec <page_insert>
f01018b9:	83 c4 10             	add    $0x10,%esp
f01018bc:	85 c0                	test   %eax,%eax
f01018be:	74 19                	je     f01018d9 <mem_init+0x868>
f01018c0:	68 40 50 10 f0       	push   $0xf0105040
f01018c5:	68 ed 55 10 f0       	push   $0xf01055ed
f01018ca:	68 8f 03 00 00       	push   $0x38f
f01018cf:	68 ad 55 10 f0       	push   $0xf01055ad
f01018d4:	e8 c7 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018d9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018de:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01018e3:	e8 7a f0 ff ff       	call   f0100962 <check_va2pa>
f01018e8:	89 f2                	mov    %esi,%edx
f01018ea:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f01018f0:	c1 fa 03             	sar    $0x3,%edx
f01018f3:	c1 e2 0c             	shl    $0xc,%edx
f01018f6:	39 d0                	cmp    %edx,%eax
f01018f8:	74 19                	je     f0101913 <mem_init+0x8a2>
f01018fa:	68 7c 50 10 f0       	push   $0xf010507c
f01018ff:	68 ed 55 10 f0       	push   $0xf01055ed
f0101904:	68 90 03 00 00       	push   $0x390
f0101909:	68 ad 55 10 f0       	push   $0xf01055ad
f010190e:	e8 8d e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101913:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101918:	74 19                	je     f0101933 <mem_init+0x8c2>
f010191a:	68 d3 57 10 f0       	push   $0xf01057d3
f010191f:	68 ed 55 10 f0       	push   $0xf01055ed
f0101924:	68 91 03 00 00       	push   $0x391
f0101929:	68 ad 55 10 f0       	push   $0xf01055ad
f010192e:	e8 6d e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101933:	83 ec 0c             	sub    $0xc,%esp
f0101936:	6a 00                	push   $0x0
f0101938:	e8 55 f4 ff ff       	call   f0100d92 <page_alloc>
f010193d:	83 c4 10             	add    $0x10,%esp
f0101940:	85 c0                	test   %eax,%eax
f0101942:	74 19                	je     f010195d <mem_init+0x8ec>
f0101944:	68 5f 57 10 f0       	push   $0xf010575f
f0101949:	68 ed 55 10 f0       	push   $0xf01055ed
f010194e:	68 95 03 00 00       	push   $0x395
f0101953:	68 ad 55 10 f0       	push   $0xf01055ad
f0101958:	e8 43 e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010195d:	8b 15 48 2c 17 f0    	mov    0xf0172c48,%edx
f0101963:	8b 02                	mov    (%edx),%eax
f0101965:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010196a:	89 c1                	mov    %eax,%ecx
f010196c:	c1 e9 0c             	shr    $0xc,%ecx
f010196f:	3b 0d 44 2c 17 f0    	cmp    0xf0172c44,%ecx
f0101975:	72 15                	jb     f010198c <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101977:	50                   	push   %eax
f0101978:	68 84 4d 10 f0       	push   $0xf0104d84
f010197d:	68 98 03 00 00       	push   $0x398
f0101982:	68 ad 55 10 f0       	push   $0xf01055ad
f0101987:	e8 14 e7 ff ff       	call   f01000a0 <_panic>
f010198c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101991:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101994:	83 ec 04             	sub    $0x4,%esp
f0101997:	6a 00                	push   $0x0
f0101999:	68 00 10 00 00       	push   $0x1000
f010199e:	52                   	push   %edx
f010199f:	e8 c0 f4 ff ff       	call   f0100e64 <pgdir_walk>
f01019a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019a7:	8d 57 04             	lea    0x4(%edi),%edx
f01019aa:	83 c4 10             	add    $0x10,%esp
f01019ad:	39 d0                	cmp    %edx,%eax
f01019af:	74 19                	je     f01019ca <mem_init+0x959>
f01019b1:	68 ac 50 10 f0       	push   $0xf01050ac
f01019b6:	68 ed 55 10 f0       	push   $0xf01055ed
f01019bb:	68 99 03 00 00       	push   $0x399
f01019c0:	68 ad 55 10 f0       	push   $0xf01055ad
f01019c5:	e8 d6 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019ca:	6a 06                	push   $0x6
f01019cc:	68 00 10 00 00       	push   $0x1000
f01019d1:	56                   	push   %esi
f01019d2:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01019d8:	e8 0f f6 ff ff       	call   f0100fec <page_insert>
f01019dd:	83 c4 10             	add    $0x10,%esp
f01019e0:	85 c0                	test   %eax,%eax
f01019e2:	74 19                	je     f01019fd <mem_init+0x98c>
f01019e4:	68 ec 50 10 f0       	push   $0xf01050ec
f01019e9:	68 ed 55 10 f0       	push   $0xf01055ed
f01019ee:	68 9c 03 00 00       	push   $0x39c
f01019f3:	68 ad 55 10 f0       	push   $0xf01055ad
f01019f8:	e8 a3 e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019fd:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101a03:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a08:	89 f8                	mov    %edi,%eax
f0101a0a:	e8 53 ef ff ff       	call   f0100962 <check_va2pa>
f0101a0f:	89 f2                	mov    %esi,%edx
f0101a11:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101a17:	c1 fa 03             	sar    $0x3,%edx
f0101a1a:	c1 e2 0c             	shl    $0xc,%edx
f0101a1d:	39 d0                	cmp    %edx,%eax
f0101a1f:	74 19                	je     f0101a3a <mem_init+0x9c9>
f0101a21:	68 7c 50 10 f0       	push   $0xf010507c
f0101a26:	68 ed 55 10 f0       	push   $0xf01055ed
f0101a2b:	68 9d 03 00 00       	push   $0x39d
f0101a30:	68 ad 55 10 f0       	push   $0xf01055ad
f0101a35:	e8 66 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a3a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a3f:	74 19                	je     f0101a5a <mem_init+0x9e9>
f0101a41:	68 d3 57 10 f0       	push   $0xf01057d3
f0101a46:	68 ed 55 10 f0       	push   $0xf01055ed
f0101a4b:	68 9e 03 00 00       	push   $0x39e
f0101a50:	68 ad 55 10 f0       	push   $0xf01055ad
f0101a55:	e8 46 e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a5a:	83 ec 04             	sub    $0x4,%esp
f0101a5d:	6a 00                	push   $0x0
f0101a5f:	68 00 10 00 00       	push   $0x1000
f0101a64:	57                   	push   %edi
f0101a65:	e8 fa f3 ff ff       	call   f0100e64 <pgdir_walk>
f0101a6a:	83 c4 10             	add    $0x10,%esp
f0101a6d:	f6 00 04             	testb  $0x4,(%eax)
f0101a70:	75 19                	jne    f0101a8b <mem_init+0xa1a>
f0101a72:	68 2c 51 10 f0       	push   $0xf010512c
f0101a77:	68 ed 55 10 f0       	push   $0xf01055ed
f0101a7c:	68 9f 03 00 00       	push   $0x39f
f0101a81:	68 ad 55 10 f0       	push   $0xf01055ad
f0101a86:	e8 15 e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a8b:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0101a90:	f6 00 04             	testb  $0x4,(%eax)
f0101a93:	75 19                	jne    f0101aae <mem_init+0xa3d>
f0101a95:	68 e4 57 10 f0       	push   $0xf01057e4
f0101a9a:	68 ed 55 10 f0       	push   $0xf01055ed
f0101a9f:	68 a0 03 00 00       	push   $0x3a0
f0101aa4:	68 ad 55 10 f0       	push   $0xf01055ad
f0101aa9:	e8 f2 e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101aae:	6a 02                	push   $0x2
f0101ab0:	68 00 10 00 00       	push   $0x1000
f0101ab5:	56                   	push   %esi
f0101ab6:	50                   	push   %eax
f0101ab7:	e8 30 f5 ff ff       	call   f0100fec <page_insert>
f0101abc:	83 c4 10             	add    $0x10,%esp
f0101abf:	85 c0                	test   %eax,%eax
f0101ac1:	74 19                	je     f0101adc <mem_init+0xa6b>
f0101ac3:	68 40 50 10 f0       	push   $0xf0105040
f0101ac8:	68 ed 55 10 f0       	push   $0xf01055ed
f0101acd:	68 a3 03 00 00       	push   $0x3a3
f0101ad2:	68 ad 55 10 f0       	push   $0xf01055ad
f0101ad7:	e8 c4 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101adc:	83 ec 04             	sub    $0x4,%esp
f0101adf:	6a 00                	push   $0x0
f0101ae1:	68 00 10 00 00       	push   $0x1000
f0101ae6:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101aec:	e8 73 f3 ff ff       	call   f0100e64 <pgdir_walk>
f0101af1:	83 c4 10             	add    $0x10,%esp
f0101af4:	f6 00 02             	testb  $0x2,(%eax)
f0101af7:	75 19                	jne    f0101b12 <mem_init+0xaa1>
f0101af9:	68 60 51 10 f0       	push   $0xf0105160
f0101afe:	68 ed 55 10 f0       	push   $0xf01055ed
f0101b03:	68 a4 03 00 00       	push   $0x3a4
f0101b08:	68 ad 55 10 f0       	push   $0xf01055ad
f0101b0d:	e8 8e e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b12:	83 ec 04             	sub    $0x4,%esp
f0101b15:	6a 00                	push   $0x0
f0101b17:	68 00 10 00 00       	push   $0x1000
f0101b1c:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101b22:	e8 3d f3 ff ff       	call   f0100e64 <pgdir_walk>
f0101b27:	83 c4 10             	add    $0x10,%esp
f0101b2a:	f6 00 04             	testb  $0x4,(%eax)
f0101b2d:	74 19                	je     f0101b48 <mem_init+0xad7>
f0101b2f:	68 94 51 10 f0       	push   $0xf0105194
f0101b34:	68 ed 55 10 f0       	push   $0xf01055ed
f0101b39:	68 a5 03 00 00       	push   $0x3a5
f0101b3e:	68 ad 55 10 f0       	push   $0xf01055ad
f0101b43:	e8 58 e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b48:	6a 02                	push   $0x2
f0101b4a:	68 00 00 40 00       	push   $0x400000
f0101b4f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b52:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101b58:	e8 8f f4 ff ff       	call   f0100fec <page_insert>
f0101b5d:	83 c4 10             	add    $0x10,%esp
f0101b60:	85 c0                	test   %eax,%eax
f0101b62:	78 19                	js     f0101b7d <mem_init+0xb0c>
f0101b64:	68 cc 51 10 f0       	push   $0xf01051cc
f0101b69:	68 ed 55 10 f0       	push   $0xf01055ed
f0101b6e:	68 a8 03 00 00       	push   $0x3a8
f0101b73:	68 ad 55 10 f0       	push   $0xf01055ad
f0101b78:	e8 23 e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b7d:	6a 02                	push   $0x2
f0101b7f:	68 00 10 00 00       	push   $0x1000
f0101b84:	53                   	push   %ebx
f0101b85:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101b8b:	e8 5c f4 ff ff       	call   f0100fec <page_insert>
f0101b90:	83 c4 10             	add    $0x10,%esp
f0101b93:	85 c0                	test   %eax,%eax
f0101b95:	74 19                	je     f0101bb0 <mem_init+0xb3f>
f0101b97:	68 04 52 10 f0       	push   $0xf0105204
f0101b9c:	68 ed 55 10 f0       	push   $0xf01055ed
f0101ba1:	68 ab 03 00 00       	push   $0x3ab
f0101ba6:	68 ad 55 10 f0       	push   $0xf01055ad
f0101bab:	e8 f0 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bb0:	83 ec 04             	sub    $0x4,%esp
f0101bb3:	6a 00                	push   $0x0
f0101bb5:	68 00 10 00 00       	push   $0x1000
f0101bba:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101bc0:	e8 9f f2 ff ff       	call   f0100e64 <pgdir_walk>
f0101bc5:	83 c4 10             	add    $0x10,%esp
f0101bc8:	f6 00 04             	testb  $0x4,(%eax)
f0101bcb:	74 19                	je     f0101be6 <mem_init+0xb75>
f0101bcd:	68 94 51 10 f0       	push   $0xf0105194
f0101bd2:	68 ed 55 10 f0       	push   $0xf01055ed
f0101bd7:	68 ac 03 00 00       	push   $0x3ac
f0101bdc:	68 ad 55 10 f0       	push   $0xf01055ad
f0101be1:	e8 ba e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101be6:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101bec:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bf1:	89 f8                	mov    %edi,%eax
f0101bf3:	e8 6a ed ff ff       	call   f0100962 <check_va2pa>
f0101bf8:	89 c1                	mov    %eax,%ecx
f0101bfa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bfd:	89 d8                	mov    %ebx,%eax
f0101bff:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101c05:	c1 f8 03             	sar    $0x3,%eax
f0101c08:	c1 e0 0c             	shl    $0xc,%eax
f0101c0b:	39 c1                	cmp    %eax,%ecx
f0101c0d:	74 19                	je     f0101c28 <mem_init+0xbb7>
f0101c0f:	68 40 52 10 f0       	push   $0xf0105240
f0101c14:	68 ed 55 10 f0       	push   $0xf01055ed
f0101c19:	68 af 03 00 00       	push   $0x3af
f0101c1e:	68 ad 55 10 f0       	push   $0xf01055ad
f0101c23:	e8 78 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c28:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c2d:	89 f8                	mov    %edi,%eax
f0101c2f:	e8 2e ed ff ff       	call   f0100962 <check_va2pa>
f0101c34:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c37:	74 19                	je     f0101c52 <mem_init+0xbe1>
f0101c39:	68 6c 52 10 f0       	push   $0xf010526c
f0101c3e:	68 ed 55 10 f0       	push   $0xf01055ed
f0101c43:	68 b0 03 00 00       	push   $0x3b0
f0101c48:	68 ad 55 10 f0       	push   $0xf01055ad
f0101c4d:	e8 4e e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c52:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c57:	74 19                	je     f0101c72 <mem_init+0xc01>
f0101c59:	68 fa 57 10 f0       	push   $0xf01057fa
f0101c5e:	68 ed 55 10 f0       	push   $0xf01055ed
f0101c63:	68 b2 03 00 00       	push   $0x3b2
f0101c68:	68 ad 55 10 f0       	push   $0xf01055ad
f0101c6d:	e8 2e e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c72:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c77:	74 19                	je     f0101c92 <mem_init+0xc21>
f0101c79:	68 0b 58 10 f0       	push   $0xf010580b
f0101c7e:	68 ed 55 10 f0       	push   $0xf01055ed
f0101c83:	68 b3 03 00 00       	push   $0x3b3
f0101c88:	68 ad 55 10 f0       	push   $0xf01055ad
f0101c8d:	e8 0e e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c92:	83 ec 0c             	sub    $0xc,%esp
f0101c95:	6a 00                	push   $0x0
f0101c97:	e8 f6 f0 ff ff       	call   f0100d92 <page_alloc>
f0101c9c:	83 c4 10             	add    $0x10,%esp
f0101c9f:	39 c6                	cmp    %eax,%esi
f0101ca1:	75 04                	jne    f0101ca7 <mem_init+0xc36>
f0101ca3:	85 c0                	test   %eax,%eax
f0101ca5:	75 19                	jne    f0101cc0 <mem_init+0xc4f>
f0101ca7:	68 9c 52 10 f0       	push   $0xf010529c
f0101cac:	68 ed 55 10 f0       	push   $0xf01055ed
f0101cb1:	68 b6 03 00 00       	push   $0x3b6
f0101cb6:	68 ad 55 10 f0       	push   $0xf01055ad
f0101cbb:	e8 e0 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cc0:	83 ec 08             	sub    $0x8,%esp
f0101cc3:	6a 00                	push   $0x0
f0101cc5:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101ccb:	e8 ce f2 ff ff       	call   f0100f9e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cd0:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101cd6:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cdb:	89 f8                	mov    %edi,%eax
f0101cdd:	e8 80 ec ff ff       	call   f0100962 <check_va2pa>
f0101ce2:	83 c4 10             	add    $0x10,%esp
f0101ce5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ce8:	74 19                	je     f0101d03 <mem_init+0xc92>
f0101cea:	68 c0 52 10 f0       	push   $0xf01052c0
f0101cef:	68 ed 55 10 f0       	push   $0xf01055ed
f0101cf4:	68 ba 03 00 00       	push   $0x3ba
f0101cf9:	68 ad 55 10 f0       	push   $0xf01055ad
f0101cfe:	e8 9d e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d03:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d08:	89 f8                	mov    %edi,%eax
f0101d0a:	e8 53 ec ff ff       	call   f0100962 <check_va2pa>
f0101d0f:	89 da                	mov    %ebx,%edx
f0101d11:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101d17:	c1 fa 03             	sar    $0x3,%edx
f0101d1a:	c1 e2 0c             	shl    $0xc,%edx
f0101d1d:	39 d0                	cmp    %edx,%eax
f0101d1f:	74 19                	je     f0101d3a <mem_init+0xcc9>
f0101d21:	68 6c 52 10 f0       	push   $0xf010526c
f0101d26:	68 ed 55 10 f0       	push   $0xf01055ed
f0101d2b:	68 bb 03 00 00       	push   $0x3bb
f0101d30:	68 ad 55 10 f0       	push   $0xf01055ad
f0101d35:	e8 66 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101d3a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d3f:	74 19                	je     f0101d5a <mem_init+0xce9>
f0101d41:	68 b1 57 10 f0       	push   $0xf01057b1
f0101d46:	68 ed 55 10 f0       	push   $0xf01055ed
f0101d4b:	68 bc 03 00 00       	push   $0x3bc
f0101d50:	68 ad 55 10 f0       	push   $0xf01055ad
f0101d55:	e8 46 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d5a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d5f:	74 19                	je     f0101d7a <mem_init+0xd09>
f0101d61:	68 0b 58 10 f0       	push   $0xf010580b
f0101d66:	68 ed 55 10 f0       	push   $0xf01055ed
f0101d6b:	68 bd 03 00 00       	push   $0x3bd
f0101d70:	68 ad 55 10 f0       	push   $0xf01055ad
f0101d75:	e8 26 e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d7a:	6a 00                	push   $0x0
f0101d7c:	68 00 10 00 00       	push   $0x1000
f0101d81:	53                   	push   %ebx
f0101d82:	57                   	push   %edi
f0101d83:	e8 64 f2 ff ff       	call   f0100fec <page_insert>
f0101d88:	83 c4 10             	add    $0x10,%esp
f0101d8b:	85 c0                	test   %eax,%eax
f0101d8d:	74 19                	je     f0101da8 <mem_init+0xd37>
f0101d8f:	68 e4 52 10 f0       	push   $0xf01052e4
f0101d94:	68 ed 55 10 f0       	push   $0xf01055ed
f0101d99:	68 c0 03 00 00       	push   $0x3c0
f0101d9e:	68 ad 55 10 f0       	push   $0xf01055ad
f0101da3:	e8 f8 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101da8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dad:	75 19                	jne    f0101dc8 <mem_init+0xd57>
f0101daf:	68 1c 58 10 f0       	push   $0xf010581c
f0101db4:	68 ed 55 10 f0       	push   $0xf01055ed
f0101db9:	68 c1 03 00 00       	push   $0x3c1
f0101dbe:	68 ad 55 10 f0       	push   $0xf01055ad
f0101dc3:	e8 d8 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101dc8:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101dcb:	74 19                	je     f0101de6 <mem_init+0xd75>
f0101dcd:	68 28 58 10 f0       	push   $0xf0105828
f0101dd2:	68 ed 55 10 f0       	push   $0xf01055ed
f0101dd7:	68 c2 03 00 00       	push   $0x3c2
f0101ddc:	68 ad 55 10 f0       	push   $0xf01055ad
f0101de1:	e8 ba e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101de6:	83 ec 08             	sub    $0x8,%esp
f0101de9:	68 00 10 00 00       	push   $0x1000
f0101dee:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101df4:	e8 a5 f1 ff ff       	call   f0100f9e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101df9:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101dff:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e04:	89 f8                	mov    %edi,%eax
f0101e06:	e8 57 eb ff ff       	call   f0100962 <check_va2pa>
f0101e0b:	83 c4 10             	add    $0x10,%esp
f0101e0e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e11:	74 19                	je     f0101e2c <mem_init+0xdbb>
f0101e13:	68 c0 52 10 f0       	push   $0xf01052c0
f0101e18:	68 ed 55 10 f0       	push   $0xf01055ed
f0101e1d:	68 c6 03 00 00       	push   $0x3c6
f0101e22:	68 ad 55 10 f0       	push   $0xf01055ad
f0101e27:	e8 74 e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e2c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e31:	89 f8                	mov    %edi,%eax
f0101e33:	e8 2a eb ff ff       	call   f0100962 <check_va2pa>
f0101e38:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e3b:	74 19                	je     f0101e56 <mem_init+0xde5>
f0101e3d:	68 1c 53 10 f0       	push   $0xf010531c
f0101e42:	68 ed 55 10 f0       	push   $0xf01055ed
f0101e47:	68 c7 03 00 00       	push   $0x3c7
f0101e4c:	68 ad 55 10 f0       	push   $0xf01055ad
f0101e51:	e8 4a e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e56:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e5b:	74 19                	je     f0101e76 <mem_init+0xe05>
f0101e5d:	68 3d 58 10 f0       	push   $0xf010583d
f0101e62:	68 ed 55 10 f0       	push   $0xf01055ed
f0101e67:	68 c8 03 00 00       	push   $0x3c8
f0101e6c:	68 ad 55 10 f0       	push   $0xf01055ad
f0101e71:	e8 2a e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e76:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e7b:	74 19                	je     f0101e96 <mem_init+0xe25>
f0101e7d:	68 0b 58 10 f0       	push   $0xf010580b
f0101e82:	68 ed 55 10 f0       	push   $0xf01055ed
f0101e87:	68 c9 03 00 00       	push   $0x3c9
f0101e8c:	68 ad 55 10 f0       	push   $0xf01055ad
f0101e91:	e8 0a e2 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e96:	83 ec 0c             	sub    $0xc,%esp
f0101e99:	6a 00                	push   $0x0
f0101e9b:	e8 f2 ee ff ff       	call   f0100d92 <page_alloc>
f0101ea0:	83 c4 10             	add    $0x10,%esp
f0101ea3:	85 c0                	test   %eax,%eax
f0101ea5:	74 04                	je     f0101eab <mem_init+0xe3a>
f0101ea7:	39 c3                	cmp    %eax,%ebx
f0101ea9:	74 19                	je     f0101ec4 <mem_init+0xe53>
f0101eab:	68 44 53 10 f0       	push   $0xf0105344
f0101eb0:	68 ed 55 10 f0       	push   $0xf01055ed
f0101eb5:	68 cc 03 00 00       	push   $0x3cc
f0101eba:	68 ad 55 10 f0       	push   $0xf01055ad
f0101ebf:	e8 dc e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ec4:	83 ec 0c             	sub    $0xc,%esp
f0101ec7:	6a 00                	push   $0x0
f0101ec9:	e8 c4 ee ff ff       	call   f0100d92 <page_alloc>
f0101ece:	83 c4 10             	add    $0x10,%esp
f0101ed1:	85 c0                	test   %eax,%eax
f0101ed3:	74 19                	je     f0101eee <mem_init+0xe7d>
f0101ed5:	68 5f 57 10 f0       	push   $0xf010575f
f0101eda:	68 ed 55 10 f0       	push   $0xf01055ed
f0101edf:	68 cf 03 00 00       	push   $0x3cf
f0101ee4:	68 ad 55 10 f0       	push   $0xf01055ad
f0101ee9:	e8 b2 e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eee:	8b 0d 48 2c 17 f0    	mov    0xf0172c48,%ecx
f0101ef4:	8b 11                	mov    (%ecx),%edx
f0101ef6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101efc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eff:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101f05:	c1 f8 03             	sar    $0x3,%eax
f0101f08:	c1 e0 0c             	shl    $0xc,%eax
f0101f0b:	39 c2                	cmp    %eax,%edx
f0101f0d:	74 19                	je     f0101f28 <mem_init+0xeb7>
f0101f0f:	68 e8 4f 10 f0       	push   $0xf0104fe8
f0101f14:	68 ed 55 10 f0       	push   $0xf01055ed
f0101f19:	68 d2 03 00 00       	push   $0x3d2
f0101f1e:	68 ad 55 10 f0       	push   $0xf01055ad
f0101f23:	e8 78 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f28:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f31:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f36:	74 19                	je     f0101f51 <mem_init+0xee0>
f0101f38:	68 c2 57 10 f0       	push   $0xf01057c2
f0101f3d:	68 ed 55 10 f0       	push   $0xf01055ed
f0101f42:	68 d4 03 00 00       	push   $0x3d4
f0101f47:	68 ad 55 10 f0       	push   $0xf01055ad
f0101f4c:	e8 4f e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f51:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f54:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f5a:	83 ec 0c             	sub    $0xc,%esp
f0101f5d:	50                   	push   %eax
f0101f5e:	e8 9f ee ff ff       	call   f0100e02 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f63:	83 c4 0c             	add    $0xc,%esp
f0101f66:	6a 01                	push   $0x1
f0101f68:	68 00 10 40 00       	push   $0x401000
f0101f6d:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101f73:	e8 ec ee ff ff       	call   f0100e64 <pgdir_walk>
f0101f78:	89 c7                	mov    %eax,%edi
f0101f7a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f7d:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0101f82:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f85:	8b 40 04             	mov    0x4(%eax),%eax
f0101f88:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f8d:	8b 0d 44 2c 17 f0    	mov    0xf0172c44,%ecx
f0101f93:	89 c2                	mov    %eax,%edx
f0101f95:	c1 ea 0c             	shr    $0xc,%edx
f0101f98:	83 c4 10             	add    $0x10,%esp
f0101f9b:	39 ca                	cmp    %ecx,%edx
f0101f9d:	72 15                	jb     f0101fb4 <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f9f:	50                   	push   %eax
f0101fa0:	68 84 4d 10 f0       	push   $0xf0104d84
f0101fa5:	68 db 03 00 00       	push   $0x3db
f0101faa:	68 ad 55 10 f0       	push   $0xf01055ad
f0101faf:	e8 ec e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fb4:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fb9:	39 c7                	cmp    %eax,%edi
f0101fbb:	74 19                	je     f0101fd6 <mem_init+0xf65>
f0101fbd:	68 4e 58 10 f0       	push   $0xf010584e
f0101fc2:	68 ed 55 10 f0       	push   $0xf01055ed
f0101fc7:	68 dc 03 00 00       	push   $0x3dc
f0101fcc:	68 ad 55 10 f0       	push   $0xf01055ad
f0101fd1:	e8 ca e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fd6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fd9:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fe0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe3:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fe9:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101fef:	c1 f8 03             	sar    $0x3,%eax
f0101ff2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ff5:	89 c2                	mov    %eax,%edx
f0101ff7:	c1 ea 0c             	shr    $0xc,%edx
f0101ffa:	39 d1                	cmp    %edx,%ecx
f0101ffc:	77 12                	ja     f0102010 <mem_init+0xf9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ffe:	50                   	push   %eax
f0101fff:	68 84 4d 10 f0       	push   $0xf0104d84
f0102004:	6a 56                	push   $0x56
f0102006:	68 d3 55 10 f0       	push   $0xf01055d3
f010200b:	e8 90 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102010:	83 ec 04             	sub    $0x4,%esp
f0102013:	68 00 10 00 00       	push   $0x1000
f0102018:	68 ff 00 00 00       	push   $0xff
f010201d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102022:	50                   	push   %eax
f0102023:	e8 92 23 00 00       	call   f01043ba <memset>
	page_free(pp0);
f0102028:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010202b:	89 3c 24             	mov    %edi,(%esp)
f010202e:	e8 cf ed ff ff       	call   f0100e02 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102033:	83 c4 0c             	add    $0xc,%esp
f0102036:	6a 01                	push   $0x1
f0102038:	6a 00                	push   $0x0
f010203a:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102040:	e8 1f ee ff ff       	call   f0100e64 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102045:	89 fa                	mov    %edi,%edx
f0102047:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f010204d:	c1 fa 03             	sar    $0x3,%edx
f0102050:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102053:	89 d0                	mov    %edx,%eax
f0102055:	c1 e8 0c             	shr    $0xc,%eax
f0102058:	83 c4 10             	add    $0x10,%esp
f010205b:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102061:	72 12                	jb     f0102075 <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102063:	52                   	push   %edx
f0102064:	68 84 4d 10 f0       	push   $0xf0104d84
f0102069:	6a 56                	push   $0x56
f010206b:	68 d3 55 10 f0       	push   $0xf01055d3
f0102070:	e8 2b e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102075:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010207b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010207e:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102084:	f6 00 01             	testb  $0x1,(%eax)
f0102087:	74 19                	je     f01020a2 <mem_init+0x1031>
f0102089:	68 66 58 10 f0       	push   $0xf0105866
f010208e:	68 ed 55 10 f0       	push   $0xf01055ed
f0102093:	68 e6 03 00 00       	push   $0x3e6
f0102098:	68 ad 55 10 f0       	push   $0xf01055ad
f010209d:	e8 fe df ff ff       	call   f01000a0 <_panic>
f01020a2:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020a5:	39 d0                	cmp    %edx,%eax
f01020a7:	75 db                	jne    f0102084 <mem_init+0x1013>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020a9:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01020ae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020b4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020bd:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01020c0:	89 3d 80 1f 17 f0    	mov    %edi,0xf0171f80

	// free the pages we took
	page_free(pp0);
f01020c6:	83 ec 0c             	sub    $0xc,%esp
f01020c9:	50                   	push   %eax
f01020ca:	e8 33 ed ff ff       	call   f0100e02 <page_free>
	page_free(pp1);
f01020cf:	89 1c 24             	mov    %ebx,(%esp)
f01020d2:	e8 2b ed ff ff       	call   f0100e02 <page_free>
	page_free(pp2);
f01020d7:	89 34 24             	mov    %esi,(%esp)
f01020da:	e8 23 ed ff ff       	call   f0100e02 <page_free>

	cprintf("check_page() succeeded!\n");
f01020df:	c7 04 24 7d 58 10 f0 	movl   $0xf010587d,(%esp)
f01020e6:	e8 fd 0e 00 00       	call   f0102fe8 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,UPAGES,ROUNDUP(npages*sizeof(struct PageInfo),PGSIZE),PADDR(pages),PTE_U);
f01020eb:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020f0:	83 c4 10             	add    $0x10,%esp
f01020f3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020f8:	77 15                	ja     f010210f <mem_init+0x109e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020fa:	50                   	push   %eax
f01020fb:	68 a8 4d 10 f0       	push   $0xf0104da8
f0102100:	68 ce 00 00 00       	push   $0xce
f0102105:	68 ad 55 10 f0       	push   $0xf01055ad
f010210a:	e8 91 df ff ff       	call   f01000a0 <_panic>
f010210f:	8b 15 44 2c 17 f0    	mov    0xf0172c44,%edx
f0102115:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f010211c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102122:	83 ec 08             	sub    $0x8,%esp
f0102125:	6a 04                	push   $0x4
f0102127:	05 00 00 00 10       	add    $0x10000000,%eax
f010212c:	50                   	push   %eax
f010212d:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102132:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102137:	e8 bb ed ff ff       	call   f0100ef7 <boot_map_region>
	boot_map_region(kern_pgdir,(uintptr_t)pages,ROUNDUP(npages*sizeof(struct PageInfo),PGSIZE),PADDR(pages),PTE_W);
f010213c:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102142:	83 c4 10             	add    $0x10,%esp
f0102145:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010214b:	77 15                	ja     f0102162 <mem_init+0x10f1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010214d:	52                   	push   %edx
f010214e:	68 a8 4d 10 f0       	push   $0xf0104da8
f0102153:	68 cf 00 00 00       	push   $0xcf
f0102158:	68 ad 55 10 f0       	push   $0xf01055ad
f010215d:	e8 3e df ff ff       	call   f01000a0 <_panic>
f0102162:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f0102167:	8d 0c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ecx
f010216e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102174:	83 ec 08             	sub    $0x8,%esp
f0102177:	6a 02                	push   $0x2
f0102179:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f010217f:	50                   	push   %eax
f0102180:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102185:	e8 6d ed ff ff       	call   f0100ef7 <boot_map_region>
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here. 
	
	boot_map_region(kern_pgdir,UENVS,ROUNDUP(NENV*sizeof(struct Env),PGSIZE),PADDR(envs),PTE_U);
f010218a:	a1 88 1f 17 f0       	mov    0xf0171f88,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010218f:	83 c4 10             	add    $0x10,%esp
f0102192:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102197:	77 15                	ja     f01021ae <mem_init+0x113d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102199:	50                   	push   %eax
f010219a:	68 a8 4d 10 f0       	push   $0xf0104da8
f010219f:	68 d9 00 00 00       	push   $0xd9
f01021a4:	68 ad 55 10 f0       	push   $0xf01055ad
f01021a9:	e8 f2 de ff ff       	call   f01000a0 <_panic>
f01021ae:	83 ec 08             	sub    $0x8,%esp
f01021b1:	6a 04                	push   $0x4
f01021b3:	05 00 00 00 10       	add    $0x10000000,%eax
f01021b8:	50                   	push   %eax
f01021b9:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01021be:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01021c3:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01021c8:	e8 2a ed ff ff       	call   f0100ef7 <boot_map_region>
	boot_map_region(kern_pgdir,(uintptr_t)envs,ROUNDUP(NENV*sizeof(struct Env),PGSIZE),PADDR(envs),PTE_W);
f01021cd:	8b 15 88 1f 17 f0    	mov    0xf0171f88,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021d3:	83 c4 10             	add    $0x10,%esp
f01021d6:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01021dc:	77 15                	ja     f01021f3 <mem_init+0x1182>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021de:	52                   	push   %edx
f01021df:	68 a8 4d 10 f0       	push   $0xf0104da8
f01021e4:	68 da 00 00 00       	push   $0xda
f01021e9:	68 ad 55 10 f0       	push   $0xf01055ad
f01021ee:	e8 ad de ff ff       	call   f01000a0 <_panic>
f01021f3:	83 ec 08             	sub    $0x8,%esp
f01021f6:	6a 02                	push   $0x2
f01021f8:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f01021fe:	50                   	push   %eax
f01021ff:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102204:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102209:	e8 e9 ec ff ff       	call   f0100ef7 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010220e:	83 c4 10             	add    $0x10,%esp
f0102211:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f0102216:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010221b:	77 15                	ja     f0102232 <mem_init+0x11c1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010221d:	50                   	push   %eax
f010221e:	68 a8 4d 10 f0       	push   $0xf0104da8
f0102223:	68 e8 00 00 00       	push   $0xe8
f0102228:	68 ad 55 10 f0       	push   $0xf01055ad
f010222d:	e8 6e de ff ff       	call   f01000a0 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W);
f0102232:	83 ec 08             	sub    $0x8,%esp
f0102235:	6a 02                	push   $0x2
f0102237:	68 00 10 11 00       	push   $0x111000
f010223c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102241:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102246:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f010224b:	e8 a7 ec ff ff       	call   f0100ef7 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,KERNBASE,(-1>>31)-KERNBASE,0,PTE_W);
f0102250:	83 c4 08             	add    $0x8,%esp
f0102253:	6a 02                	push   $0x2
f0102255:	6a 00                	push   $0x0
f0102257:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010225c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102261:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102266:	e8 8c ec ff ff       	call   f0100ef7 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010226b:	8b 1d 48 2c 17 f0    	mov    0xf0172c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102271:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f0102276:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102279:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102280:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102285:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102288:	8b 3d 4c 2c 17 f0    	mov    0xf0172c4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010228e:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102291:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102294:	be 00 00 00 00       	mov    $0x0,%esi
f0102299:	eb 55                	jmp    f01022f0 <mem_init+0x127f>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010229b:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f01022a1:	89 d8                	mov    %ebx,%eax
f01022a3:	e8 ba e6 ff ff       	call   f0100962 <check_va2pa>
f01022a8:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01022af:	77 15                	ja     f01022c6 <mem_init+0x1255>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022b1:	57                   	push   %edi
f01022b2:	68 a8 4d 10 f0       	push   $0xf0104da8
f01022b7:	68 22 03 00 00       	push   $0x322
f01022bc:	68 ad 55 10 f0       	push   $0xf01055ad
f01022c1:	e8 da dd ff ff       	call   f01000a0 <_panic>
f01022c6:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01022cd:	39 d0                	cmp    %edx,%eax
f01022cf:	74 19                	je     f01022ea <mem_init+0x1279>
f01022d1:	68 68 53 10 f0       	push   $0xf0105368
f01022d6:	68 ed 55 10 f0       	push   $0xf01055ed
f01022db:	68 22 03 00 00       	push   $0x322
f01022e0:	68 ad 55 10 f0       	push   $0xf01055ad
f01022e5:	e8 b6 dd ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022ea:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022f0:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01022f3:	77 a6                	ja     f010229b <mem_init+0x122a>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01022f5:	8b 3d 88 1f 17 f0    	mov    0xf0171f88,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022fb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01022fe:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102303:	89 f2                	mov    %esi,%edx
f0102305:	89 d8                	mov    %ebx,%eax
f0102307:	e8 56 e6 ff ff       	call   f0100962 <check_va2pa>
f010230c:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102313:	77 15                	ja     f010232a <mem_init+0x12b9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102315:	57                   	push   %edi
f0102316:	68 a8 4d 10 f0       	push   $0xf0104da8
f010231b:	68 27 03 00 00       	push   $0x327
f0102320:	68 ad 55 10 f0       	push   $0xf01055ad
f0102325:	e8 76 dd ff ff       	call   f01000a0 <_panic>
f010232a:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f0102331:	39 c2                	cmp    %eax,%edx
f0102333:	74 19                	je     f010234e <mem_init+0x12dd>
f0102335:	68 9c 53 10 f0       	push   $0xf010539c
f010233a:	68 ed 55 10 f0       	push   $0xf01055ed
f010233f:	68 27 03 00 00       	push   $0x327
f0102344:	68 ad 55 10 f0       	push   $0xf01055ad
f0102349:	e8 52 dd ff ff       	call   f01000a0 <_panic>
f010234e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102354:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f010235a:	75 a7                	jne    f0102303 <mem_init+0x1292>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010235c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010235f:	c1 e7 0c             	shl    $0xc,%edi
f0102362:	be 00 00 00 00       	mov    $0x0,%esi
f0102367:	eb 30                	jmp    f0102399 <mem_init+0x1328>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102369:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f010236f:	89 d8                	mov    %ebx,%eax
f0102371:	e8 ec e5 ff ff       	call   f0100962 <check_va2pa>
f0102376:	39 c6                	cmp    %eax,%esi
f0102378:	74 19                	je     f0102393 <mem_init+0x1322>
f010237a:	68 d0 53 10 f0       	push   $0xf01053d0
f010237f:	68 ed 55 10 f0       	push   $0xf01055ed
f0102384:	68 2b 03 00 00       	push   $0x32b
f0102389:	68 ad 55 10 f0       	push   $0xf01055ad
f010238e:	e8 0d dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102393:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102399:	39 fe                	cmp    %edi,%esi
f010239b:	72 cc                	jb     f0102369 <mem_init+0x12f8>
f010239d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01023a2:	89 f2                	mov    %esi,%edx
f01023a4:	89 d8                	mov    %ebx,%eax
f01023a6:	e8 b7 e5 ff ff       	call   f0100962 <check_va2pa>
f01023ab:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f01023b1:	39 c2                	cmp    %eax,%edx
f01023b3:	74 19                	je     f01023ce <mem_init+0x135d>
f01023b5:	68 f8 53 10 f0       	push   $0xf01053f8
f01023ba:	68 ed 55 10 f0       	push   $0xf01055ed
f01023bf:	68 2f 03 00 00       	push   $0x32f
f01023c4:	68 ad 55 10 f0       	push   $0xf01055ad
f01023c9:	e8 d2 dc ff ff       	call   f01000a0 <_panic>
f01023ce:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023d4:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01023da:	75 c6                	jne    f01023a2 <mem_init+0x1331>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023dc:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023e1:	89 d8                	mov    %ebx,%eax
f01023e3:	e8 7a e5 ff ff       	call   f0100962 <check_va2pa>
f01023e8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023eb:	74 51                	je     f010243e <mem_init+0x13cd>
f01023ed:	68 40 54 10 f0       	push   $0xf0105440
f01023f2:	68 ed 55 10 f0       	push   $0xf01055ed
f01023f7:	68 30 03 00 00       	push   $0x330
f01023fc:	68 ad 55 10 f0       	push   $0xf01055ad
f0102401:	e8 9a dc ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102406:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010240b:	72 36                	jb     f0102443 <mem_init+0x13d2>
f010240d:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102412:	76 07                	jbe    f010241b <mem_init+0x13aa>
f0102414:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102419:	75 28                	jne    f0102443 <mem_init+0x13d2>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010241b:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010241f:	0f 85 83 00 00 00    	jne    f01024a8 <mem_init+0x1437>
f0102425:	68 96 58 10 f0       	push   $0xf0105896
f010242a:	68 ed 55 10 f0       	push   $0xf01055ed
f010242f:	68 39 03 00 00       	push   $0x339
f0102434:	68 ad 55 10 f0       	push   $0xf01055ad
f0102439:	e8 62 dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010243e:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102443:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102448:	76 3f                	jbe    f0102489 <mem_init+0x1418>
				assert(pgdir[i] & PTE_P);
f010244a:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f010244d:	f6 c2 01             	test   $0x1,%dl
f0102450:	75 19                	jne    f010246b <mem_init+0x13fa>
f0102452:	68 96 58 10 f0       	push   $0xf0105896
f0102457:	68 ed 55 10 f0       	push   $0xf01055ed
f010245c:	68 3d 03 00 00       	push   $0x33d
f0102461:	68 ad 55 10 f0       	push   $0xf01055ad
f0102466:	e8 35 dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f010246b:	f6 c2 02             	test   $0x2,%dl
f010246e:	75 38                	jne    f01024a8 <mem_init+0x1437>
f0102470:	68 a7 58 10 f0       	push   $0xf01058a7
f0102475:	68 ed 55 10 f0       	push   $0xf01055ed
f010247a:	68 3e 03 00 00       	push   $0x33e
f010247f:	68 ad 55 10 f0       	push   $0xf01055ad
f0102484:	e8 17 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102489:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010248d:	74 19                	je     f01024a8 <mem_init+0x1437>
f010248f:	68 b8 58 10 f0       	push   $0xf01058b8
f0102494:	68 ed 55 10 f0       	push   $0xf01055ed
f0102499:	68 40 03 00 00       	push   $0x340
f010249e:	68 ad 55 10 f0       	push   $0xf01055ad
f01024a3:	e8 f8 db ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01024a8:	83 c0 01             	add    $0x1,%eax
f01024ab:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01024b0:	0f 86 50 ff ff ff    	jbe    f0102406 <mem_init+0x1395>
				assert(pgdir[i] == 0);
				
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01024b6:	83 ec 0c             	sub    $0xc,%esp
f01024b9:	68 70 54 10 f0       	push   $0xf0105470
f01024be:	e8 25 0b 00 00       	call   f0102fe8 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024c3:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024c8:	83 c4 10             	add    $0x10,%esp
f01024cb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024d0:	77 15                	ja     f01024e7 <mem_init+0x1476>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024d2:	50                   	push   %eax
f01024d3:	68 a8 4d 10 f0       	push   $0xf0104da8
f01024d8:	68 ff 00 00 00       	push   $0xff
f01024dd:	68 ad 55 10 f0       	push   $0xf01055ad
f01024e2:	e8 b9 db ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01024e7:	05 00 00 00 10       	add    $0x10000000,%eax
f01024ec:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01024ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01024f4:	e8 47 e5 ff ff       	call   f0100a40 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01024f9:	0f 20 c0             	mov    %cr0,%eax
f01024fc:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01024ff:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102504:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102507:	83 ec 0c             	sub    $0xc,%esp
f010250a:	6a 00                	push   $0x0
f010250c:	e8 81 e8 ff ff       	call   f0100d92 <page_alloc>
f0102511:	89 c3                	mov    %eax,%ebx
f0102513:	83 c4 10             	add    $0x10,%esp
f0102516:	85 c0                	test   %eax,%eax
f0102518:	75 19                	jne    f0102533 <mem_init+0x14c2>
f010251a:	68 b4 56 10 f0       	push   $0xf01056b4
f010251f:	68 ed 55 10 f0       	push   $0xf01055ed
f0102524:	68 01 04 00 00       	push   $0x401
f0102529:	68 ad 55 10 f0       	push   $0xf01055ad
f010252e:	e8 6d db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0102533:	83 ec 0c             	sub    $0xc,%esp
f0102536:	6a 00                	push   $0x0
f0102538:	e8 55 e8 ff ff       	call   f0100d92 <page_alloc>
f010253d:	89 c7                	mov    %eax,%edi
f010253f:	83 c4 10             	add    $0x10,%esp
f0102542:	85 c0                	test   %eax,%eax
f0102544:	75 19                	jne    f010255f <mem_init+0x14ee>
f0102546:	68 ca 56 10 f0       	push   $0xf01056ca
f010254b:	68 ed 55 10 f0       	push   $0xf01055ed
f0102550:	68 02 04 00 00       	push   $0x402
f0102555:	68 ad 55 10 f0       	push   $0xf01055ad
f010255a:	e8 41 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010255f:	83 ec 0c             	sub    $0xc,%esp
f0102562:	6a 00                	push   $0x0
f0102564:	e8 29 e8 ff ff       	call   f0100d92 <page_alloc>
f0102569:	89 c6                	mov    %eax,%esi
f010256b:	83 c4 10             	add    $0x10,%esp
f010256e:	85 c0                	test   %eax,%eax
f0102570:	75 19                	jne    f010258b <mem_init+0x151a>
f0102572:	68 e0 56 10 f0       	push   $0xf01056e0
f0102577:	68 ed 55 10 f0       	push   $0xf01055ed
f010257c:	68 03 04 00 00       	push   $0x403
f0102581:	68 ad 55 10 f0       	push   $0xf01055ad
f0102586:	e8 15 db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f010258b:	83 ec 0c             	sub    $0xc,%esp
f010258e:	53                   	push   %ebx
f010258f:	e8 6e e8 ff ff       	call   f0100e02 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102594:	89 f8                	mov    %edi,%eax
f0102596:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f010259c:	c1 f8 03             	sar    $0x3,%eax
f010259f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025a2:	89 c2                	mov    %eax,%edx
f01025a4:	c1 ea 0c             	shr    $0xc,%edx
f01025a7:	83 c4 10             	add    $0x10,%esp
f01025aa:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01025b0:	72 12                	jb     f01025c4 <mem_init+0x1553>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025b2:	50                   	push   %eax
f01025b3:	68 84 4d 10 f0       	push   $0xf0104d84
f01025b8:	6a 56                	push   $0x56
f01025ba:	68 d3 55 10 f0       	push   $0xf01055d3
f01025bf:	e8 dc da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01025c4:	83 ec 04             	sub    $0x4,%esp
f01025c7:	68 00 10 00 00       	push   $0x1000
f01025cc:	6a 01                	push   $0x1
f01025ce:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025d3:	50                   	push   %eax
f01025d4:	e8 e1 1d 00 00       	call   f01043ba <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025d9:	89 f0                	mov    %esi,%eax
f01025db:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01025e1:	c1 f8 03             	sar    $0x3,%eax
f01025e4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025e7:	89 c2                	mov    %eax,%edx
f01025e9:	c1 ea 0c             	shr    $0xc,%edx
f01025ec:	83 c4 10             	add    $0x10,%esp
f01025ef:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01025f5:	72 12                	jb     f0102609 <mem_init+0x1598>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025f7:	50                   	push   %eax
f01025f8:	68 84 4d 10 f0       	push   $0xf0104d84
f01025fd:	6a 56                	push   $0x56
f01025ff:	68 d3 55 10 f0       	push   $0xf01055d3
f0102604:	e8 97 da ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102609:	83 ec 04             	sub    $0x4,%esp
f010260c:	68 00 10 00 00       	push   $0x1000
f0102611:	6a 02                	push   $0x2
f0102613:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102618:	50                   	push   %eax
f0102619:	e8 9c 1d 00 00       	call   f01043ba <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010261e:	6a 02                	push   $0x2
f0102620:	68 00 10 00 00       	push   $0x1000
f0102625:	57                   	push   %edi
f0102626:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f010262c:	e8 bb e9 ff ff       	call   f0100fec <page_insert>
	assert(pp1->pp_ref == 1);
f0102631:	83 c4 20             	add    $0x20,%esp
f0102634:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102639:	74 19                	je     f0102654 <mem_init+0x15e3>
f010263b:	68 b1 57 10 f0       	push   $0xf01057b1
f0102640:	68 ed 55 10 f0       	push   $0xf01055ed
f0102645:	68 08 04 00 00       	push   $0x408
f010264a:	68 ad 55 10 f0       	push   $0xf01055ad
f010264f:	e8 4c da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102654:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010265b:	01 01 01 
f010265e:	74 19                	je     f0102679 <mem_init+0x1608>
f0102660:	68 90 54 10 f0       	push   $0xf0105490
f0102665:	68 ed 55 10 f0       	push   $0xf01055ed
f010266a:	68 09 04 00 00       	push   $0x409
f010266f:	68 ad 55 10 f0       	push   $0xf01055ad
f0102674:	e8 27 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102679:	6a 02                	push   $0x2
f010267b:	68 00 10 00 00       	push   $0x1000
f0102680:	56                   	push   %esi
f0102681:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102687:	e8 60 e9 ff ff       	call   f0100fec <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010268c:	83 c4 10             	add    $0x10,%esp
f010268f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102696:	02 02 02 
f0102699:	74 19                	je     f01026b4 <mem_init+0x1643>
f010269b:	68 b4 54 10 f0       	push   $0xf01054b4
f01026a0:	68 ed 55 10 f0       	push   $0xf01055ed
f01026a5:	68 0b 04 00 00       	push   $0x40b
f01026aa:	68 ad 55 10 f0       	push   $0xf01055ad
f01026af:	e8 ec d9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01026b4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01026b9:	74 19                	je     f01026d4 <mem_init+0x1663>
f01026bb:	68 d3 57 10 f0       	push   $0xf01057d3
f01026c0:	68 ed 55 10 f0       	push   $0xf01055ed
f01026c5:	68 0c 04 00 00       	push   $0x40c
f01026ca:	68 ad 55 10 f0       	push   $0xf01055ad
f01026cf:	e8 cc d9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01026d4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01026d9:	74 19                	je     f01026f4 <mem_init+0x1683>
f01026db:	68 3d 58 10 f0       	push   $0xf010583d
f01026e0:	68 ed 55 10 f0       	push   $0xf01055ed
f01026e5:	68 0d 04 00 00       	push   $0x40d
f01026ea:	68 ad 55 10 f0       	push   $0xf01055ad
f01026ef:	e8 ac d9 ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01026f4:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01026fb:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026fe:	89 f0                	mov    %esi,%eax
f0102700:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0102706:	c1 f8 03             	sar    $0x3,%eax
f0102709:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010270c:	89 c2                	mov    %eax,%edx
f010270e:	c1 ea 0c             	shr    $0xc,%edx
f0102711:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0102717:	72 12                	jb     f010272b <mem_init+0x16ba>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102719:	50                   	push   %eax
f010271a:	68 84 4d 10 f0       	push   $0xf0104d84
f010271f:	6a 56                	push   $0x56
f0102721:	68 d3 55 10 f0       	push   $0xf01055d3
f0102726:	e8 75 d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010272b:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102732:	03 03 03 
f0102735:	74 19                	je     f0102750 <mem_init+0x16df>
f0102737:	68 d8 54 10 f0       	push   $0xf01054d8
f010273c:	68 ed 55 10 f0       	push   $0xf01055ed
f0102741:	68 0f 04 00 00       	push   $0x40f
f0102746:	68 ad 55 10 f0       	push   $0xf01055ad
f010274b:	e8 50 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102750:	83 ec 08             	sub    $0x8,%esp
f0102753:	68 00 10 00 00       	push   $0x1000
f0102758:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f010275e:	e8 3b e8 ff ff       	call   f0100f9e <page_remove>
	assert(pp2->pp_ref == 0);
f0102763:	83 c4 10             	add    $0x10,%esp
f0102766:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010276b:	74 19                	je     f0102786 <mem_init+0x1715>
f010276d:	68 0b 58 10 f0       	push   $0xf010580b
f0102772:	68 ed 55 10 f0       	push   $0xf01055ed
f0102777:	68 11 04 00 00       	push   $0x411
f010277c:	68 ad 55 10 f0       	push   $0xf01055ad
f0102781:	e8 1a d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102786:	8b 0d 48 2c 17 f0    	mov    0xf0172c48,%ecx
f010278c:	8b 11                	mov    (%ecx),%edx
f010278e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102794:	89 d8                	mov    %ebx,%eax
f0102796:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f010279c:	c1 f8 03             	sar    $0x3,%eax
f010279f:	c1 e0 0c             	shl    $0xc,%eax
f01027a2:	39 c2                	cmp    %eax,%edx
f01027a4:	74 19                	je     f01027bf <mem_init+0x174e>
f01027a6:	68 e8 4f 10 f0       	push   $0xf0104fe8
f01027ab:	68 ed 55 10 f0       	push   $0xf01055ed
f01027b0:	68 14 04 00 00       	push   $0x414
f01027b5:	68 ad 55 10 f0       	push   $0xf01055ad
f01027ba:	e8 e1 d8 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01027bf:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01027c5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01027ca:	74 19                	je     f01027e5 <mem_init+0x1774>
f01027cc:	68 c2 57 10 f0       	push   $0xf01057c2
f01027d1:	68 ed 55 10 f0       	push   $0xf01055ed
f01027d6:	68 16 04 00 00       	push   $0x416
f01027db:	68 ad 55 10 f0       	push   $0xf01055ad
f01027e0:	e8 bb d8 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01027e5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01027eb:	83 ec 0c             	sub    $0xc,%esp
f01027ee:	53                   	push   %ebx
f01027ef:	e8 0e e6 ff ff       	call   f0100e02 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01027f4:	c7 04 24 04 55 10 f0 	movl   $0xf0105504,(%esp)
f01027fb:	e8 e8 07 00 00       	call   f0102fe8 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102800:	83 c4 10             	add    $0x10,%esp
f0102803:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102806:	5b                   	pop    %ebx
f0102807:	5e                   	pop    %esi
f0102808:	5f                   	pop    %edi
f0102809:	5d                   	pop    %ebp
f010280a:	c3                   	ret    

f010280b <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010280b:	55                   	push   %ebp
f010280c:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010280e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102811:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102814:	5d                   	pop    %ebp
f0102815:	c3                   	ret    

f0102816 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102816:	55                   	push   %ebp
f0102817:	89 e5                	mov    %esp,%ebp
f0102819:	57                   	push   %edi
f010281a:	56                   	push   %esi
f010281b:	53                   	push   %ebx
f010281c:	83 ec 20             	sub    $0x20,%esp
f010281f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102822:	8b 75 14             	mov    0x14(%ebp),%esi
	cprintf("user_mem_check va: %x, len: %x\n", va, len);
f0102825:	ff 75 10             	pushl  0x10(%ebp)
f0102828:	ff 75 0c             	pushl  0xc(%ebp)
f010282b:	68 30 55 10 f0       	push   $0xf0105530
f0102830:	e8 b3 07 00 00       	call   f0102fe8 <cprintf>
	uint32_t begin = (uint32_t) ROUNDDOWN(va, PGSIZE); 
f0102835:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102838:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t) ROUNDUP(va+len, PGSIZE);
f010283e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102841:	8b 55 10             	mov    0x10(%ebp),%edx
f0102844:	8d 84 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%eax
f010284b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102850:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	uint32_t i;
	for (i = (uint32_t)begin; i < end; i+=PGSIZE) {
f0102853:	83 c4 10             	add    $0x10,%esp
f0102856:	eb 50                	jmp    f01028a8 <user_mem_check+0x92>
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)i, 0);
f0102858:	83 ec 04             	sub    $0x4,%esp
f010285b:	6a 00                	push   $0x0
f010285d:	53                   	push   %ebx
f010285e:	ff 77 5c             	pushl  0x5c(%edi)
f0102861:	e8 fe e5 ff ff       	call   f0100e64 <pgdir_walk>
		
		if ((i>=ULIM) || !pte || !(*pte & PTE_P) || ((*pte & perm) != perm)) {
f0102866:	83 c4 10             	add    $0x10,%esp
f0102869:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010286f:	77 10                	ja     f0102881 <user_mem_check+0x6b>
f0102871:	85 c0                	test   %eax,%eax
f0102873:	74 0c                	je     f0102881 <user_mem_check+0x6b>
f0102875:	8b 00                	mov    (%eax),%eax
f0102877:	a8 01                	test   $0x1,%al
f0102879:	74 06                	je     f0102881 <user_mem_check+0x6b>
f010287b:	21 f0                	and    %esi,%eax
f010287d:	39 c6                	cmp    %eax,%esi
f010287f:	74 21                	je     f01028a2 <user_mem_check+0x8c>
			if(i < (uint32_t)va){
f0102881:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102884:	73 0f                	jae    f0102895 <user_mem_check+0x7f>
				user_mem_check_addr = (uint32_t) va;
f0102886:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102889:	a3 7c 1f 17 f0       	mov    %eax,0xf0171f7c
			}
			else{
				user_mem_check_addr = i;
			}

			return -E_FAULT;
f010288e:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102893:	eb 33                	jmp    f01028c8 <user_mem_check+0xb2>
		if ((i>=ULIM) || !pte || !(*pte & PTE_P) || ((*pte & perm) != perm)) {
			if(i < (uint32_t)va){
				user_mem_check_addr = (uint32_t) va;
			}
			else{
				user_mem_check_addr = i;
f0102895:	89 1d 7c 1f 17 f0    	mov    %ebx,0xf0171f7c
			}

			return -E_FAULT;
f010289b:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01028a0:	eb 26                	jmp    f01028c8 <user_mem_check+0xb2>
{
	cprintf("user_mem_check va: %x, len: %x\n", va, len);
	uint32_t begin = (uint32_t) ROUNDDOWN(va, PGSIZE); 
	uint32_t end = (uint32_t) ROUNDUP(va+len, PGSIZE);
	uint32_t i;
	for (i = (uint32_t)begin; i < end; i+=PGSIZE) {
f01028a2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028a8:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01028ab:	72 ab                	jb     f0102858 <user_mem_check+0x42>
			}

			return -E_FAULT;
		}
	}
	cprintf("user_mem_check success va: %x, len: %x\n", va, len);
f01028ad:	83 ec 04             	sub    $0x4,%esp
f01028b0:	ff 75 10             	pushl  0x10(%ebp)
f01028b3:	ff 75 0c             	pushl  0xc(%ebp)
f01028b6:	68 50 55 10 f0       	push   $0xf0105550
f01028bb:	e8 28 07 00 00       	call   f0102fe8 <cprintf>
	return 0;
f01028c0:	83 c4 10             	add    $0x10,%esp
f01028c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01028c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028cb:	5b                   	pop    %ebx
f01028cc:	5e                   	pop    %esi
f01028cd:	5f                   	pop    %edi
f01028ce:	5d                   	pop    %ebp
f01028cf:	c3                   	ret    

f01028d0 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01028d0:	55                   	push   %ebp
f01028d1:	89 e5                	mov    %esp,%ebp
f01028d3:	53                   	push   %ebx
f01028d4:	83 ec 04             	sub    $0x4,%esp
f01028d7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01028da:	8b 45 14             	mov    0x14(%ebp),%eax
f01028dd:	83 c8 04             	or     $0x4,%eax
f01028e0:	50                   	push   %eax
f01028e1:	ff 75 10             	pushl  0x10(%ebp)
f01028e4:	ff 75 0c             	pushl  0xc(%ebp)
f01028e7:	53                   	push   %ebx
f01028e8:	e8 29 ff ff ff       	call   f0102816 <user_mem_check>
f01028ed:	83 c4 10             	add    $0x10,%esp
f01028f0:	85 c0                	test   %eax,%eax
f01028f2:	79 21                	jns    f0102915 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f01028f4:	83 ec 04             	sub    $0x4,%esp
f01028f7:	ff 35 7c 1f 17 f0    	pushl  0xf0171f7c
f01028fd:	ff 73 48             	pushl  0x48(%ebx)
f0102900:	68 78 55 10 f0       	push   $0xf0105578
f0102905:	e8 de 06 00 00       	call   f0102fe8 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f010290a:	89 1c 24             	mov    %ebx,(%esp)
f010290d:	e8 bd 05 00 00       	call   f0102ecf <env_destroy>
f0102912:	83 c4 10             	add    $0x10,%esp
	}
}
f0102915:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102918:	c9                   	leave  
f0102919:	c3                   	ret    

f010291a <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010291a:	55                   	push   %ebp
f010291b:	89 e5                	mov    %esp,%ebp
f010291d:	57                   	push   %edi
f010291e:	56                   	push   %esi
f010291f:	53                   	push   %ebx
f0102920:	83 ec 0c             	sub    $0xc,%esp
f0102923:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	
	void* zaciatok = ROUNDDOWN(va,PGSIZE);
        void* koniec = ROUNDUP(va+len,PGSIZE);
f0102925:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010292c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

        for(int i=(int)zaciatok;i<(int)koniec;i+=PGSIZE)
f0102932:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102938:	89 d3                	mov    %edx,%ebx
f010293a:	eb 3d                	jmp    f0102979 <region_alloc+0x5f>
        {
                struct PageInfo* page = page_alloc(0);
f010293c:	83 ec 0c             	sub    $0xc,%esp
f010293f:	6a 00                	push   $0x0
f0102941:	e8 4c e4 ff ff       	call   f0100d92 <page_alloc>

                if(!page)
f0102946:	83 c4 10             	add    $0x10,%esp
f0102949:	85 c0                	test   %eax,%eax
f010294b:	75 17                	jne    f0102964 <region_alloc+0x4a>
                        panic("Unable to alloc a page!");
f010294d:	83 ec 04             	sub    $0x4,%esp
f0102950:	68 c6 58 10 f0       	push   $0xf01058c6
f0102955:	68 1e 01 00 00       	push   $0x11e
f010295a:	68 de 58 10 f0       	push   $0xf01058de
f010295f:	e8 3c d7 ff ff       	call   f01000a0 <_panic>

                page_insert(e->env_pgdir,page,(void*)i,PTE_P|PTE_W|PTE_U);
f0102964:	6a 07                	push   $0x7
f0102966:	53                   	push   %ebx
f0102967:	50                   	push   %eax
f0102968:	ff 77 5c             	pushl  0x5c(%edi)
f010296b:	e8 7c e6 ff ff       	call   f0100fec <page_insert>
	// (But only if you need it for load_icode.)
	
	void* zaciatok = ROUNDDOWN(va,PGSIZE);
        void* koniec = ROUNDUP(va+len,PGSIZE);

        for(int i=(int)zaciatok;i<(int)koniec;i+=PGSIZE)
f0102970:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102976:	83 c4 10             	add    $0x10,%esp
f0102979:	39 f3                	cmp    %esi,%ebx
f010297b:	7c bf                	jl     f010293c <region_alloc+0x22>

	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f010297d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102980:	5b                   	pop    %ebx
f0102981:	5e                   	pop    %esi
f0102982:	5f                   	pop    %edi
f0102983:	5d                   	pop    %ebp
f0102984:	c3                   	ret    

f0102985 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102985:	55                   	push   %ebp
f0102986:	89 e5                	mov    %esp,%ebp
f0102988:	8b 55 08             	mov    0x8(%ebp),%edx
f010298b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010298e:	85 d2                	test   %edx,%edx
f0102990:	75 11                	jne    f01029a3 <envid2env+0x1e>
		*env_store = curenv;
f0102992:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0102997:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010299a:	89 01                	mov    %eax,(%ecx)
		return 0;
f010299c:	b8 00 00 00 00       	mov    $0x0,%eax
f01029a1:	eb 5e                	jmp    f0102a01 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01029a3:	89 d0                	mov    %edx,%eax
f01029a5:	25 ff 03 00 00       	and    $0x3ff,%eax
f01029aa:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01029ad:	c1 e0 05             	shl    $0x5,%eax
f01029b0:	03 05 88 1f 17 f0    	add    0xf0171f88,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01029b6:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01029ba:	74 05                	je     f01029c1 <envid2env+0x3c>
f01029bc:	3b 50 48             	cmp    0x48(%eax),%edx
f01029bf:	74 10                	je     f01029d1 <envid2env+0x4c>
		*env_store = 0;
f01029c1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029c4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01029ca:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01029cf:	eb 30                	jmp    f0102a01 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01029d1:	84 c9                	test   %cl,%cl
f01029d3:	74 22                	je     f01029f7 <envid2env+0x72>
f01029d5:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f01029db:	39 d0                	cmp    %edx,%eax
f01029dd:	74 18                	je     f01029f7 <envid2env+0x72>
f01029df:	8b 4a 48             	mov    0x48(%edx),%ecx
f01029e2:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01029e5:	74 10                	je     f01029f7 <envid2env+0x72>
		*env_store = 0;
f01029e7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029ea:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01029f0:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01029f5:	eb 0a                	jmp    f0102a01 <envid2env+0x7c>
	}

	*env_store = e;
f01029f7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01029fa:	89 01                	mov    %eax,(%ecx)
	return 0;
f01029fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a01:	5d                   	pop    %ebp
f0102a02:	c3                   	ret    

f0102a03 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102a03:	55                   	push   %ebp
f0102a04:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102a06:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102a0b:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102a0e:	b8 23 00 00 00       	mov    $0x23,%eax
f0102a13:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102a15:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102a17:	b8 10 00 00 00       	mov    $0x10,%eax
f0102a1c:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102a1e:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102a20:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102a22:	ea 29 2a 10 f0 08 00 	ljmp   $0x8,$0xf0102a29
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102a29:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a2e:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102a31:	5d                   	pop    %ebp
f0102a32:	c3                   	ret    

f0102a33 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102a33:	55                   	push   %ebp
f0102a34:	89 e5                	mov    %esp,%ebp
f0102a36:	56                   	push   %esi
f0102a37:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	
	for(int i=NENV-1;i>=0;i--)
	{
		envs[i].env_id=0;
f0102a38:	8b 35 88 1f 17 f0    	mov    0xf0171f88,%esi
f0102a3e:	8b 15 8c 1f 17 f0    	mov    0xf0171f8c,%edx
f0102a44:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102a4a:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102a4d:	89 c1                	mov    %eax,%ecx
f0102a4f:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f0102a56:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link=env_free_list;
f0102a5d:	89 50 44             	mov    %edx,0x44(%eax)
f0102a60:	83 e8 60             	sub    $0x60,%eax
		env_free_list=&envs[i];		
f0102a63:	89 ca                	mov    %ecx,%edx
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	
	for(int i=NENV-1;i>=0;i--)
f0102a65:	39 d8                	cmp    %ebx,%eax
f0102a67:	75 e4                	jne    f0102a4d <env_init+0x1a>
f0102a69:	89 35 8c 1f 17 f0    	mov    %esi,0xf0171f8c
		envs[i].env_link=env_free_list;
		env_free_list=&envs[i];		
	}
	
	// Per-CPU part of the initialization
	env_init_percpu();
f0102a6f:	e8 8f ff ff ff       	call   f0102a03 <env_init_percpu>
}
f0102a74:	5b                   	pop    %ebx
f0102a75:	5e                   	pop    %esi
f0102a76:	5d                   	pop    %ebp
f0102a77:	c3                   	ret    

f0102a78 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102a78:	55                   	push   %ebp
f0102a79:	89 e5                	mov    %esp,%ebp
f0102a7b:	53                   	push   %ebx
f0102a7c:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102a7f:	8b 1d 8c 1f 17 f0    	mov    0xf0171f8c,%ebx
f0102a85:	85 db                	test   %ebx,%ebx
f0102a87:	0f 84 43 01 00 00    	je     f0102bd0 <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102a8d:	83 ec 0c             	sub    $0xc,%esp
f0102a90:	6a 01                	push   $0x1
f0102a92:	e8 fb e2 ff ff       	call   f0100d92 <page_alloc>
f0102a97:	83 c4 10             	add    $0x10,%esp
f0102a9a:	85 c0                	test   %eax,%eax
f0102a9c:	0f 84 35 01 00 00    	je     f0102bd7 <env_alloc+0x15f>
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.

	p->pp_ref++;
f0102aa2:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102aa7:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0102aad:	c1 f8 03             	sar    $0x3,%eax
f0102ab0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ab3:	89 c2                	mov    %eax,%edx
f0102ab5:	c1 ea 0c             	shr    $0xc,%edx
f0102ab8:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0102abe:	72 12                	jb     f0102ad2 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ac0:	50                   	push   %eax
f0102ac1:	68 84 4d 10 f0       	push   $0xf0104d84
f0102ac6:	6a 56                	push   $0x56
f0102ac8:	68 d3 55 10 f0       	push   $0xf01055d3
f0102acd:	e8 ce d5 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102ad2:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir=(pde_t*)page2kva(p);
f0102ad7:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f0102ada:	83 ec 04             	sub    $0x4,%esp
f0102add:	68 00 10 00 00       	push   $0x1000
f0102ae2:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102ae8:	50                   	push   %eax
f0102ae9:	e8 81 19 00 00       	call   f010446f <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102aee:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102af1:	83 c4 10             	add    $0x10,%esp
f0102af4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102af9:	77 15                	ja     f0102b10 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102afb:	50                   	push   %eax
f0102afc:	68 a8 4d 10 f0       	push   $0xf0104da8
f0102b01:	68 c5 00 00 00       	push   $0xc5
f0102b06:	68 de 58 10 f0       	push   $0xf01058de
f0102b0b:	e8 90 d5 ff ff       	call   f01000a0 <_panic>
f0102b10:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102b16:	83 ca 05             	or     $0x5,%edx
f0102b19:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102b1f:	8b 43 48             	mov    0x48(%ebx),%eax
f0102b22:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102b27:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102b2c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102b31:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102b34:	89 da                	mov    %ebx,%edx
f0102b36:	2b 15 88 1f 17 f0    	sub    0xf0171f88,%edx
f0102b3c:	c1 fa 05             	sar    $0x5,%edx
f0102b3f:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102b45:	09 d0                	or     %edx,%eax
f0102b47:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102b4a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b4d:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102b50:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102b57:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102b5e:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102b65:	83 ec 04             	sub    $0x4,%esp
f0102b68:	6a 44                	push   $0x44
f0102b6a:	6a 00                	push   $0x0
f0102b6c:	53                   	push   %ebx
f0102b6d:	e8 48 18 00 00       	call   f01043ba <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102b72:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102b78:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102b7e:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102b84:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102b8b:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102b91:	8b 43 44             	mov    0x44(%ebx),%eax
f0102b94:	a3 8c 1f 17 f0       	mov    %eax,0xf0171f8c
	*newenv_store = e;
f0102b99:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b9c:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102b9e:	8b 53 48             	mov    0x48(%ebx),%edx
f0102ba1:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0102ba6:	83 c4 10             	add    $0x10,%esp
f0102ba9:	85 c0                	test   %eax,%eax
f0102bab:	74 05                	je     f0102bb2 <env_alloc+0x13a>
f0102bad:	8b 40 48             	mov    0x48(%eax),%eax
f0102bb0:	eb 05                	jmp    f0102bb7 <env_alloc+0x13f>
f0102bb2:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb7:	83 ec 04             	sub    $0x4,%esp
f0102bba:	52                   	push   %edx
f0102bbb:	50                   	push   %eax
f0102bbc:	68 e9 58 10 f0       	push   $0xf01058e9
f0102bc1:	e8 22 04 00 00       	call   f0102fe8 <cprintf>
	return 0;
f0102bc6:	83 c4 10             	add    $0x10,%esp
f0102bc9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bce:	eb 0c                	jmp    f0102bdc <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102bd0:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102bd5:	eb 05                	jmp    f0102bdc <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102bd7:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102bdc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102bdf:	c9                   	leave  
f0102be0:	c3                   	ret    

f0102be1 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102be1:	55                   	push   %ebp
f0102be2:	89 e5                	mov    %esp,%ebp
f0102be4:	57                   	push   %edi
f0102be5:	56                   	push   %esi
f0102be6:	53                   	push   %ebx
f0102be7:	83 ec 34             	sub    $0x34,%esp
f0102bea:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env* e;
	int error = env_alloc(&e,0);
f0102bed:	6a 00                	push   $0x0
f0102bef:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102bf2:	50                   	push   %eax
f0102bf3:	e8 80 fe ff ff       	call   f0102a78 <env_alloc>

	if(error<0)
f0102bf8:	83 c4 10             	add    $0x10,%esp
f0102bfb:	85 c0                	test   %eax,%eax
f0102bfd:	79 15                	jns    f0102c14 <env_create+0x33>
		panic("Environment allocation error: %e",error);
f0102bff:	50                   	push   %eax
f0102c00:	68 34 59 10 f0       	push   $0xf0105934
f0102c05:	68 96 01 00 00       	push   $0x196
f0102c0a:	68 de 58 10 f0       	push   $0xf01058de
f0102c0f:	e8 8c d4 ff ff       	call   f01000a0 <_panic>

	load_icode(e,binary);
f0102c14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c17:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// LAB 3: Your code here.
	struct Proghdr *ph, *eph;
	struct Elf *elf=(struct Elf*) binary;
        
	// is this a valid ELF?
        if (elf->e_magic != ELF_MAGIC)
f0102c1a:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102c20:	74 17                	je     f0102c39 <env_create+0x58>
                panic("Not a valid ELF!");
f0102c22:	83 ec 04             	sub    $0x4,%esp
f0102c25:	68 fe 58 10 f0       	push   $0xf01058fe
f0102c2a:	68 65 01 00 00       	push   $0x165
f0102c2f:	68 de 58 10 f0       	push   $0xf01058de
f0102c34:	e8 67 d4 ff ff       	call   f01000a0 <_panic>

        // load each program segment (ignores ph flags)
        ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f0102c39:	89 fb                	mov    %edi,%ebx
f0102c3b:	03 5f 1c             	add    0x1c(%edi),%ebx
        
	eph = ph + elf->e_phnum;
f0102c3e:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102c42:	c1 e6 05             	shl    $0x5,%esi
f0102c45:	01 de                	add    %ebx,%esi
	
	lcr3(PADDR(e->env_pgdir));
f0102c47:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c4a:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c4d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c52:	77 15                	ja     f0102c69 <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c54:	50                   	push   %eax
f0102c55:	68 a8 4d 10 f0       	push   $0xf0104da8
f0102c5a:	68 6c 01 00 00       	push   $0x16c
f0102c5f:	68 de 58 10 f0       	push   $0xf01058de
f0102c64:	e8 37 d4 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102c69:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c6e:	0f 22 d8             	mov    %eax,%cr3
f0102c71:	eb 41                	jmp    f0102cb4 <env_create+0xd3>

        for (; ph < eph; ph++)
	{	
		if(ph->p_type==ELF_PROG_LOAD)
f0102c73:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102c76:	75 39                	jne    f0102cb1 <env_create+0xd0>
		{
			region_alloc(e,(void*)ph->p_va,ph->p_memsz);	
f0102c78:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102c7b:	8b 53 08             	mov    0x8(%ebx),%edx
f0102c7e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c81:	e8 94 fc ff ff       	call   f010291a <region_alloc>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
f0102c86:	83 ec 04             	sub    $0x4,%esp
f0102c89:	ff 73 10             	pushl  0x10(%ebx)
f0102c8c:	89 f8                	mov    %edi,%eax
f0102c8e:	03 43 04             	add    0x4(%ebx),%eax
f0102c91:	50                   	push   %eax
f0102c92:	ff 73 08             	pushl  0x8(%ebx)
f0102c95:	e8 d5 17 00 00       	call   f010446f <memcpy>
			memset((void*)ph->p_va,0,ph->p_memsz-ph->p_filesz);				
f0102c9a:	83 c4 0c             	add    $0xc,%esp
f0102c9d:	8b 43 14             	mov    0x14(%ebx),%eax
f0102ca0:	2b 43 10             	sub    0x10(%ebx),%eax
f0102ca3:	50                   	push   %eax
f0102ca4:	6a 00                	push   $0x0
f0102ca6:	ff 73 08             	pushl  0x8(%ebx)
f0102ca9:	e8 0c 17 00 00       	call   f01043ba <memset>
f0102cae:	83 c4 10             	add    $0x10,%esp
        
	eph = ph + elf->e_phnum;
	
	lcr3(PADDR(e->env_pgdir));

        for (; ph < eph; ph++)
f0102cb1:	83 c3 20             	add    $0x20,%ebx
f0102cb4:	39 de                	cmp    %ebx,%esi
f0102cb6:	77 bb                	ja     f0102c73 <env_create+0x92>
			memcpy((void*)ph->p_va,binary+ph->p_offset,ph->p_filesz);
			memset((void*)ph->p_va,0,ph->p_memsz-ph->p_filesz);				
		}
	}
	
	lcr3(PADDR(kern_pgdir));
f0102cb8:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cbd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102cc2:	77 15                	ja     f0102cd9 <env_create+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cc4:	50                   	push   %eax
f0102cc5:	68 a8 4d 10 f0       	push   $0xf0104da8
f0102cca:	68 78 01 00 00       	push   $0x178
f0102ccf:	68 de 58 10 f0       	push   $0xf01058de
f0102cd4:	e8 c7 d3 ff ff       	call   f01000a0 <_panic>
f0102cd9:	05 00 00 00 10       	add    $0x10000000,%eax
f0102cde:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here

	region_alloc(e,(void*)(USTACKTOP-PGSIZE),PGSIZE);	
f0102ce1:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102ce6:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102ceb:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102cee:	89 f0                	mov    %esi,%eax
f0102cf0:	e8 25 fc ff ff       	call   f010291a <region_alloc>

	e->env_tf.tf_eip = elf->e_entry;
f0102cf5:	8b 47 18             	mov    0x18(%edi),%eax
f0102cf8:	89 46 30             	mov    %eax,0x30(%esi)

	e->env_tf.tf_esp = (uintptr_t)(USTACKTOP);
f0102cfb:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	if(error<0)
		panic("Environment allocation error: %e",error);

	load_icode(e,binary);
	
	e->env_type=type;
f0102d02:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d05:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102d08:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102d0b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d0e:	5b                   	pop    %ebx
f0102d0f:	5e                   	pop    %esi
f0102d10:	5f                   	pop    %edi
f0102d11:	5d                   	pop    %ebp
f0102d12:	c3                   	ret    

f0102d13 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102d13:	55                   	push   %ebp
f0102d14:	89 e5                	mov    %esp,%ebp
f0102d16:	57                   	push   %edi
f0102d17:	56                   	push   %esi
f0102d18:	53                   	push   %ebx
f0102d19:	83 ec 1c             	sub    $0x1c,%esp
f0102d1c:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102d1f:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0102d25:	39 fa                	cmp    %edi,%edx
f0102d27:	75 29                	jne    f0102d52 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102d29:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d2e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d33:	77 15                	ja     f0102d4a <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d35:	50                   	push   %eax
f0102d36:	68 a8 4d 10 f0       	push   $0xf0104da8
f0102d3b:	68 ab 01 00 00       	push   $0x1ab
f0102d40:	68 de 58 10 f0       	push   $0xf01058de
f0102d45:	e8 56 d3 ff ff       	call   f01000a0 <_panic>
f0102d4a:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d4f:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102d52:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102d55:	85 d2                	test   %edx,%edx
f0102d57:	74 05                	je     f0102d5e <env_free+0x4b>
f0102d59:	8b 42 48             	mov    0x48(%edx),%eax
f0102d5c:	eb 05                	jmp    f0102d63 <env_free+0x50>
f0102d5e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d63:	83 ec 04             	sub    $0x4,%esp
f0102d66:	51                   	push   %ecx
f0102d67:	50                   	push   %eax
f0102d68:	68 0f 59 10 f0       	push   $0xf010590f
f0102d6d:	e8 76 02 00 00       	call   f0102fe8 <cprintf>
f0102d72:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d75:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102d7c:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102d7f:	89 d0                	mov    %edx,%eax
f0102d81:	c1 e0 02             	shl    $0x2,%eax
f0102d84:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102d87:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d8a:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102d8d:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102d93:	0f 84 a8 00 00 00    	je     f0102e41 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102d99:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d9f:	89 f0                	mov    %esi,%eax
f0102da1:	c1 e8 0c             	shr    $0xc,%eax
f0102da4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102da7:	39 05 44 2c 17 f0    	cmp    %eax,0xf0172c44
f0102dad:	77 15                	ja     f0102dc4 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102daf:	56                   	push   %esi
f0102db0:	68 84 4d 10 f0       	push   $0xf0104d84
f0102db5:	68 ba 01 00 00       	push   $0x1ba
f0102dba:	68 de 58 10 f0       	push   $0xf01058de
f0102dbf:	e8 dc d2 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102dc4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102dc7:	c1 e0 16             	shl    $0x16,%eax
f0102dca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102dcd:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102dd2:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102dd9:	01 
f0102dda:	74 17                	je     f0102df3 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102ddc:	83 ec 08             	sub    $0x8,%esp
f0102ddf:	89 d8                	mov    %ebx,%eax
f0102de1:	c1 e0 0c             	shl    $0xc,%eax
f0102de4:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102de7:	50                   	push   %eax
f0102de8:	ff 77 5c             	pushl  0x5c(%edi)
f0102deb:	e8 ae e1 ff ff       	call   f0100f9e <page_remove>
f0102df0:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102df3:	83 c3 01             	add    $0x1,%ebx
f0102df6:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102dfc:	75 d4                	jne    f0102dd2 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102dfe:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102e01:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e04:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e0b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e0e:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102e14:	72 14                	jb     f0102e2a <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102e16:	83 ec 04             	sub    $0x4,%esp
f0102e19:	68 b4 4e 10 f0       	push   $0xf0104eb4
f0102e1e:	6a 4f                	push   $0x4f
f0102e20:	68 d3 55 10 f0       	push   $0xf01055d3
f0102e25:	e8 76 d2 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102e2a:	83 ec 0c             	sub    $0xc,%esp
f0102e2d:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0102e32:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102e35:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102e38:	50                   	push   %eax
f0102e39:	e8 ff df ff ff       	call   f0100e3d <page_decref>
f0102e3e:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102e41:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102e45:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102e48:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102e4d:	0f 85 29 ff ff ff    	jne    f0102d7c <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102e53:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e56:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e5b:	77 15                	ja     f0102e72 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e5d:	50                   	push   %eax
f0102e5e:	68 a8 4d 10 f0       	push   $0xf0104da8
f0102e63:	68 c8 01 00 00       	push   $0x1c8
f0102e68:	68 de 58 10 f0       	push   $0xf01058de
f0102e6d:	e8 2e d2 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102e72:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e79:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e7e:	c1 e8 0c             	shr    $0xc,%eax
f0102e81:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102e87:	72 14                	jb     f0102e9d <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102e89:	83 ec 04             	sub    $0x4,%esp
f0102e8c:	68 b4 4e 10 f0       	push   $0xf0104eb4
f0102e91:	6a 4f                	push   $0x4f
f0102e93:	68 d3 55 10 f0       	push   $0xf01055d3
f0102e98:	e8 03 d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102e9d:	83 ec 0c             	sub    $0xc,%esp
f0102ea0:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f0102ea6:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102ea9:	50                   	push   %eax
f0102eaa:	e8 8e df ff ff       	call   f0100e3d <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102eaf:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102eb6:	a1 8c 1f 17 f0       	mov    0xf0171f8c,%eax
f0102ebb:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102ebe:	89 3d 8c 1f 17 f0    	mov    %edi,0xf0171f8c
}
f0102ec4:	83 c4 10             	add    $0x10,%esp
f0102ec7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102eca:	5b                   	pop    %ebx
f0102ecb:	5e                   	pop    %esi
f0102ecc:	5f                   	pop    %edi
f0102ecd:	5d                   	pop    %ebp
f0102ece:	c3                   	ret    

f0102ecf <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102ecf:	55                   	push   %ebp
f0102ed0:	89 e5                	mov    %esp,%ebp
f0102ed2:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102ed5:	ff 75 08             	pushl  0x8(%ebp)
f0102ed8:	e8 36 fe ff ff       	call   f0102d13 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102edd:	c7 04 24 58 59 10 f0 	movl   $0xf0105958,(%esp)
f0102ee4:	e8 ff 00 00 00       	call   f0102fe8 <cprintf>
f0102ee9:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102eec:	83 ec 0c             	sub    $0xc,%esp
f0102eef:	6a 00                	push   $0x0
f0102ef1:	e8 fb d8 ff ff       	call   f01007f1 <monitor>
f0102ef6:	83 c4 10             	add    $0x10,%esp
f0102ef9:	eb f1                	jmp    f0102eec <env_destroy+0x1d>

f0102efb <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102efb:	55                   	push   %ebp
f0102efc:	89 e5                	mov    %esp,%ebp
f0102efe:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102f01:	8b 65 08             	mov    0x8(%ebp),%esp
f0102f04:	61                   	popa   
f0102f05:	07                   	pop    %es
f0102f06:	1f                   	pop    %ds
f0102f07:	83 c4 08             	add    $0x8,%esp
f0102f0a:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102f0b:	68 25 59 10 f0       	push   $0xf0105925
f0102f10:	68 f1 01 00 00       	push   $0x1f1
f0102f15:	68 de 58 10 f0       	push   $0xf01058de
f0102f1a:	e8 81 d1 ff ff       	call   f01000a0 <_panic>

f0102f1f <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102f1f:	55                   	push   %ebp
f0102f20:	89 e5                	mov    %esp,%ebp
f0102f22:	83 ec 08             	sub    $0x8,%esp
f0102f25:	8b 45 08             	mov    0x8(%ebp),%eax
	//	   5. Use lcr3() to switch to its address space.
	// Step 2: Use env_pop_tf() to restore the environment's
	//	   registers and drop into user mode in the
	//	   environment.

	if(curenv)
f0102f28:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0102f2e:	85 d2                	test   %edx,%edx
f0102f30:	74 0d                	je     f0102f3f <env_run+0x20>
	{		
		if(curenv->env_status==ENV_RUNNING)
f0102f32:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102f36:	75 07                	jne    f0102f3f <env_run+0x20>
			curenv->env_status=ENV_RUNNABLE;
f0102f38:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}	
		
	lcr3(PADDR(e->env_pgdir));
f0102f3f:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f42:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102f48:	77 15                	ja     f0102f5f <env_run+0x40>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f4a:	52                   	push   %edx
f0102f4b:	68 a8 4d 10 f0       	push   $0xf0104da8
f0102f50:	68 0f 02 00 00       	push   $0x20f
f0102f55:	68 de 58 10 f0       	push   $0xf01058de
f0102f5a:	e8 41 d1 ff ff       	call   f01000a0 <_panic>
f0102f5f:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102f65:	0f 22 da             	mov    %edx,%cr3
	
	curenv=e;
f0102f68:	a3 84 1f 17 f0       	mov    %eax,0xf0171f84
	
	e->env_status=ENV_RUNNING;
f0102f6d:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0102f74:	83 40 58 01          	addl   $0x1,0x58(%eax)
		
	env_pop_tf(&e->env_tf);
f0102f78:	83 ec 0c             	sub    $0xc,%esp
f0102f7b:	50                   	push   %eax
f0102f7c:	e8 7a ff ff ff       	call   f0102efb <env_pop_tf>

f0102f81 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f81:	55                   	push   %ebp
f0102f82:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f84:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f89:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f8c:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f8d:	ba 71 00 00 00       	mov    $0x71,%edx
f0102f92:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f93:	0f b6 c0             	movzbl %al,%eax
}
f0102f96:	5d                   	pop    %ebp
f0102f97:	c3                   	ret    

f0102f98 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f98:	55                   	push   %ebp
f0102f99:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f9b:	ba 70 00 00 00       	mov    $0x70,%edx
f0102fa0:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fa3:	ee                   	out    %al,(%dx)
f0102fa4:	ba 71 00 00 00       	mov    $0x71,%edx
f0102fa9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fac:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102fad:	5d                   	pop    %ebp
f0102fae:	c3                   	ret    

f0102faf <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102faf:	55                   	push   %ebp
f0102fb0:	89 e5                	mov    %esp,%ebp
f0102fb2:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102fb5:	ff 75 08             	pushl  0x8(%ebp)
f0102fb8:	e8 58 d6 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102fbd:	83 c4 10             	add    $0x10,%esp
f0102fc0:	c9                   	leave  
f0102fc1:	c3                   	ret    

f0102fc2 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102fc2:	55                   	push   %ebp
f0102fc3:	89 e5                	mov    %esp,%ebp
f0102fc5:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102fc8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102fcf:	ff 75 0c             	pushl  0xc(%ebp)
f0102fd2:	ff 75 08             	pushl  0x8(%ebp)
f0102fd5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102fd8:	50                   	push   %eax
f0102fd9:	68 af 2f 10 f0       	push   $0xf0102faf
f0102fde:	e8 6b 0d 00 00       	call   f0103d4e <vprintfmt>
	return cnt;
}
f0102fe3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fe6:	c9                   	leave  
f0102fe7:	c3                   	ret    

f0102fe8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102fe8:	55                   	push   %ebp
f0102fe9:	89 e5                	mov    %esp,%ebp
f0102feb:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102fee:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102ff1:	50                   	push   %eax
f0102ff2:	ff 75 08             	pushl  0x8(%ebp)
f0102ff5:	e8 c8 ff ff ff       	call   f0102fc2 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102ffa:	c9                   	leave  
f0102ffb:	c3                   	ret    

f0102ffc <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102ffc:	55                   	push   %ebp
f0102ffd:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102fff:	b8 c0 27 17 f0       	mov    $0xf01727c0,%eax
f0103004:	c7 05 c4 27 17 f0 00 	movl   $0xf0000000,0xf01727c4
f010300b:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010300e:	66 c7 05 c8 27 17 f0 	movw   $0x10,0xf01727c8
f0103015:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103017:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f010301e:	67 00 
f0103020:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0103026:	89 c2                	mov    %eax,%edx
f0103028:	c1 ea 10             	shr    $0x10,%edx
f010302b:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0103031:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0103038:	c1 e8 18             	shr    $0x18,%eax
f010303b:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103040:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103047:	b8 28 00 00 00       	mov    $0x28,%eax
f010304c:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f010304f:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103054:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103057:	5d                   	pop    %ebp
f0103058:	c3                   	ret    

f0103059 <trap_init>:
}


void
trap_init(void)
{
f0103059:	55                   	push   %ebp
f010305a:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	
	extern void TH_DIVIDE(); 	SETGATE(idt[T_DIVIDE], 0, GD_KT, TH_DIVIDE, 0); 
f010305c:	b8 2e 37 10 f0       	mov    $0xf010372e,%eax
f0103061:	66 a3 a0 1f 17 f0    	mov    %ax,0xf0171fa0
f0103067:	66 c7 05 a2 1f 17 f0 	movw   $0x8,0xf0171fa2
f010306e:	08 00 
f0103070:	c6 05 a4 1f 17 f0 00 	movb   $0x0,0xf0171fa4
f0103077:	c6 05 a5 1f 17 f0 8e 	movb   $0x8e,0xf0171fa5
f010307e:	c1 e8 10             	shr    $0x10,%eax
f0103081:	66 a3 a6 1f 17 f0    	mov    %ax,0xf0171fa6
	extern void TH_DEBUG(); 	SETGATE(idt[T_DEBUG], 0, GD_KT, TH_DEBUG, 0); 
f0103087:	b8 34 37 10 f0       	mov    $0xf0103734,%eax
f010308c:	66 a3 a8 1f 17 f0    	mov    %ax,0xf0171fa8
f0103092:	66 c7 05 aa 1f 17 f0 	movw   $0x8,0xf0171faa
f0103099:	08 00 
f010309b:	c6 05 ac 1f 17 f0 00 	movb   $0x0,0xf0171fac
f01030a2:	c6 05 ad 1f 17 f0 8e 	movb   $0x8e,0xf0171fad
f01030a9:	c1 e8 10             	shr    $0x10,%eax
f01030ac:	66 a3 ae 1f 17 f0    	mov    %ax,0xf0171fae
	extern void TH_NMI(); 		SETGATE(idt[T_NMI], 0, GD_KT, TH_NMI, 0); 
f01030b2:	b8 3a 37 10 f0       	mov    $0xf010373a,%eax
f01030b7:	66 a3 b0 1f 17 f0    	mov    %ax,0xf0171fb0
f01030bd:	66 c7 05 b2 1f 17 f0 	movw   $0x8,0xf0171fb2
f01030c4:	08 00 
f01030c6:	c6 05 b4 1f 17 f0 00 	movb   $0x0,0xf0171fb4
f01030cd:	c6 05 b5 1f 17 f0 8e 	movb   $0x8e,0xf0171fb5
f01030d4:	c1 e8 10             	shr    $0x10,%eax
f01030d7:	66 a3 b6 1f 17 f0    	mov    %ax,0xf0171fb6
	extern void TH_BRKPT(); 	SETGATE(idt[T_BRKPT], 0, GD_KT, TH_BRKPT, 3); 
f01030dd:	b8 40 37 10 f0       	mov    $0xf0103740,%eax
f01030e2:	66 a3 b8 1f 17 f0    	mov    %ax,0xf0171fb8
f01030e8:	66 c7 05 ba 1f 17 f0 	movw   $0x8,0xf0171fba
f01030ef:	08 00 
f01030f1:	c6 05 bc 1f 17 f0 00 	movb   $0x0,0xf0171fbc
f01030f8:	c6 05 bd 1f 17 f0 ee 	movb   $0xee,0xf0171fbd
f01030ff:	c1 e8 10             	shr    $0x10,%eax
f0103102:	66 a3 be 1f 17 f0    	mov    %ax,0xf0171fbe
	extern void TH_OFLOW(); 	SETGATE(idt[T_OFLOW], 0, GD_KT, TH_OFLOW, 0); 
f0103108:	b8 46 37 10 f0       	mov    $0xf0103746,%eax
f010310d:	66 a3 c0 1f 17 f0    	mov    %ax,0xf0171fc0
f0103113:	66 c7 05 c2 1f 17 f0 	movw   $0x8,0xf0171fc2
f010311a:	08 00 
f010311c:	c6 05 c4 1f 17 f0 00 	movb   $0x0,0xf0171fc4
f0103123:	c6 05 c5 1f 17 f0 8e 	movb   $0x8e,0xf0171fc5
f010312a:	c1 e8 10             	shr    $0x10,%eax
f010312d:	66 a3 c6 1f 17 f0    	mov    %ax,0xf0171fc6
	extern void TH_BOUND(); 	SETGATE(idt[T_BOUND], 0, GD_KT, TH_BOUND, 0); 
f0103133:	b8 4c 37 10 f0       	mov    $0xf010374c,%eax
f0103138:	66 a3 c8 1f 17 f0    	mov    %ax,0xf0171fc8
f010313e:	66 c7 05 ca 1f 17 f0 	movw   $0x8,0xf0171fca
f0103145:	08 00 
f0103147:	c6 05 cc 1f 17 f0 00 	movb   $0x0,0xf0171fcc
f010314e:	c6 05 cd 1f 17 f0 8e 	movb   $0x8e,0xf0171fcd
f0103155:	c1 e8 10             	shr    $0x10,%eax
f0103158:	66 a3 ce 1f 17 f0    	mov    %ax,0xf0171fce
	extern void TH_ILLOP(); 	SETGATE(idt[T_ILLOP], 0, GD_KT, TH_ILLOP, 0); 
f010315e:	b8 52 37 10 f0       	mov    $0xf0103752,%eax
f0103163:	66 a3 d0 1f 17 f0    	mov    %ax,0xf0171fd0
f0103169:	66 c7 05 d2 1f 17 f0 	movw   $0x8,0xf0171fd2
f0103170:	08 00 
f0103172:	c6 05 d4 1f 17 f0 00 	movb   $0x0,0xf0171fd4
f0103179:	c6 05 d5 1f 17 f0 8e 	movb   $0x8e,0xf0171fd5
f0103180:	c1 e8 10             	shr    $0x10,%eax
f0103183:	66 a3 d6 1f 17 f0    	mov    %ax,0xf0171fd6
	extern void TH_DEVICE(); 	SETGATE(idt[T_DEVICE], 0, GD_KT, TH_DEVICE, 0); 
f0103189:	b8 58 37 10 f0       	mov    $0xf0103758,%eax
f010318e:	66 a3 d8 1f 17 f0    	mov    %ax,0xf0171fd8
f0103194:	66 c7 05 da 1f 17 f0 	movw   $0x8,0xf0171fda
f010319b:	08 00 
f010319d:	c6 05 dc 1f 17 f0 00 	movb   $0x0,0xf0171fdc
f01031a4:	c6 05 dd 1f 17 f0 8e 	movb   $0x8e,0xf0171fdd
f01031ab:	c1 e8 10             	shr    $0x10,%eax
f01031ae:	66 a3 de 1f 17 f0    	mov    %ax,0xf0171fde
	extern void TH_DBLFLT(); 	SETGATE(idt[T_DBLFLT], 0, GD_KT, TH_DBLFLT, 0); 
f01031b4:	b8 5e 37 10 f0       	mov    $0xf010375e,%eax
f01031b9:	66 a3 e0 1f 17 f0    	mov    %ax,0xf0171fe0
f01031bf:	66 c7 05 e2 1f 17 f0 	movw   $0x8,0xf0171fe2
f01031c6:	08 00 
f01031c8:	c6 05 e4 1f 17 f0 00 	movb   $0x0,0xf0171fe4
f01031cf:	c6 05 e5 1f 17 f0 8e 	movb   $0x8e,0xf0171fe5
f01031d6:	c1 e8 10             	shr    $0x10,%eax
f01031d9:	66 a3 e6 1f 17 f0    	mov    %ax,0xf0171fe6
	extern void TH_TSS(); 		SETGATE(idt[T_TSS], 0, GD_KT, TH_TSS, 0); 
f01031df:	b8 62 37 10 f0       	mov    $0xf0103762,%eax
f01031e4:	66 a3 f0 1f 17 f0    	mov    %ax,0xf0171ff0
f01031ea:	66 c7 05 f2 1f 17 f0 	movw   $0x8,0xf0171ff2
f01031f1:	08 00 
f01031f3:	c6 05 f4 1f 17 f0 00 	movb   $0x0,0xf0171ff4
f01031fa:	c6 05 f5 1f 17 f0 8e 	movb   $0x8e,0xf0171ff5
f0103201:	c1 e8 10             	shr    $0x10,%eax
f0103204:	66 a3 f6 1f 17 f0    	mov    %ax,0xf0171ff6
	extern void TH_SEGNP(); 	SETGATE(idt[T_SEGNP], 0, GD_KT, TH_SEGNP, 0); 
f010320a:	b8 66 37 10 f0       	mov    $0xf0103766,%eax
f010320f:	66 a3 f8 1f 17 f0    	mov    %ax,0xf0171ff8
f0103215:	66 c7 05 fa 1f 17 f0 	movw   $0x8,0xf0171ffa
f010321c:	08 00 
f010321e:	c6 05 fc 1f 17 f0 00 	movb   $0x0,0xf0171ffc
f0103225:	c6 05 fd 1f 17 f0 8e 	movb   $0x8e,0xf0171ffd
f010322c:	c1 e8 10             	shr    $0x10,%eax
f010322f:	66 a3 fe 1f 17 f0    	mov    %ax,0xf0171ffe
	extern void TH_STACK(); 	SETGATE(idt[T_STACK], 0, GD_KT, TH_STACK, 0); 
f0103235:	b8 6a 37 10 f0       	mov    $0xf010376a,%eax
f010323a:	66 a3 00 20 17 f0    	mov    %ax,0xf0172000
f0103240:	66 c7 05 02 20 17 f0 	movw   $0x8,0xf0172002
f0103247:	08 00 
f0103249:	c6 05 04 20 17 f0 00 	movb   $0x0,0xf0172004
f0103250:	c6 05 05 20 17 f0 8e 	movb   $0x8e,0xf0172005
f0103257:	c1 e8 10             	shr    $0x10,%eax
f010325a:	66 a3 06 20 17 f0    	mov    %ax,0xf0172006
	extern void TH_GPFLT(); 	SETGATE(idt[T_GPFLT], 0, GD_KT, TH_GPFLT, 0); 
f0103260:	b8 6e 37 10 f0       	mov    $0xf010376e,%eax
f0103265:	66 a3 08 20 17 f0    	mov    %ax,0xf0172008
f010326b:	66 c7 05 0a 20 17 f0 	movw   $0x8,0xf017200a
f0103272:	08 00 
f0103274:	c6 05 0c 20 17 f0 00 	movb   $0x0,0xf017200c
f010327b:	c6 05 0d 20 17 f0 8e 	movb   $0x8e,0xf017200d
f0103282:	c1 e8 10             	shr    $0x10,%eax
f0103285:	66 a3 0e 20 17 f0    	mov    %ax,0xf017200e
	extern void TH_PGFLT(); 	SETGATE(idt[T_PGFLT], 0, GD_KT, TH_PGFLT, 0); 
f010328b:	b8 72 37 10 f0       	mov    $0xf0103772,%eax
f0103290:	66 a3 10 20 17 f0    	mov    %ax,0xf0172010
f0103296:	66 c7 05 12 20 17 f0 	movw   $0x8,0xf0172012
f010329d:	08 00 
f010329f:	c6 05 14 20 17 f0 00 	movb   $0x0,0xf0172014
f01032a6:	c6 05 15 20 17 f0 8e 	movb   $0x8e,0xf0172015
f01032ad:	c1 e8 10             	shr    $0x10,%eax
f01032b0:	66 a3 16 20 17 f0    	mov    %ax,0xf0172016
	extern void TH_FPERR(); 	SETGATE(idt[T_FPERR], 0, GD_KT, TH_FPERR, 0); 
f01032b6:	b8 76 37 10 f0       	mov    $0xf0103776,%eax
f01032bb:	66 a3 20 20 17 f0    	mov    %ax,0xf0172020
f01032c1:	66 c7 05 22 20 17 f0 	movw   $0x8,0xf0172022
f01032c8:	08 00 
f01032ca:	c6 05 24 20 17 f0 00 	movb   $0x0,0xf0172024
f01032d1:	c6 05 25 20 17 f0 8e 	movb   $0x8e,0xf0172025
f01032d8:	c1 e8 10             	shr    $0x10,%eax
f01032db:	66 a3 26 20 17 f0    	mov    %ax,0xf0172026
	extern void TH_ALIGN(); 	SETGATE(idt[T_ALIGN], 0, GD_KT, TH_ALIGN, 0); 
f01032e1:	b8 7c 37 10 f0       	mov    $0xf010377c,%eax
f01032e6:	66 a3 28 20 17 f0    	mov    %ax,0xf0172028
f01032ec:	66 c7 05 2a 20 17 f0 	movw   $0x8,0xf017202a
f01032f3:	08 00 
f01032f5:	c6 05 2c 20 17 f0 00 	movb   $0x0,0xf017202c
f01032fc:	c6 05 2d 20 17 f0 8e 	movb   $0x8e,0xf017202d
f0103303:	c1 e8 10             	shr    $0x10,%eax
f0103306:	66 a3 2e 20 17 f0    	mov    %ax,0xf017202e
	extern void TH_MCHK(); 		SETGATE(idt[T_MCHK], 0, GD_KT, TH_MCHK, 0); 
f010330c:	b8 80 37 10 f0       	mov    $0xf0103780,%eax
f0103311:	66 a3 30 20 17 f0    	mov    %ax,0xf0172030
f0103317:	66 c7 05 32 20 17 f0 	movw   $0x8,0xf0172032
f010331e:	08 00 
f0103320:	c6 05 34 20 17 f0 00 	movb   $0x0,0xf0172034
f0103327:	c6 05 35 20 17 f0 8e 	movb   $0x8e,0xf0172035
f010332e:	c1 e8 10             	shr    $0x10,%eax
f0103331:	66 a3 36 20 17 f0    	mov    %ax,0xf0172036
	extern void TH_SIMDERR(); 	SETGATE(idt[T_SIMDERR], 0, GD_KT, TH_SIMDERR, 0); 
f0103337:	b8 86 37 10 f0       	mov    $0xf0103786,%eax
f010333c:	66 a3 38 20 17 f0    	mov    %ax,0xf0172038
f0103342:	66 c7 05 3a 20 17 f0 	movw   $0x8,0xf017203a
f0103349:	08 00 
f010334b:	c6 05 3c 20 17 f0 00 	movb   $0x0,0xf017203c
f0103352:	c6 05 3d 20 17 f0 8e 	movb   $0x8e,0xf017203d
f0103359:	c1 e8 10             	shr    $0x10,%eax
f010335c:	66 a3 3e 20 17 f0    	mov    %ax,0xf017203e
	extern void TH_SYSCALL(); 	SETGATE(idt[T_SYSCALL], 1, GD_KT, TH_SYSCALL, 3); 
f0103362:	b8 8c 37 10 f0       	mov    $0xf010378c,%eax
f0103367:	66 a3 20 21 17 f0    	mov    %ax,0xf0172120
f010336d:	66 c7 05 22 21 17 f0 	movw   $0x8,0xf0172122
f0103374:	08 00 
f0103376:	c6 05 24 21 17 f0 00 	movb   $0x0,0xf0172124
f010337d:	c6 05 25 21 17 f0 ef 	movb   $0xef,0xf0172125
f0103384:	c1 e8 10             	shr    $0x10,%eax
f0103387:	66 a3 26 21 17 f0    	mov    %ax,0xf0172126

	// Per-CPU setup 
	trap_init_percpu();
f010338d:	e8 6a fc ff ff       	call   f0102ffc <trap_init_percpu>
}
f0103392:	5d                   	pop    %ebp
f0103393:	c3                   	ret    

f0103394 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103394:	55                   	push   %ebp
f0103395:	89 e5                	mov    %esp,%ebp
f0103397:	53                   	push   %ebx
f0103398:	83 ec 0c             	sub    $0xc,%esp
f010339b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010339e:	ff 33                	pushl  (%ebx)
f01033a0:	68 8e 59 10 f0       	push   $0xf010598e
f01033a5:	e8 3e fc ff ff       	call   f0102fe8 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01033aa:	83 c4 08             	add    $0x8,%esp
f01033ad:	ff 73 04             	pushl  0x4(%ebx)
f01033b0:	68 9d 59 10 f0       	push   $0xf010599d
f01033b5:	e8 2e fc ff ff       	call   f0102fe8 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01033ba:	83 c4 08             	add    $0x8,%esp
f01033bd:	ff 73 08             	pushl  0x8(%ebx)
f01033c0:	68 ac 59 10 f0       	push   $0xf01059ac
f01033c5:	e8 1e fc ff ff       	call   f0102fe8 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01033ca:	83 c4 08             	add    $0x8,%esp
f01033cd:	ff 73 0c             	pushl  0xc(%ebx)
f01033d0:	68 bb 59 10 f0       	push   $0xf01059bb
f01033d5:	e8 0e fc ff ff       	call   f0102fe8 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01033da:	83 c4 08             	add    $0x8,%esp
f01033dd:	ff 73 10             	pushl  0x10(%ebx)
f01033e0:	68 ca 59 10 f0       	push   $0xf01059ca
f01033e5:	e8 fe fb ff ff       	call   f0102fe8 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01033ea:	83 c4 08             	add    $0x8,%esp
f01033ed:	ff 73 14             	pushl  0x14(%ebx)
f01033f0:	68 d9 59 10 f0       	push   $0xf01059d9
f01033f5:	e8 ee fb ff ff       	call   f0102fe8 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01033fa:	83 c4 08             	add    $0x8,%esp
f01033fd:	ff 73 18             	pushl  0x18(%ebx)
f0103400:	68 e8 59 10 f0       	push   $0xf01059e8
f0103405:	e8 de fb ff ff       	call   f0102fe8 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010340a:	83 c4 08             	add    $0x8,%esp
f010340d:	ff 73 1c             	pushl  0x1c(%ebx)
f0103410:	68 f7 59 10 f0       	push   $0xf01059f7
f0103415:	e8 ce fb ff ff       	call   f0102fe8 <cprintf>
}
f010341a:	83 c4 10             	add    $0x10,%esp
f010341d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103420:	c9                   	leave  
f0103421:	c3                   	ret    

f0103422 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103422:	55                   	push   %ebp
f0103423:	89 e5                	mov    %esp,%ebp
f0103425:	56                   	push   %esi
f0103426:	53                   	push   %ebx
f0103427:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f010342a:	83 ec 08             	sub    $0x8,%esp
f010342d:	53                   	push   %ebx
f010342e:	68 3c 5b 10 f0       	push   $0xf0105b3c
f0103433:	e8 b0 fb ff ff       	call   f0102fe8 <cprintf>
	print_regs(&tf->tf_regs);
f0103438:	89 1c 24             	mov    %ebx,(%esp)
f010343b:	e8 54 ff ff ff       	call   f0103394 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103440:	83 c4 08             	add    $0x8,%esp
f0103443:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103447:	50                   	push   %eax
f0103448:	68 48 5a 10 f0       	push   $0xf0105a48
f010344d:	e8 96 fb ff ff       	call   f0102fe8 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103452:	83 c4 08             	add    $0x8,%esp
f0103455:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103459:	50                   	push   %eax
f010345a:	68 5b 5a 10 f0       	push   $0xf0105a5b
f010345f:	e8 84 fb ff ff       	call   f0102fe8 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103464:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103467:	83 c4 10             	add    $0x10,%esp
f010346a:	83 f8 13             	cmp    $0x13,%eax
f010346d:	77 09                	ja     f0103478 <print_trapframe+0x56>
		return excnames[trapno];
f010346f:	8b 14 85 20 5d 10 f0 	mov    -0xfefa2e0(,%eax,4),%edx
f0103476:	eb 10                	jmp    f0103488 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0103478:	83 f8 30             	cmp    $0x30,%eax
f010347b:	b9 12 5a 10 f0       	mov    $0xf0105a12,%ecx
f0103480:	ba 06 5a 10 f0       	mov    $0xf0105a06,%edx
f0103485:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103488:	83 ec 04             	sub    $0x4,%esp
f010348b:	52                   	push   %edx
f010348c:	50                   	push   %eax
f010348d:	68 6e 5a 10 f0       	push   $0xf0105a6e
f0103492:	e8 51 fb ff ff       	call   f0102fe8 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103497:	83 c4 10             	add    $0x10,%esp
f010349a:	3b 1d a0 27 17 f0    	cmp    0xf01727a0,%ebx
f01034a0:	75 1a                	jne    f01034bc <print_trapframe+0x9a>
f01034a2:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01034a6:	75 14                	jne    f01034bc <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01034a8:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01034ab:	83 ec 08             	sub    $0x8,%esp
f01034ae:	50                   	push   %eax
f01034af:	68 80 5a 10 f0       	push   $0xf0105a80
f01034b4:	e8 2f fb ff ff       	call   f0102fe8 <cprintf>
f01034b9:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01034bc:	83 ec 08             	sub    $0x8,%esp
f01034bf:	ff 73 2c             	pushl  0x2c(%ebx)
f01034c2:	68 8f 5a 10 f0       	push   $0xf0105a8f
f01034c7:	e8 1c fb ff ff       	call   f0102fe8 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01034cc:	83 c4 10             	add    $0x10,%esp
f01034cf:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01034d3:	75 49                	jne    f010351e <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f01034d5:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01034d8:	89 c2                	mov    %eax,%edx
f01034da:	83 e2 01             	and    $0x1,%edx
f01034dd:	ba 2c 5a 10 f0       	mov    $0xf0105a2c,%edx
f01034e2:	b9 21 5a 10 f0       	mov    $0xf0105a21,%ecx
f01034e7:	0f 44 ca             	cmove  %edx,%ecx
f01034ea:	89 c2                	mov    %eax,%edx
f01034ec:	83 e2 02             	and    $0x2,%edx
f01034ef:	ba 3e 5a 10 f0       	mov    $0xf0105a3e,%edx
f01034f4:	be 38 5a 10 f0       	mov    $0xf0105a38,%esi
f01034f9:	0f 45 d6             	cmovne %esi,%edx
f01034fc:	83 e0 04             	and    $0x4,%eax
f01034ff:	be 67 5b 10 f0       	mov    $0xf0105b67,%esi
f0103504:	b8 43 5a 10 f0       	mov    $0xf0105a43,%eax
f0103509:	0f 44 c6             	cmove  %esi,%eax
f010350c:	51                   	push   %ecx
f010350d:	52                   	push   %edx
f010350e:	50                   	push   %eax
f010350f:	68 9d 5a 10 f0       	push   $0xf0105a9d
f0103514:	e8 cf fa ff ff       	call   f0102fe8 <cprintf>
f0103519:	83 c4 10             	add    $0x10,%esp
f010351c:	eb 10                	jmp    f010352e <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010351e:	83 ec 0c             	sub    $0xc,%esp
f0103521:	68 94 58 10 f0       	push   $0xf0105894
f0103526:	e8 bd fa ff ff       	call   f0102fe8 <cprintf>
f010352b:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010352e:	83 ec 08             	sub    $0x8,%esp
f0103531:	ff 73 30             	pushl  0x30(%ebx)
f0103534:	68 ac 5a 10 f0       	push   $0xf0105aac
f0103539:	e8 aa fa ff ff       	call   f0102fe8 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010353e:	83 c4 08             	add    $0x8,%esp
f0103541:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103545:	50                   	push   %eax
f0103546:	68 bb 5a 10 f0       	push   $0xf0105abb
f010354b:	e8 98 fa ff ff       	call   f0102fe8 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103550:	83 c4 08             	add    $0x8,%esp
f0103553:	ff 73 38             	pushl  0x38(%ebx)
f0103556:	68 ce 5a 10 f0       	push   $0xf0105ace
f010355b:	e8 88 fa ff ff       	call   f0102fe8 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103560:	83 c4 10             	add    $0x10,%esp
f0103563:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103567:	74 25                	je     f010358e <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103569:	83 ec 08             	sub    $0x8,%esp
f010356c:	ff 73 3c             	pushl  0x3c(%ebx)
f010356f:	68 dd 5a 10 f0       	push   $0xf0105add
f0103574:	e8 6f fa ff ff       	call   f0102fe8 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103579:	83 c4 08             	add    $0x8,%esp
f010357c:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103580:	50                   	push   %eax
f0103581:	68 ec 5a 10 f0       	push   $0xf0105aec
f0103586:	e8 5d fa ff ff       	call   f0102fe8 <cprintf>
f010358b:	83 c4 10             	add    $0x10,%esp
	}
}
f010358e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103591:	5b                   	pop    %ebx
f0103592:	5e                   	pop    %esi
f0103593:	5d                   	pop    %ebp
f0103594:	c3                   	ret    

f0103595 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103595:	55                   	push   %ebp
f0103596:	89 e5                	mov    %esp,%ebp
f0103598:	53                   	push   %ebx
f0103599:	83 ec 04             	sub    $0x4,%esp
f010359c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010359f:	0f 20 d0             	mov    %cr2,%eax
	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	if ((tf->tf_cs & 3) == 0)
f01035a2:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01035a6:	75 17                	jne    f01035bf <page_fault_handler+0x2a>
		panic("FAULTY PAGE!!!");
f01035a8:	83 ec 04             	sub    $0x4,%esp
f01035ab:	68 ff 5a 10 f0       	push   $0xf0105aff
f01035b0:	68 f0 00 00 00       	push   $0xf0
f01035b5:	68 0e 5b 10 f0       	push   $0xf0105b0e
f01035ba:	e8 e1 ca ff ff       	call   f01000a0 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01035bf:	ff 73 30             	pushl  0x30(%ebx)
f01035c2:	50                   	push   %eax
f01035c3:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f01035c8:	ff 70 48             	pushl  0x48(%eax)
f01035cb:	68 b4 5c 10 f0       	push   $0xf0105cb4
f01035d0:	e8 13 fa ff ff       	call   f0102fe8 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01035d5:	89 1c 24             	mov    %ebx,(%esp)
f01035d8:	e8 45 fe ff ff       	call   f0103422 <print_trapframe>
	env_destroy(curenv);
f01035dd:	83 c4 04             	add    $0x4,%esp
f01035e0:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f01035e6:	e8 e4 f8 ff ff       	call   f0102ecf <env_destroy>
}
f01035eb:	83 c4 10             	add    $0x10,%esp
f01035ee:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035f1:	c9                   	leave  
f01035f2:	c3                   	ret    

f01035f3 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01035f3:	55                   	push   %ebp
f01035f4:	89 e5                	mov    %esp,%ebp
f01035f6:	57                   	push   %edi
f01035f7:	56                   	push   %esi
f01035f8:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01035fb:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01035fc:	9c                   	pushf  
f01035fd:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01035fe:	f6 c4 02             	test   $0x2,%ah
f0103601:	74 19                	je     f010361c <trap+0x29>
f0103603:	68 1a 5b 10 f0       	push   $0xf0105b1a
f0103608:	68 ed 55 10 f0       	push   $0xf01055ed
f010360d:	68 c8 00 00 00       	push   $0xc8
f0103612:	68 0e 5b 10 f0       	push   $0xf0105b0e
f0103617:	e8 84 ca ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f010361c:	83 ec 08             	sub    $0x8,%esp
f010361f:	56                   	push   %esi
f0103620:	68 33 5b 10 f0       	push   $0xf0105b33
f0103625:	e8 be f9 ff ff       	call   f0102fe8 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f010362a:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010362e:	83 e0 03             	and    $0x3,%eax
f0103631:	83 c4 10             	add    $0x10,%esp
f0103634:	66 83 f8 03          	cmp    $0x3,%ax
f0103638:	75 31                	jne    f010366b <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f010363a:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f010363f:	85 c0                	test   %eax,%eax
f0103641:	75 19                	jne    f010365c <trap+0x69>
f0103643:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0103648:	68 ed 55 10 f0       	push   $0xf01055ed
f010364d:	68 ce 00 00 00       	push   $0xce
f0103652:	68 0e 5b 10 f0       	push   $0xf0105b0e
f0103657:	e8 44 ca ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010365c:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103661:	89 c7                	mov    %eax,%edi
f0103663:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103665:	8b 35 84 1f 17 f0    	mov    0xf0171f84,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010366b:	89 35 a0 27 17 f0    	mov    %esi,0xf01727a0
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	
	switch(tf->tf_trapno)
f0103671:	8b 46 28             	mov    0x28(%esi),%eax
f0103674:	83 f8 0e             	cmp    $0xe,%eax
f0103677:	74 0c                	je     f0103685 <trap+0x92>
f0103679:	83 f8 30             	cmp    $0x30,%eax
f010367c:	74 23                	je     f01036a1 <trap+0xae>
f010367e:	83 f8 03             	cmp    $0x3,%eax
f0103681:	75 3f                	jne    f01036c2 <trap+0xcf>
f0103683:	eb 0e                	jmp    f0103693 <trap+0xa0>
	{
		case T_PGFLT:
			page_fault_handler(tf);
f0103685:	83 ec 0c             	sub    $0xc,%esp
f0103688:	56                   	push   %esi
f0103689:	e8 07 ff ff ff       	call   f0103595 <page_fault_handler>
f010368e:	83 c4 10             	add    $0x10,%esp
f0103691:	eb 6a                	jmp    f01036fd <trap+0x10a>
			return;
		case T_BRKPT:
			monitor(tf);
f0103693:	83 ec 0c             	sub    $0xc,%esp
f0103696:	56                   	push   %esi
f0103697:	e8 55 d1 ff ff       	call   f01007f1 <monitor>
f010369c:	83 c4 10             	add    $0x10,%esp
f010369f:	eb 5c                	jmp    f01036fd <trap+0x10a>
			return;
		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
f01036a1:	83 ec 08             	sub    $0x8,%esp
f01036a4:	ff 76 04             	pushl  0x4(%esi)
f01036a7:	ff 36                	pushl  (%esi)
f01036a9:	ff 76 10             	pushl  0x10(%esi)
f01036ac:	ff 76 18             	pushl  0x18(%esi)
f01036af:	ff 76 14             	pushl  0x14(%esi)
f01036b2:	ff 76 1c             	pushl  0x1c(%esi)
f01036b5:	e8 ea 00 00 00       	call   f01037a4 <syscall>
f01036ba:	89 46 1c             	mov    %eax,0x1c(%esi)
f01036bd:	83 c4 20             	add    $0x20,%esp
f01036c0:	eb 3b                	jmp    f01036fd <trap+0x10a>
			return;
	}
	
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01036c2:	83 ec 0c             	sub    $0xc,%esp
f01036c5:	56                   	push   %esi
f01036c6:	e8 57 fd ff ff       	call   f0103422 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01036cb:	83 c4 10             	add    $0x10,%esp
f01036ce:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01036d3:	75 17                	jne    f01036ec <trap+0xf9>
		panic("unhandled trap in kernel");
f01036d5:	83 ec 04             	sub    $0x4,%esp
f01036d8:	68 55 5b 10 f0       	push   $0xf0105b55
f01036dd:	68 b7 00 00 00       	push   $0xb7
f01036e2:	68 0e 5b 10 f0       	push   $0xf0105b0e
f01036e7:	e8 b4 c9 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f01036ec:	83 ec 0c             	sub    $0xc,%esp
f01036ef:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f01036f5:	e8 d5 f7 ff ff       	call   f0102ecf <env_destroy>
f01036fa:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01036fd:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0103702:	85 c0                	test   %eax,%eax
f0103704:	74 06                	je     f010370c <trap+0x119>
f0103706:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010370a:	74 19                	je     f0103725 <trap+0x132>
f010370c:	68 d8 5c 10 f0       	push   $0xf0105cd8
f0103711:	68 ed 55 10 f0       	push   $0xf01055ed
f0103716:	68 e0 00 00 00       	push   $0xe0
f010371b:	68 0e 5b 10 f0       	push   $0xf0105b0e
f0103720:	e8 7b c9 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103725:	83 ec 0c             	sub    $0xc,%esp
f0103728:	50                   	push   %eax
f0103729:	e8 f1 f7 ff ff       	call   f0102f1f <env_run>

f010372e <TH_DIVIDE>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(TH_DIVIDE, 0)	// fault
f010372e:	6a 00                	push   $0x0
f0103730:	6a 00                	push   $0x0
f0103732:	eb 5e                	jmp    f0103792 <_alltraps>

f0103734 <TH_DEBUG>:
TRAPHANDLER_NOEC(TH_DEBUG, 1)	// fault/trap
f0103734:	6a 00                	push   $0x0
f0103736:	6a 01                	push   $0x1
f0103738:	eb 58                	jmp    f0103792 <_alltraps>

f010373a <TH_NMI>:
TRAPHANDLER_NOEC(TH_NMI, 2)	//
f010373a:	6a 00                	push   $0x0
f010373c:	6a 02                	push   $0x2
f010373e:	eb 52                	jmp    f0103792 <_alltraps>

f0103740 <TH_BRKPT>:
TRAPHANDLER_NOEC(TH_BRKPT, 3)	// trap
f0103740:	6a 00                	push   $0x0
f0103742:	6a 03                	push   $0x3
f0103744:	eb 4c                	jmp    f0103792 <_alltraps>

f0103746 <TH_OFLOW>:
TRAPHANDLER_NOEC(TH_OFLOW, 4)	// trap
f0103746:	6a 00                	push   $0x0
f0103748:	6a 04                	push   $0x4
f010374a:	eb 46                	jmp    f0103792 <_alltraps>

f010374c <TH_BOUND>:
TRAPHANDLER_NOEC(TH_BOUND, 5)	// fault
f010374c:	6a 00                	push   $0x0
f010374e:	6a 05                	push   $0x5
f0103750:	eb 40                	jmp    f0103792 <_alltraps>

f0103752 <TH_ILLOP>:
TRAPHANDLER_NOEC(TH_ILLOP, 6)	// fault
f0103752:	6a 00                	push   $0x0
f0103754:	6a 06                	push   $0x6
f0103756:	eb 3a                	jmp    f0103792 <_alltraps>

f0103758 <TH_DEVICE>:
TRAPHANDLER_NOEC(TH_DEVICE, 7)	// fault
f0103758:	6a 00                	push   $0x0
f010375a:	6a 07                	push   $0x7
f010375c:	eb 34                	jmp    f0103792 <_alltraps>

f010375e <TH_DBLFLT>:
TRAPHANDLER     (TH_DBLFLT, 8)	// abort
f010375e:	6a 08                	push   $0x8
f0103760:	eb 30                	jmp    f0103792 <_alltraps>

f0103762 <TH_TSS>:
//TRAPHANDLER_NOEC(TH_COPROC, 9) // abort	
TRAPHANDLER     (TH_TSS, 10)	// fault
f0103762:	6a 0a                	push   $0xa
f0103764:	eb 2c                	jmp    f0103792 <_alltraps>

f0103766 <TH_SEGNP>:
TRAPHANDLER     (TH_SEGNP, 11)	// fault
f0103766:	6a 0b                	push   $0xb
f0103768:	eb 28                	jmp    f0103792 <_alltraps>

f010376a <TH_STACK>:
TRAPHANDLER     (TH_STACK, 12)	// fault
f010376a:	6a 0c                	push   $0xc
f010376c:	eb 24                	jmp    f0103792 <_alltraps>

f010376e <TH_GPFLT>:
TRAPHANDLER     (TH_GPFLT, 13)	// fault/abort
f010376e:	6a 0d                	push   $0xd
f0103770:	eb 20                	jmp    f0103792 <_alltraps>

f0103772 <TH_PGFLT>:
TRAPHANDLER     (TH_PGFLT, 14)	// fault
f0103772:	6a 0e                	push   $0xe
f0103774:	eb 1c                	jmp    f0103792 <_alltraps>

f0103776 <TH_FPERR>:
//TRAPHANDLER_NOEC(TH_RES, 15)	
TRAPHANDLER_NOEC(TH_FPERR, 16)	// fault
f0103776:	6a 00                	push   $0x0
f0103778:	6a 10                	push   $0x10
f010377a:	eb 16                	jmp    f0103792 <_alltraps>

f010377c <TH_ALIGN>:
TRAPHANDLER     (TH_ALIGN, 17)	//
f010377c:	6a 11                	push   $0x11
f010377e:	eb 12                	jmp    f0103792 <_alltraps>

f0103780 <TH_MCHK>:
TRAPHANDLER_NOEC(TH_MCHK, 18)	//
f0103780:	6a 00                	push   $0x0
f0103782:	6a 12                	push   $0x12
f0103784:	eb 0c                	jmp    f0103792 <_alltraps>

f0103786 <TH_SIMDERR>:
TRAPHANDLER_NOEC(TH_SIMDERR, 19) //
f0103786:	6a 00                	push   $0x0
f0103788:	6a 13                	push   $0x13
f010378a:	eb 06                	jmp    f0103792 <_alltraps>

f010378c <TH_SYSCALL>:

TRAPHANDLER_NOEC(TH_SYSCALL, 48) // trap
f010378c:	6a 00                	push   $0x0
f010378e:	6a 30                	push   $0x30
f0103790:	eb 00                	jmp    f0103792 <_alltraps>

f0103792 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

.text
_alltraps:
	pushl	%ds
f0103792:	1e                   	push   %ds
	pushl	%es
f0103793:	06                   	push   %es
	pushal
f0103794:	60                   	pusha  
	mov	$GD_KD, %eax
f0103795:	b8 10 00 00 00       	mov    $0x10,%eax
	mov	%ax, %es
f010379a:	8e c0                	mov    %eax,%es
	mov	%ax, %ds
f010379c:	8e d8                	mov    %eax,%ds
	pushl	%esp
f010379e:	54                   	push   %esp
	call	trap
f010379f:	e8 4f fe ff ff       	call   f01035f3 <trap>

f01037a4 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01037a4:	55                   	push   %ebp
f01037a5:	89 e5                	mov    %esp,%ebp
f01037a7:	83 ec 18             	sub    $0x18,%esp
f01037aa:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) 
f01037ad:	83 f8 01             	cmp    $0x1,%eax
f01037b0:	74 44                	je     f01037f6 <syscall+0x52>
f01037b2:	83 f8 01             	cmp    $0x1,%eax
f01037b5:	72 0f                	jb     f01037c6 <syscall+0x22>
f01037b7:	83 f8 02             	cmp    $0x2,%eax
f01037ba:	74 41                	je     f01037fd <syscall+0x59>
f01037bc:	83 f8 03             	cmp    $0x3,%eax
f01037bf:	74 46                	je     f0103807 <syscall+0x63>
f01037c1:	e9 a6 00 00 00       	jmp    f010386c <syscall+0xc8>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv,s,len,PTE_U);
f01037c6:	6a 04                	push   $0x4
f01037c8:	ff 75 10             	pushl  0x10(%ebp)
f01037cb:	ff 75 0c             	pushl  0xc(%ebp)
f01037ce:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f01037d4:	e8 f7 f0 ff ff       	call   f01028d0 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01037d9:	83 c4 0c             	add    $0xc,%esp
f01037dc:	ff 75 0c             	pushl  0xc(%ebp)
f01037df:	ff 75 10             	pushl  0x10(%ebp)
f01037e2:	68 70 5d 10 f0       	push   $0xf0105d70
f01037e7:	e8 fc f7 ff ff       	call   f0102fe8 <cprintf>
f01037ec:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) 
	{
		case SYS_cputs:
			sys_cputs((char*)a1,a2);
			return 0;
f01037ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01037f4:	eb 7b                	jmp    f0103871 <syscall+0xcd>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01037f6:	e8 c8 cc ff ff       	call   f01004c3 <cons_getc>
		case SYS_cputs:
			sys_cputs((char*)a1,a2);
			return 0;
			break;
		case SYS_cgetc:
			return sys_cgetc();
f01037fb:	eb 74                	jmp    f0103871 <syscall+0xcd>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01037fd:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0103802:	8b 40 48             	mov    0x48(%eax),%eax
			break;
		case SYS_cgetc:
			return sys_cgetc();
			break;
		case SYS_getenvid:
			return sys_getenvid();	
f0103805:	eb 6a                	jmp    f0103871 <syscall+0xcd>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103807:	83 ec 04             	sub    $0x4,%esp
f010380a:	6a 01                	push   $0x1
f010380c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010380f:	50                   	push   %eax
f0103810:	ff 75 0c             	pushl  0xc(%ebp)
f0103813:	e8 6d f1 ff ff       	call   f0102985 <envid2env>
f0103818:	83 c4 10             	add    $0x10,%esp
f010381b:	85 c0                	test   %eax,%eax
f010381d:	78 52                	js     f0103871 <syscall+0xcd>
		return r;
	if (e == curenv)
f010381f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103822:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0103828:	39 d0                	cmp    %edx,%eax
f010382a:	75 15                	jne    f0103841 <syscall+0x9d>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010382c:	83 ec 08             	sub    $0x8,%esp
f010382f:	ff 70 48             	pushl  0x48(%eax)
f0103832:	68 75 5d 10 f0       	push   $0xf0105d75
f0103837:	e8 ac f7 ff ff       	call   f0102fe8 <cprintf>
f010383c:	83 c4 10             	add    $0x10,%esp
f010383f:	eb 16                	jmp    f0103857 <syscall+0xb3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103841:	83 ec 04             	sub    $0x4,%esp
f0103844:	ff 70 48             	pushl  0x48(%eax)
f0103847:	ff 72 48             	pushl  0x48(%edx)
f010384a:	68 90 5d 10 f0       	push   $0xf0105d90
f010384f:	e8 94 f7 ff ff       	call   f0102fe8 <cprintf>
f0103854:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103857:	83 ec 0c             	sub    $0xc,%esp
f010385a:	ff 75 f4             	pushl  -0xc(%ebp)
f010385d:	e8 6d f6 ff ff       	call   f0102ecf <env_destroy>
f0103862:	83 c4 10             	add    $0x10,%esp
	return 0;
f0103865:	b8 00 00 00 00       	mov    $0x0,%eax
f010386a:	eb 05                	jmp    f0103871 <syscall+0xcd>
			break;		
		case SYS_env_destroy:
			return sys_env_destroy((envid_t)a1);
			break;
		default:
			return -E_INVAL;
f010386c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f0103871:	c9                   	leave  
f0103872:	c3                   	ret    

f0103873 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103873:	55                   	push   %ebp
f0103874:	89 e5                	mov    %esp,%ebp
f0103876:	57                   	push   %edi
f0103877:	56                   	push   %esi
f0103878:	53                   	push   %ebx
f0103879:	83 ec 14             	sub    $0x14,%esp
f010387c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010387f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103882:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103885:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103888:	8b 1a                	mov    (%edx),%ebx
f010388a:	8b 01                	mov    (%ecx),%eax
f010388c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010388f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103896:	eb 7f                	jmp    f0103917 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0103898:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010389b:	01 d8                	add    %ebx,%eax
f010389d:	89 c6                	mov    %eax,%esi
f010389f:	c1 ee 1f             	shr    $0x1f,%esi
f01038a2:	01 c6                	add    %eax,%esi
f01038a4:	d1 fe                	sar    %esi
f01038a6:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01038a9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01038ac:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01038af:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01038b1:	eb 03                	jmp    f01038b6 <stab_binsearch+0x43>
			m--;
f01038b3:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01038b6:	39 c3                	cmp    %eax,%ebx
f01038b8:	7f 0d                	jg     f01038c7 <stab_binsearch+0x54>
f01038ba:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01038be:	83 ea 0c             	sub    $0xc,%edx
f01038c1:	39 f9                	cmp    %edi,%ecx
f01038c3:	75 ee                	jne    f01038b3 <stab_binsearch+0x40>
f01038c5:	eb 05                	jmp    f01038cc <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01038c7:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01038ca:	eb 4b                	jmp    f0103917 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01038cc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01038cf:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01038d2:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01038d6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01038d9:	76 11                	jbe    f01038ec <stab_binsearch+0x79>
			*region_left = m;
f01038db:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01038de:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01038e0:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038e3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01038ea:	eb 2b                	jmp    f0103917 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01038ec:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01038ef:	73 14                	jae    f0103905 <stab_binsearch+0x92>
			*region_right = m - 1;
f01038f1:	83 e8 01             	sub    $0x1,%eax
f01038f4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01038f7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01038fa:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01038fc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103903:	eb 12                	jmp    f0103917 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103905:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103908:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010390a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010390e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103910:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103917:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010391a:	0f 8e 78 ff ff ff    	jle    f0103898 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103920:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103924:	75 0f                	jne    f0103935 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103926:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103929:	8b 00                	mov    (%eax),%eax
f010392b:	83 e8 01             	sub    $0x1,%eax
f010392e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103931:	89 06                	mov    %eax,(%esi)
f0103933:	eb 2c                	jmp    f0103961 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103935:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103938:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010393a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010393d:	8b 0e                	mov    (%esi),%ecx
f010393f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103942:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103945:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103948:	eb 03                	jmp    f010394d <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010394a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010394d:	39 c8                	cmp    %ecx,%eax
f010394f:	7e 0b                	jle    f010395c <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103951:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103955:	83 ea 0c             	sub    $0xc,%edx
f0103958:	39 df                	cmp    %ebx,%edi
f010395a:	75 ee                	jne    f010394a <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010395c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010395f:	89 06                	mov    %eax,(%esi)
	}
}
f0103961:	83 c4 14             	add    $0x14,%esp
f0103964:	5b                   	pop    %ebx
f0103965:	5e                   	pop    %esi
f0103966:	5f                   	pop    %edi
f0103967:	5d                   	pop    %ebp
f0103968:	c3                   	ret    

f0103969 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103969:	55                   	push   %ebp
f010396a:	89 e5                	mov    %esp,%ebp
f010396c:	57                   	push   %edi
f010396d:	56                   	push   %esi
f010396e:	53                   	push   %ebx
f010396f:	83 ec 3c             	sub    $0x3c,%esp
f0103972:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103975:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103978:	c7 03 a8 5d 10 f0    	movl   $0xf0105da8,(%ebx)
	info->eip_line = 0;
f010397e:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103985:	c7 43 08 a8 5d 10 f0 	movl   $0xf0105da8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010398c:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103993:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103996:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010399d:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01039a3:	77 7e                	ja     f0103a23 <debuginfo_eip+0xba>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_U))
f01039a5:	6a 04                	push   $0x4
f01039a7:	6a 10                	push   $0x10
f01039a9:	68 00 00 20 00       	push   $0x200000
f01039ae:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f01039b4:	e8 5d ee ff ff       	call   f0102816 <user_mem_check>
f01039b9:	83 c4 10             	add    $0x10,%esp
f01039bc:	85 c0                	test   %eax,%eax
f01039be:	0f 85 29 02 00 00    	jne    f0103bed <debuginfo_eip+0x284>
			return -1;

		stabs = usd->stabs;
f01039c4:	a1 00 00 20 00       	mov    0x200000,%eax
f01039c9:	89 c1                	mov    %eax,%ecx
f01039cb:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f01039ce:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f01039d4:	a1 08 00 20 00       	mov    0x200008,%eax
f01039d9:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01039dc:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01039e2:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, sizeof(struct Stab), PTE_U))
f01039e5:	6a 04                	push   $0x4
f01039e7:	6a 0c                	push   $0xc
f01039e9:	51                   	push   %ecx
f01039ea:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f01039f0:	e8 21 ee ff ff       	call   f0102816 <user_mem_check>
f01039f5:	83 c4 10             	add    $0x10,%esp
f01039f8:	85 c0                	test   %eax,%eax
f01039fa:	0f 85 f4 01 00 00    	jne    f0103bf4 <debuginfo_eip+0x28b>
			return -1;

		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
f0103a00:	6a 04                	push   $0x4
f0103a02:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103a05:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0103a08:	29 ca                	sub    %ecx,%edx
f0103a0a:	52                   	push   %edx
f0103a0b:	51                   	push   %ecx
f0103a0c:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103a12:	e8 ff ed ff ff       	call   f0102816 <user_mem_check>
f0103a17:	83 c4 10             	add    $0x10,%esp
f0103a1a:	85 c0                	test   %eax,%eax
f0103a1c:	74 1f                	je     f0103a3d <debuginfo_eip+0xd4>
f0103a1e:	e9 d8 01 00 00       	jmp    f0103bfb <debuginfo_eip+0x292>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103a23:	c7 45 bc 21 03 11 f0 	movl   $0xf0110321,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103a2a:	c7 45 b8 ed d8 10 f0 	movl   $0xf010d8ed,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103a31:	be ec d8 10 f0       	mov    $0xf010d8ec,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103a36:	c7 45 c0 c0 5f 10 f0 	movl   $0xf0105fc0,-0x40(%ebp)
			return -1;
	
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103a3d:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103a40:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0103a43:	0f 83 b9 01 00 00    	jae    f0103c02 <debuginfo_eip+0x299>
f0103a49:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103a4d:	0f 85 b6 01 00 00    	jne    f0103c09 <debuginfo_eip+0x2a0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103a53:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103a5a:	2b 75 c0             	sub    -0x40(%ebp),%esi
f0103a5d:	c1 fe 02             	sar    $0x2,%esi
f0103a60:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0103a66:	83 e8 01             	sub    $0x1,%eax
f0103a69:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103a6c:	83 ec 08             	sub    $0x8,%esp
f0103a6f:	57                   	push   %edi
f0103a70:	6a 64                	push   $0x64
f0103a72:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0103a75:	89 d1                	mov    %edx,%ecx
f0103a77:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103a7a:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103a7d:	89 f0                	mov    %esi,%eax
f0103a7f:	e8 ef fd ff ff       	call   f0103873 <stab_binsearch>
	if (lfile == 0)
f0103a84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a87:	83 c4 10             	add    $0x10,%esp
f0103a8a:	85 c0                	test   %eax,%eax
f0103a8c:	0f 84 7e 01 00 00    	je     f0103c10 <debuginfo_eip+0x2a7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103a92:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103a95:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a98:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103a9b:	83 ec 08             	sub    $0x8,%esp
f0103a9e:	57                   	push   %edi
f0103a9f:	6a 24                	push   $0x24
f0103aa1:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0103aa4:	89 d1                	mov    %edx,%ecx
f0103aa6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103aa9:	89 f0                	mov    %esi,%eax
f0103aab:	e8 c3 fd ff ff       	call   f0103873 <stab_binsearch>

	if (lfun <= rfun) {
f0103ab0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103ab3:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103ab6:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103ab9:	83 c4 10             	add    $0x10,%esp
f0103abc:	39 d0                	cmp    %edx,%eax
f0103abe:	7f 2b                	jg     f0103aeb <debuginfo_eip+0x182>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103ac0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103ac3:	8d 0c 96             	lea    (%esi,%edx,4),%ecx
f0103ac6:	8b 11                	mov    (%ecx),%edx
f0103ac8:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0103acb:	2b 75 b8             	sub    -0x48(%ebp),%esi
f0103ace:	39 f2                	cmp    %esi,%edx
f0103ad0:	73 06                	jae    f0103ad8 <debuginfo_eip+0x16f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103ad2:	03 55 b8             	add    -0x48(%ebp),%edx
f0103ad5:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103ad8:	8b 51 08             	mov    0x8(%ecx),%edx
f0103adb:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103ade:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0103ae0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103ae3:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103ae6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103ae9:	eb 0f                	jmp    f0103afa <debuginfo_eip+0x191>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103aeb:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0103aee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103af1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103af4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103af7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103afa:	83 ec 08             	sub    $0x8,%esp
f0103afd:	6a 3a                	push   $0x3a
f0103aff:	ff 73 08             	pushl  0x8(%ebx)
f0103b02:	e8 97 08 00 00       	call   f010439e <strfind>
f0103b07:	2b 43 08             	sub    0x8(%ebx),%eax
f0103b0a:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103b0d:	83 c4 08             	add    $0x8,%esp
f0103b10:	57                   	push   %edi
f0103b11:	6a 44                	push   $0x44
f0103b13:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103b16:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103b19:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103b1c:	89 f0                	mov    %esi,%eax
f0103b1e:	e8 50 fd ff ff       	call   f0103873 <stab_binsearch>
	if(lline > rline)
f0103b23:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103b26:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103b29:	83 c4 10             	add    $0x10,%esp
f0103b2c:	39 c2                	cmp    %eax,%edx
f0103b2e:	0f 8f e3 00 00 00    	jg     f0103c17 <debuginfo_eip+0x2ae>
	return -1;
	info->eip_line =  stabs[rline].n_desc;	
f0103b34:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103b37:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103b3c:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103b3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b42:	89 d0                	mov    %edx,%eax
f0103b44:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103b47:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103b4a:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103b4e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103b51:	eb 0a                	jmp    f0103b5d <debuginfo_eip+0x1f4>
f0103b53:	83 e8 01             	sub    $0x1,%eax
f0103b56:	83 ea 0c             	sub    $0xc,%edx
f0103b59:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103b5d:	39 c7                	cmp    %eax,%edi
f0103b5f:	7e 05                	jle    f0103b66 <debuginfo_eip+0x1fd>
f0103b61:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b64:	eb 47                	jmp    f0103bad <debuginfo_eip+0x244>
	       && stabs[lline].n_type != N_SOL
f0103b66:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103b6a:	80 f9 84             	cmp    $0x84,%cl
f0103b6d:	75 0e                	jne    f0103b7d <debuginfo_eip+0x214>
f0103b6f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b72:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103b76:	74 1c                	je     f0103b94 <debuginfo_eip+0x22b>
f0103b78:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103b7b:	eb 17                	jmp    f0103b94 <debuginfo_eip+0x22b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103b7d:	80 f9 64             	cmp    $0x64,%cl
f0103b80:	75 d1                	jne    f0103b53 <debuginfo_eip+0x1ea>
f0103b82:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103b86:	74 cb                	je     f0103b53 <debuginfo_eip+0x1ea>
f0103b88:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b8b:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103b8f:	74 03                	je     f0103b94 <debuginfo_eip+0x22b>
f0103b91:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103b94:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103b97:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103b9a:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103b9d:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103ba0:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103ba3:	29 f8                	sub    %edi,%eax
f0103ba5:	39 c2                	cmp    %eax,%edx
f0103ba7:	73 04                	jae    f0103bad <debuginfo_eip+0x244>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103ba9:	01 fa                	add    %edi,%edx
f0103bab:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103bad:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103bb0:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103bb3:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103bb8:	39 f2                	cmp    %esi,%edx
f0103bba:	7d 67                	jge    f0103c23 <debuginfo_eip+0x2ba>
		for (lline = lfun + 1;
f0103bbc:	83 c2 01             	add    $0x1,%edx
f0103bbf:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103bc2:	89 d0                	mov    %edx,%eax
f0103bc4:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103bc7:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103bca:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103bcd:	eb 04                	jmp    f0103bd3 <debuginfo_eip+0x26a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103bcf:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103bd3:	39 c6                	cmp    %eax,%esi
f0103bd5:	7e 47                	jle    f0103c1e <debuginfo_eip+0x2b5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103bd7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103bdb:	83 c0 01             	add    $0x1,%eax
f0103bde:	83 c2 0c             	add    $0xc,%edx
f0103be1:	80 f9 a0             	cmp    $0xa0,%cl
f0103be4:	74 e9                	je     f0103bcf <debuginfo_eip+0x266>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103be6:	b8 00 00 00 00       	mov    $0x0,%eax
f0103beb:	eb 36                	jmp    f0103c23 <debuginfo_eip+0x2ba>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,usd,sizeof(struct UserStabData),PTE_U))
			return -1;
f0103bed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103bf2:	eb 2f                	jmp    f0103c23 <debuginfo_eip+0x2ba>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, sizeof(struct Stab), PTE_U))
			return -1;
f0103bf4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103bf9:	eb 28                	jmp    f0103c23 <debuginfo_eip+0x2ba>

		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U))
			return -1;
f0103bfb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c00:	eb 21                	jmp    f0103c23 <debuginfo_eip+0x2ba>
	
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103c02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c07:	eb 1a                	jmp    f0103c23 <debuginfo_eip+0x2ba>
f0103c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c0e:	eb 13                	jmp    f0103c23 <debuginfo_eip+0x2ba>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103c10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c15:	eb 0c                	jmp    f0103c23 <debuginfo_eip+0x2ba>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline > rline)
	return -1;
f0103c17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103c1c:	eb 05                	jmp    f0103c23 <debuginfo_eip+0x2ba>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103c1e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c23:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c26:	5b                   	pop    %ebx
f0103c27:	5e                   	pop    %esi
f0103c28:	5f                   	pop    %edi
f0103c29:	5d                   	pop    %ebp
f0103c2a:	c3                   	ret    

f0103c2b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103c2b:	55                   	push   %ebp
f0103c2c:	89 e5                	mov    %esp,%ebp
f0103c2e:	57                   	push   %edi
f0103c2f:	56                   	push   %esi
f0103c30:	53                   	push   %ebx
f0103c31:	83 ec 1c             	sub    $0x1c,%esp
f0103c34:	89 c7                	mov    %eax,%edi
f0103c36:	89 d6                	mov    %edx,%esi
f0103c38:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c3b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c3e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c41:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103c44:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103c47:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103c4c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103c4f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103c52:	39 d3                	cmp    %edx,%ebx
f0103c54:	72 05                	jb     f0103c5b <printnum+0x30>
f0103c56:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103c59:	77 45                	ja     f0103ca0 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103c5b:	83 ec 0c             	sub    $0xc,%esp
f0103c5e:	ff 75 18             	pushl  0x18(%ebp)
f0103c61:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c64:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103c67:	53                   	push   %ebx
f0103c68:	ff 75 10             	pushl  0x10(%ebp)
f0103c6b:	83 ec 08             	sub    $0x8,%esp
f0103c6e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c71:	ff 75 e0             	pushl  -0x20(%ebp)
f0103c74:	ff 75 dc             	pushl  -0x24(%ebp)
f0103c77:	ff 75 d8             	pushl  -0x28(%ebp)
f0103c7a:	e8 41 09 00 00       	call   f01045c0 <__udivdi3>
f0103c7f:	83 c4 18             	add    $0x18,%esp
f0103c82:	52                   	push   %edx
f0103c83:	50                   	push   %eax
f0103c84:	89 f2                	mov    %esi,%edx
f0103c86:	89 f8                	mov    %edi,%eax
f0103c88:	e8 9e ff ff ff       	call   f0103c2b <printnum>
f0103c8d:	83 c4 20             	add    $0x20,%esp
f0103c90:	eb 18                	jmp    f0103caa <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103c92:	83 ec 08             	sub    $0x8,%esp
f0103c95:	56                   	push   %esi
f0103c96:	ff 75 18             	pushl  0x18(%ebp)
f0103c99:	ff d7                	call   *%edi
f0103c9b:	83 c4 10             	add    $0x10,%esp
f0103c9e:	eb 03                	jmp    f0103ca3 <printnum+0x78>
f0103ca0:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103ca3:	83 eb 01             	sub    $0x1,%ebx
f0103ca6:	85 db                	test   %ebx,%ebx
f0103ca8:	7f e8                	jg     f0103c92 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103caa:	83 ec 08             	sub    $0x8,%esp
f0103cad:	56                   	push   %esi
f0103cae:	83 ec 04             	sub    $0x4,%esp
f0103cb1:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103cb4:	ff 75 e0             	pushl  -0x20(%ebp)
f0103cb7:	ff 75 dc             	pushl  -0x24(%ebp)
f0103cba:	ff 75 d8             	pushl  -0x28(%ebp)
f0103cbd:	e8 2e 0a 00 00       	call   f01046f0 <__umoddi3>
f0103cc2:	83 c4 14             	add    $0x14,%esp
f0103cc5:	0f be 80 b2 5d 10 f0 	movsbl -0xfefa24e(%eax),%eax
f0103ccc:	50                   	push   %eax
f0103ccd:	ff d7                	call   *%edi
}
f0103ccf:	83 c4 10             	add    $0x10,%esp
f0103cd2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103cd5:	5b                   	pop    %ebx
f0103cd6:	5e                   	pop    %esi
f0103cd7:	5f                   	pop    %edi
f0103cd8:	5d                   	pop    %ebp
f0103cd9:	c3                   	ret    

f0103cda <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103cda:	55                   	push   %ebp
f0103cdb:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103cdd:	83 fa 01             	cmp    $0x1,%edx
f0103ce0:	7e 0e                	jle    f0103cf0 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103ce2:	8b 10                	mov    (%eax),%edx
f0103ce4:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103ce7:	89 08                	mov    %ecx,(%eax)
f0103ce9:	8b 02                	mov    (%edx),%eax
f0103ceb:	8b 52 04             	mov    0x4(%edx),%edx
f0103cee:	eb 22                	jmp    f0103d12 <getuint+0x38>
	else if (lflag)
f0103cf0:	85 d2                	test   %edx,%edx
f0103cf2:	74 10                	je     f0103d04 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103cf4:	8b 10                	mov    (%eax),%edx
f0103cf6:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103cf9:	89 08                	mov    %ecx,(%eax)
f0103cfb:	8b 02                	mov    (%edx),%eax
f0103cfd:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d02:	eb 0e                	jmp    f0103d12 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103d04:	8b 10                	mov    (%eax),%edx
f0103d06:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103d09:	89 08                	mov    %ecx,(%eax)
f0103d0b:	8b 02                	mov    (%edx),%eax
f0103d0d:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103d12:	5d                   	pop    %ebp
f0103d13:	c3                   	ret    

f0103d14 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103d14:	55                   	push   %ebp
f0103d15:	89 e5                	mov    %esp,%ebp
f0103d17:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103d1a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103d1e:	8b 10                	mov    (%eax),%edx
f0103d20:	3b 50 04             	cmp    0x4(%eax),%edx
f0103d23:	73 0a                	jae    f0103d2f <sprintputch+0x1b>
		*b->buf++ = ch;
f0103d25:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103d28:	89 08                	mov    %ecx,(%eax)
f0103d2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d2d:	88 02                	mov    %al,(%edx)
}
f0103d2f:	5d                   	pop    %ebp
f0103d30:	c3                   	ret    

f0103d31 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103d31:	55                   	push   %ebp
f0103d32:	89 e5                	mov    %esp,%ebp
f0103d34:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103d37:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103d3a:	50                   	push   %eax
f0103d3b:	ff 75 10             	pushl  0x10(%ebp)
f0103d3e:	ff 75 0c             	pushl  0xc(%ebp)
f0103d41:	ff 75 08             	pushl  0x8(%ebp)
f0103d44:	e8 05 00 00 00       	call   f0103d4e <vprintfmt>
	va_end(ap);
}
f0103d49:	83 c4 10             	add    $0x10,%esp
f0103d4c:	c9                   	leave  
f0103d4d:	c3                   	ret    

f0103d4e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103d4e:	55                   	push   %ebp
f0103d4f:	89 e5                	mov    %esp,%ebp
f0103d51:	57                   	push   %edi
f0103d52:	56                   	push   %esi
f0103d53:	53                   	push   %ebx
f0103d54:	83 ec 2c             	sub    $0x2c,%esp
f0103d57:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d5a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d5d:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103d60:	eb 12                	jmp    f0103d74 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103d62:	85 c0                	test   %eax,%eax
f0103d64:	0f 84 89 03 00 00    	je     f01040f3 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103d6a:	83 ec 08             	sub    $0x8,%esp
f0103d6d:	53                   	push   %ebx
f0103d6e:	50                   	push   %eax
f0103d6f:	ff d6                	call   *%esi
f0103d71:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103d74:	83 c7 01             	add    $0x1,%edi
f0103d77:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103d7b:	83 f8 25             	cmp    $0x25,%eax
f0103d7e:	75 e2                	jne    f0103d62 <vprintfmt+0x14>
f0103d80:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103d84:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103d8b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d92:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103d99:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d9e:	eb 07                	jmp    f0103da7 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103da0:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103da3:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103da7:	8d 47 01             	lea    0x1(%edi),%eax
f0103daa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103dad:	0f b6 07             	movzbl (%edi),%eax
f0103db0:	0f b6 c8             	movzbl %al,%ecx
f0103db3:	83 e8 23             	sub    $0x23,%eax
f0103db6:	3c 55                	cmp    $0x55,%al
f0103db8:	0f 87 1a 03 00 00    	ja     f01040d8 <vprintfmt+0x38a>
f0103dbe:	0f b6 c0             	movzbl %al,%eax
f0103dc1:	ff 24 85 3c 5e 10 f0 	jmp    *-0xfefa1c4(,%eax,4)
f0103dc8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103dcb:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103dcf:	eb d6                	jmp    f0103da7 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dd1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103dd4:	b8 00 00 00 00       	mov    $0x0,%eax
f0103dd9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103ddc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103ddf:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103de3:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103de6:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103de9:	83 fa 09             	cmp    $0x9,%edx
f0103dec:	77 39                	ja     f0103e27 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103dee:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103df1:	eb e9                	jmp    f0103ddc <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103df3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103df6:	8d 48 04             	lea    0x4(%eax),%ecx
f0103df9:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103dfc:	8b 00                	mov    (%eax),%eax
f0103dfe:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103e04:	eb 27                	jmp    f0103e2d <vprintfmt+0xdf>
f0103e06:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103e09:	85 c0                	test   %eax,%eax
f0103e0b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e10:	0f 49 c8             	cmovns %eax,%ecx
f0103e13:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e16:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e19:	eb 8c                	jmp    f0103da7 <vprintfmt+0x59>
f0103e1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103e1e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103e25:	eb 80                	jmp    f0103da7 <vprintfmt+0x59>
f0103e27:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103e2a:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103e2d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103e31:	0f 89 70 ff ff ff    	jns    f0103da7 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103e37:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103e3a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e3d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103e44:	e9 5e ff ff ff       	jmp    f0103da7 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103e49:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e4c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103e4f:	e9 53 ff ff ff       	jmp    f0103da7 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103e54:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e57:	8d 50 04             	lea    0x4(%eax),%edx
f0103e5a:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e5d:	83 ec 08             	sub    $0x8,%esp
f0103e60:	53                   	push   %ebx
f0103e61:	ff 30                	pushl  (%eax)
f0103e63:	ff d6                	call   *%esi
			break;
f0103e65:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103e6b:	e9 04 ff ff ff       	jmp    f0103d74 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103e70:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e73:	8d 50 04             	lea    0x4(%eax),%edx
f0103e76:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e79:	8b 00                	mov    (%eax),%eax
f0103e7b:	99                   	cltd   
f0103e7c:	31 d0                	xor    %edx,%eax
f0103e7e:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103e80:	83 f8 06             	cmp    $0x6,%eax
f0103e83:	7f 0b                	jg     f0103e90 <vprintfmt+0x142>
f0103e85:	8b 14 85 94 5f 10 f0 	mov    -0xfefa06c(,%eax,4),%edx
f0103e8c:	85 d2                	test   %edx,%edx
f0103e8e:	75 18                	jne    f0103ea8 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103e90:	50                   	push   %eax
f0103e91:	68 ca 5d 10 f0       	push   $0xf0105dca
f0103e96:	53                   	push   %ebx
f0103e97:	56                   	push   %esi
f0103e98:	e8 94 fe ff ff       	call   f0103d31 <printfmt>
f0103e9d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ea0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103ea3:	e9 cc fe ff ff       	jmp    f0103d74 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103ea8:	52                   	push   %edx
f0103ea9:	68 ff 55 10 f0       	push   $0xf01055ff
f0103eae:	53                   	push   %ebx
f0103eaf:	56                   	push   %esi
f0103eb0:	e8 7c fe ff ff       	call   f0103d31 <printfmt>
f0103eb5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103eb8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103ebb:	e9 b4 fe ff ff       	jmp    f0103d74 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103ec0:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ec3:	8d 50 04             	lea    0x4(%eax),%edx
f0103ec6:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ec9:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103ecb:	85 ff                	test   %edi,%edi
f0103ecd:	b8 c3 5d 10 f0       	mov    $0xf0105dc3,%eax
f0103ed2:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103ed5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103ed9:	0f 8e 94 00 00 00    	jle    f0103f73 <vprintfmt+0x225>
f0103edf:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103ee3:	0f 84 98 00 00 00    	je     f0103f81 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ee9:	83 ec 08             	sub    $0x8,%esp
f0103eec:	ff 75 d0             	pushl  -0x30(%ebp)
f0103eef:	57                   	push   %edi
f0103ef0:	e8 5f 03 00 00       	call   f0104254 <strnlen>
f0103ef5:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103ef8:	29 c1                	sub    %eax,%ecx
f0103efa:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103efd:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103f00:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103f04:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103f07:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103f0a:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f0c:	eb 0f                	jmp    f0103f1d <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103f0e:	83 ec 08             	sub    $0x8,%esp
f0103f11:	53                   	push   %ebx
f0103f12:	ff 75 e0             	pushl  -0x20(%ebp)
f0103f15:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f17:	83 ef 01             	sub    $0x1,%edi
f0103f1a:	83 c4 10             	add    $0x10,%esp
f0103f1d:	85 ff                	test   %edi,%edi
f0103f1f:	7f ed                	jg     f0103f0e <vprintfmt+0x1c0>
f0103f21:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103f24:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103f27:	85 c9                	test   %ecx,%ecx
f0103f29:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f2e:	0f 49 c1             	cmovns %ecx,%eax
f0103f31:	29 c1                	sub    %eax,%ecx
f0103f33:	89 75 08             	mov    %esi,0x8(%ebp)
f0103f36:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103f39:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103f3c:	89 cb                	mov    %ecx,%ebx
f0103f3e:	eb 4d                	jmp    f0103f8d <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103f40:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103f44:	74 1b                	je     f0103f61 <vprintfmt+0x213>
f0103f46:	0f be c0             	movsbl %al,%eax
f0103f49:	83 e8 20             	sub    $0x20,%eax
f0103f4c:	83 f8 5e             	cmp    $0x5e,%eax
f0103f4f:	76 10                	jbe    f0103f61 <vprintfmt+0x213>
					putch('?', putdat);
f0103f51:	83 ec 08             	sub    $0x8,%esp
f0103f54:	ff 75 0c             	pushl  0xc(%ebp)
f0103f57:	6a 3f                	push   $0x3f
f0103f59:	ff 55 08             	call   *0x8(%ebp)
f0103f5c:	83 c4 10             	add    $0x10,%esp
f0103f5f:	eb 0d                	jmp    f0103f6e <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103f61:	83 ec 08             	sub    $0x8,%esp
f0103f64:	ff 75 0c             	pushl  0xc(%ebp)
f0103f67:	52                   	push   %edx
f0103f68:	ff 55 08             	call   *0x8(%ebp)
f0103f6b:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103f6e:	83 eb 01             	sub    $0x1,%ebx
f0103f71:	eb 1a                	jmp    f0103f8d <vprintfmt+0x23f>
f0103f73:	89 75 08             	mov    %esi,0x8(%ebp)
f0103f76:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103f79:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103f7c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103f7f:	eb 0c                	jmp    f0103f8d <vprintfmt+0x23f>
f0103f81:	89 75 08             	mov    %esi,0x8(%ebp)
f0103f84:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103f87:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103f8a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103f8d:	83 c7 01             	add    $0x1,%edi
f0103f90:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103f94:	0f be d0             	movsbl %al,%edx
f0103f97:	85 d2                	test   %edx,%edx
f0103f99:	74 23                	je     f0103fbe <vprintfmt+0x270>
f0103f9b:	85 f6                	test   %esi,%esi
f0103f9d:	78 a1                	js     f0103f40 <vprintfmt+0x1f2>
f0103f9f:	83 ee 01             	sub    $0x1,%esi
f0103fa2:	79 9c                	jns    f0103f40 <vprintfmt+0x1f2>
f0103fa4:	89 df                	mov    %ebx,%edi
f0103fa6:	8b 75 08             	mov    0x8(%ebp),%esi
f0103fa9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103fac:	eb 18                	jmp    f0103fc6 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103fae:	83 ec 08             	sub    $0x8,%esp
f0103fb1:	53                   	push   %ebx
f0103fb2:	6a 20                	push   $0x20
f0103fb4:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103fb6:	83 ef 01             	sub    $0x1,%edi
f0103fb9:	83 c4 10             	add    $0x10,%esp
f0103fbc:	eb 08                	jmp    f0103fc6 <vprintfmt+0x278>
f0103fbe:	89 df                	mov    %ebx,%edi
f0103fc0:	8b 75 08             	mov    0x8(%ebp),%esi
f0103fc3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103fc6:	85 ff                	test   %edi,%edi
f0103fc8:	7f e4                	jg     f0103fae <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103fcd:	e9 a2 fd ff ff       	jmp    f0103d74 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103fd2:	83 fa 01             	cmp    $0x1,%edx
f0103fd5:	7e 16                	jle    f0103fed <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103fd7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fda:	8d 50 08             	lea    0x8(%eax),%edx
f0103fdd:	89 55 14             	mov    %edx,0x14(%ebp)
f0103fe0:	8b 50 04             	mov    0x4(%eax),%edx
f0103fe3:	8b 00                	mov    (%eax),%eax
f0103fe5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103fe8:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103feb:	eb 32                	jmp    f010401f <vprintfmt+0x2d1>
	else if (lflag)
f0103fed:	85 d2                	test   %edx,%edx
f0103fef:	74 18                	je     f0104009 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103ff1:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ff4:	8d 50 04             	lea    0x4(%eax),%edx
f0103ff7:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ffa:	8b 00                	mov    (%eax),%eax
f0103ffc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103fff:	89 c1                	mov    %eax,%ecx
f0104001:	c1 f9 1f             	sar    $0x1f,%ecx
f0104004:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104007:	eb 16                	jmp    f010401f <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0104009:	8b 45 14             	mov    0x14(%ebp),%eax
f010400c:	8d 50 04             	lea    0x4(%eax),%edx
f010400f:	89 55 14             	mov    %edx,0x14(%ebp)
f0104012:	8b 00                	mov    (%eax),%eax
f0104014:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104017:	89 c1                	mov    %eax,%ecx
f0104019:	c1 f9 1f             	sar    $0x1f,%ecx
f010401c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010401f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104022:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104025:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010402a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010402e:	79 74                	jns    f01040a4 <vprintfmt+0x356>
				putch('-', putdat);
f0104030:	83 ec 08             	sub    $0x8,%esp
f0104033:	53                   	push   %ebx
f0104034:	6a 2d                	push   $0x2d
f0104036:	ff d6                	call   *%esi
				num = -(long long) num;
f0104038:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010403b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010403e:	f7 d8                	neg    %eax
f0104040:	83 d2 00             	adc    $0x0,%edx
f0104043:	f7 da                	neg    %edx
f0104045:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104048:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010404d:	eb 55                	jmp    f01040a4 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010404f:	8d 45 14             	lea    0x14(%ebp),%eax
f0104052:	e8 83 fc ff ff       	call   f0103cda <getuint>
			base = 10;
f0104057:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010405c:	eb 46                	jmp    f01040a4 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
		        num = getuint(&ap, lflag);
f010405e:	8d 45 14             	lea    0x14(%ebp),%eax
f0104061:	e8 74 fc ff ff       	call   f0103cda <getuint>
			base=8;
f0104066:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010406b:	eb 37                	jmp    f01040a4 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f010406d:	83 ec 08             	sub    $0x8,%esp
f0104070:	53                   	push   %ebx
f0104071:	6a 30                	push   $0x30
f0104073:	ff d6                	call   *%esi
			putch('x', putdat);
f0104075:	83 c4 08             	add    $0x8,%esp
f0104078:	53                   	push   %ebx
f0104079:	6a 78                	push   $0x78
f010407b:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010407d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104080:	8d 50 04             	lea    0x4(%eax),%edx
f0104083:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104086:	8b 00                	mov    (%eax),%eax
f0104088:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010408d:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104090:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104095:	eb 0d                	jmp    f01040a4 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104097:	8d 45 14             	lea    0x14(%ebp),%eax
f010409a:	e8 3b fc ff ff       	call   f0103cda <getuint>
			base = 16;
f010409f:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01040a4:	83 ec 0c             	sub    $0xc,%esp
f01040a7:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01040ab:	57                   	push   %edi
f01040ac:	ff 75 e0             	pushl  -0x20(%ebp)
f01040af:	51                   	push   %ecx
f01040b0:	52                   	push   %edx
f01040b1:	50                   	push   %eax
f01040b2:	89 da                	mov    %ebx,%edx
f01040b4:	89 f0                	mov    %esi,%eax
f01040b6:	e8 70 fb ff ff       	call   f0103c2b <printnum>
			break;
f01040bb:	83 c4 20             	add    $0x20,%esp
f01040be:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040c1:	e9 ae fc ff ff       	jmp    f0103d74 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01040c6:	83 ec 08             	sub    $0x8,%esp
f01040c9:	53                   	push   %ebx
f01040ca:	51                   	push   %ecx
f01040cb:	ff d6                	call   *%esi
			break;
f01040cd:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01040d3:	e9 9c fc ff ff       	jmp    f0103d74 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01040d8:	83 ec 08             	sub    $0x8,%esp
f01040db:	53                   	push   %ebx
f01040dc:	6a 25                	push   $0x25
f01040de:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01040e0:	83 c4 10             	add    $0x10,%esp
f01040e3:	eb 03                	jmp    f01040e8 <vprintfmt+0x39a>
f01040e5:	83 ef 01             	sub    $0x1,%edi
f01040e8:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01040ec:	75 f7                	jne    f01040e5 <vprintfmt+0x397>
f01040ee:	e9 81 fc ff ff       	jmp    f0103d74 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01040f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040f6:	5b                   	pop    %ebx
f01040f7:	5e                   	pop    %esi
f01040f8:	5f                   	pop    %edi
f01040f9:	5d                   	pop    %ebp
f01040fa:	c3                   	ret    

f01040fb <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01040fb:	55                   	push   %ebp
f01040fc:	89 e5                	mov    %esp,%ebp
f01040fe:	83 ec 18             	sub    $0x18,%esp
f0104101:	8b 45 08             	mov    0x8(%ebp),%eax
f0104104:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104107:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010410a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010410e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104111:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104118:	85 c0                	test   %eax,%eax
f010411a:	74 26                	je     f0104142 <vsnprintf+0x47>
f010411c:	85 d2                	test   %edx,%edx
f010411e:	7e 22                	jle    f0104142 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104120:	ff 75 14             	pushl  0x14(%ebp)
f0104123:	ff 75 10             	pushl  0x10(%ebp)
f0104126:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104129:	50                   	push   %eax
f010412a:	68 14 3d 10 f0       	push   $0xf0103d14
f010412f:	e8 1a fc ff ff       	call   f0103d4e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104134:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104137:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010413a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010413d:	83 c4 10             	add    $0x10,%esp
f0104140:	eb 05                	jmp    f0104147 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104142:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104147:	c9                   	leave  
f0104148:	c3                   	ret    

f0104149 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104149:	55                   	push   %ebp
f010414a:	89 e5                	mov    %esp,%ebp
f010414c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010414f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104152:	50                   	push   %eax
f0104153:	ff 75 10             	pushl  0x10(%ebp)
f0104156:	ff 75 0c             	pushl  0xc(%ebp)
f0104159:	ff 75 08             	pushl  0x8(%ebp)
f010415c:	e8 9a ff ff ff       	call   f01040fb <vsnprintf>
	va_end(ap);

	return rc;
}
f0104161:	c9                   	leave  
f0104162:	c3                   	ret    

f0104163 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104163:	55                   	push   %ebp
f0104164:	89 e5                	mov    %esp,%ebp
f0104166:	57                   	push   %edi
f0104167:	56                   	push   %esi
f0104168:	53                   	push   %ebx
f0104169:	83 ec 0c             	sub    $0xc,%esp
f010416c:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010416f:	85 c0                	test   %eax,%eax
f0104171:	74 11                	je     f0104184 <readline+0x21>
		cprintf("%s", prompt);
f0104173:	83 ec 08             	sub    $0x8,%esp
f0104176:	50                   	push   %eax
f0104177:	68 ff 55 10 f0       	push   $0xf01055ff
f010417c:	e8 67 ee ff ff       	call   f0102fe8 <cprintf>
f0104181:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104184:	83 ec 0c             	sub    $0xc,%esp
f0104187:	6a 00                	push   $0x0
f0104189:	e8 a8 c4 ff ff       	call   f0100636 <iscons>
f010418e:	89 c7                	mov    %eax,%edi
f0104190:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104193:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104198:	e8 88 c4 ff ff       	call   f0100625 <getchar>
f010419d:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010419f:	85 c0                	test   %eax,%eax
f01041a1:	79 18                	jns    f01041bb <readline+0x58>
			cprintf("read error: %e\n", c);
f01041a3:	83 ec 08             	sub    $0x8,%esp
f01041a6:	50                   	push   %eax
f01041a7:	68 b0 5f 10 f0       	push   $0xf0105fb0
f01041ac:	e8 37 ee ff ff       	call   f0102fe8 <cprintf>
			return NULL;
f01041b1:	83 c4 10             	add    $0x10,%esp
f01041b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01041b9:	eb 79                	jmp    f0104234 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01041bb:	83 f8 08             	cmp    $0x8,%eax
f01041be:	0f 94 c2             	sete   %dl
f01041c1:	83 f8 7f             	cmp    $0x7f,%eax
f01041c4:	0f 94 c0             	sete   %al
f01041c7:	08 c2                	or     %al,%dl
f01041c9:	74 1a                	je     f01041e5 <readline+0x82>
f01041cb:	85 f6                	test   %esi,%esi
f01041cd:	7e 16                	jle    f01041e5 <readline+0x82>
			if (echoing)
f01041cf:	85 ff                	test   %edi,%edi
f01041d1:	74 0d                	je     f01041e0 <readline+0x7d>
				cputchar('\b');
f01041d3:	83 ec 0c             	sub    $0xc,%esp
f01041d6:	6a 08                	push   $0x8
f01041d8:	e8 38 c4 ff ff       	call   f0100615 <cputchar>
f01041dd:	83 c4 10             	add    $0x10,%esp
			i--;
f01041e0:	83 ee 01             	sub    $0x1,%esi
f01041e3:	eb b3                	jmp    f0104198 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01041e5:	83 fb 1f             	cmp    $0x1f,%ebx
f01041e8:	7e 23                	jle    f010420d <readline+0xaa>
f01041ea:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01041f0:	7f 1b                	jg     f010420d <readline+0xaa>
			if (echoing)
f01041f2:	85 ff                	test   %edi,%edi
f01041f4:	74 0c                	je     f0104202 <readline+0x9f>
				cputchar(c);
f01041f6:	83 ec 0c             	sub    $0xc,%esp
f01041f9:	53                   	push   %ebx
f01041fa:	e8 16 c4 ff ff       	call   f0100615 <cputchar>
f01041ff:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104202:	88 9e 40 28 17 f0    	mov    %bl,-0xfe8d7c0(%esi)
f0104208:	8d 76 01             	lea    0x1(%esi),%esi
f010420b:	eb 8b                	jmp    f0104198 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010420d:	83 fb 0a             	cmp    $0xa,%ebx
f0104210:	74 05                	je     f0104217 <readline+0xb4>
f0104212:	83 fb 0d             	cmp    $0xd,%ebx
f0104215:	75 81                	jne    f0104198 <readline+0x35>
			if (echoing)
f0104217:	85 ff                	test   %edi,%edi
f0104219:	74 0d                	je     f0104228 <readline+0xc5>
				cputchar('\n');
f010421b:	83 ec 0c             	sub    $0xc,%esp
f010421e:	6a 0a                	push   $0xa
f0104220:	e8 f0 c3 ff ff       	call   f0100615 <cputchar>
f0104225:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104228:	c6 86 40 28 17 f0 00 	movb   $0x0,-0xfe8d7c0(%esi)
			return buf;
f010422f:	b8 40 28 17 f0       	mov    $0xf0172840,%eax
		}
	}
}
f0104234:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104237:	5b                   	pop    %ebx
f0104238:	5e                   	pop    %esi
f0104239:	5f                   	pop    %edi
f010423a:	5d                   	pop    %ebp
f010423b:	c3                   	ret    

f010423c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010423c:	55                   	push   %ebp
f010423d:	89 e5                	mov    %esp,%ebp
f010423f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104242:	b8 00 00 00 00       	mov    $0x0,%eax
f0104247:	eb 03                	jmp    f010424c <strlen+0x10>
		n++;
f0104249:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010424c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104250:	75 f7                	jne    f0104249 <strlen+0xd>
		n++;
	return n;
}
f0104252:	5d                   	pop    %ebp
f0104253:	c3                   	ret    

f0104254 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104254:	55                   	push   %ebp
f0104255:	89 e5                	mov    %esp,%ebp
f0104257:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010425a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010425d:	ba 00 00 00 00       	mov    $0x0,%edx
f0104262:	eb 03                	jmp    f0104267 <strnlen+0x13>
		n++;
f0104264:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104267:	39 c2                	cmp    %eax,%edx
f0104269:	74 08                	je     f0104273 <strnlen+0x1f>
f010426b:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010426f:	75 f3                	jne    f0104264 <strnlen+0x10>
f0104271:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104273:	5d                   	pop    %ebp
f0104274:	c3                   	ret    

f0104275 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104275:	55                   	push   %ebp
f0104276:	89 e5                	mov    %esp,%ebp
f0104278:	53                   	push   %ebx
f0104279:	8b 45 08             	mov    0x8(%ebp),%eax
f010427c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010427f:	89 c2                	mov    %eax,%edx
f0104281:	83 c2 01             	add    $0x1,%edx
f0104284:	83 c1 01             	add    $0x1,%ecx
f0104287:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010428b:	88 5a ff             	mov    %bl,-0x1(%edx)
f010428e:	84 db                	test   %bl,%bl
f0104290:	75 ef                	jne    f0104281 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104292:	5b                   	pop    %ebx
f0104293:	5d                   	pop    %ebp
f0104294:	c3                   	ret    

f0104295 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104295:	55                   	push   %ebp
f0104296:	89 e5                	mov    %esp,%ebp
f0104298:	53                   	push   %ebx
f0104299:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010429c:	53                   	push   %ebx
f010429d:	e8 9a ff ff ff       	call   f010423c <strlen>
f01042a2:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01042a5:	ff 75 0c             	pushl  0xc(%ebp)
f01042a8:	01 d8                	add    %ebx,%eax
f01042aa:	50                   	push   %eax
f01042ab:	e8 c5 ff ff ff       	call   f0104275 <strcpy>
	return dst;
}
f01042b0:	89 d8                	mov    %ebx,%eax
f01042b2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042b5:	c9                   	leave  
f01042b6:	c3                   	ret    

f01042b7 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01042b7:	55                   	push   %ebp
f01042b8:	89 e5                	mov    %esp,%ebp
f01042ba:	56                   	push   %esi
f01042bb:	53                   	push   %ebx
f01042bc:	8b 75 08             	mov    0x8(%ebp),%esi
f01042bf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01042c2:	89 f3                	mov    %esi,%ebx
f01042c4:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01042c7:	89 f2                	mov    %esi,%edx
f01042c9:	eb 0f                	jmp    f01042da <strncpy+0x23>
		*dst++ = *src;
f01042cb:	83 c2 01             	add    $0x1,%edx
f01042ce:	0f b6 01             	movzbl (%ecx),%eax
f01042d1:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01042d4:	80 39 01             	cmpb   $0x1,(%ecx)
f01042d7:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01042da:	39 da                	cmp    %ebx,%edx
f01042dc:	75 ed                	jne    f01042cb <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01042de:	89 f0                	mov    %esi,%eax
f01042e0:	5b                   	pop    %ebx
f01042e1:	5e                   	pop    %esi
f01042e2:	5d                   	pop    %ebp
f01042e3:	c3                   	ret    

f01042e4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01042e4:	55                   	push   %ebp
f01042e5:	89 e5                	mov    %esp,%ebp
f01042e7:	56                   	push   %esi
f01042e8:	53                   	push   %ebx
f01042e9:	8b 75 08             	mov    0x8(%ebp),%esi
f01042ec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01042ef:	8b 55 10             	mov    0x10(%ebp),%edx
f01042f2:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01042f4:	85 d2                	test   %edx,%edx
f01042f6:	74 21                	je     f0104319 <strlcpy+0x35>
f01042f8:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01042fc:	89 f2                	mov    %esi,%edx
f01042fe:	eb 09                	jmp    f0104309 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104300:	83 c2 01             	add    $0x1,%edx
f0104303:	83 c1 01             	add    $0x1,%ecx
f0104306:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104309:	39 c2                	cmp    %eax,%edx
f010430b:	74 09                	je     f0104316 <strlcpy+0x32>
f010430d:	0f b6 19             	movzbl (%ecx),%ebx
f0104310:	84 db                	test   %bl,%bl
f0104312:	75 ec                	jne    f0104300 <strlcpy+0x1c>
f0104314:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104316:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104319:	29 f0                	sub    %esi,%eax
}
f010431b:	5b                   	pop    %ebx
f010431c:	5e                   	pop    %esi
f010431d:	5d                   	pop    %ebp
f010431e:	c3                   	ret    

f010431f <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010431f:	55                   	push   %ebp
f0104320:	89 e5                	mov    %esp,%ebp
f0104322:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104325:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104328:	eb 06                	jmp    f0104330 <strcmp+0x11>
		p++, q++;
f010432a:	83 c1 01             	add    $0x1,%ecx
f010432d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104330:	0f b6 01             	movzbl (%ecx),%eax
f0104333:	84 c0                	test   %al,%al
f0104335:	74 04                	je     f010433b <strcmp+0x1c>
f0104337:	3a 02                	cmp    (%edx),%al
f0104339:	74 ef                	je     f010432a <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010433b:	0f b6 c0             	movzbl %al,%eax
f010433e:	0f b6 12             	movzbl (%edx),%edx
f0104341:	29 d0                	sub    %edx,%eax
}
f0104343:	5d                   	pop    %ebp
f0104344:	c3                   	ret    

f0104345 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104345:	55                   	push   %ebp
f0104346:	89 e5                	mov    %esp,%ebp
f0104348:	53                   	push   %ebx
f0104349:	8b 45 08             	mov    0x8(%ebp),%eax
f010434c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010434f:	89 c3                	mov    %eax,%ebx
f0104351:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104354:	eb 06                	jmp    f010435c <strncmp+0x17>
		n--, p++, q++;
f0104356:	83 c0 01             	add    $0x1,%eax
f0104359:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010435c:	39 d8                	cmp    %ebx,%eax
f010435e:	74 15                	je     f0104375 <strncmp+0x30>
f0104360:	0f b6 08             	movzbl (%eax),%ecx
f0104363:	84 c9                	test   %cl,%cl
f0104365:	74 04                	je     f010436b <strncmp+0x26>
f0104367:	3a 0a                	cmp    (%edx),%cl
f0104369:	74 eb                	je     f0104356 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010436b:	0f b6 00             	movzbl (%eax),%eax
f010436e:	0f b6 12             	movzbl (%edx),%edx
f0104371:	29 d0                	sub    %edx,%eax
f0104373:	eb 05                	jmp    f010437a <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104375:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010437a:	5b                   	pop    %ebx
f010437b:	5d                   	pop    %ebp
f010437c:	c3                   	ret    

f010437d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010437d:	55                   	push   %ebp
f010437e:	89 e5                	mov    %esp,%ebp
f0104380:	8b 45 08             	mov    0x8(%ebp),%eax
f0104383:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104387:	eb 07                	jmp    f0104390 <strchr+0x13>
		if (*s == c)
f0104389:	38 ca                	cmp    %cl,%dl
f010438b:	74 0f                	je     f010439c <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010438d:	83 c0 01             	add    $0x1,%eax
f0104390:	0f b6 10             	movzbl (%eax),%edx
f0104393:	84 d2                	test   %dl,%dl
f0104395:	75 f2                	jne    f0104389 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104397:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010439c:	5d                   	pop    %ebp
f010439d:	c3                   	ret    

f010439e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010439e:	55                   	push   %ebp
f010439f:	89 e5                	mov    %esp,%ebp
f01043a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01043a4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01043a8:	eb 03                	jmp    f01043ad <strfind+0xf>
f01043aa:	83 c0 01             	add    $0x1,%eax
f01043ad:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01043b0:	38 ca                	cmp    %cl,%dl
f01043b2:	74 04                	je     f01043b8 <strfind+0x1a>
f01043b4:	84 d2                	test   %dl,%dl
f01043b6:	75 f2                	jne    f01043aa <strfind+0xc>
			break;
	return (char *) s;
}
f01043b8:	5d                   	pop    %ebp
f01043b9:	c3                   	ret    

f01043ba <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01043ba:	55                   	push   %ebp
f01043bb:	89 e5                	mov    %esp,%ebp
f01043bd:	57                   	push   %edi
f01043be:	56                   	push   %esi
f01043bf:	53                   	push   %ebx
f01043c0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01043c3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01043c6:	85 c9                	test   %ecx,%ecx
f01043c8:	74 36                	je     f0104400 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01043ca:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01043d0:	75 28                	jne    f01043fa <memset+0x40>
f01043d2:	f6 c1 03             	test   $0x3,%cl
f01043d5:	75 23                	jne    f01043fa <memset+0x40>
		c &= 0xFF;
f01043d7:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01043db:	89 d3                	mov    %edx,%ebx
f01043dd:	c1 e3 08             	shl    $0x8,%ebx
f01043e0:	89 d6                	mov    %edx,%esi
f01043e2:	c1 e6 18             	shl    $0x18,%esi
f01043e5:	89 d0                	mov    %edx,%eax
f01043e7:	c1 e0 10             	shl    $0x10,%eax
f01043ea:	09 f0                	or     %esi,%eax
f01043ec:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01043ee:	89 d8                	mov    %ebx,%eax
f01043f0:	09 d0                	or     %edx,%eax
f01043f2:	c1 e9 02             	shr    $0x2,%ecx
f01043f5:	fc                   	cld    
f01043f6:	f3 ab                	rep stos %eax,%es:(%edi)
f01043f8:	eb 06                	jmp    f0104400 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01043fa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043fd:	fc                   	cld    
f01043fe:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104400:	89 f8                	mov    %edi,%eax
f0104402:	5b                   	pop    %ebx
f0104403:	5e                   	pop    %esi
f0104404:	5f                   	pop    %edi
f0104405:	5d                   	pop    %ebp
f0104406:	c3                   	ret    

f0104407 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104407:	55                   	push   %ebp
f0104408:	89 e5                	mov    %esp,%ebp
f010440a:	57                   	push   %edi
f010440b:	56                   	push   %esi
f010440c:	8b 45 08             	mov    0x8(%ebp),%eax
f010440f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104412:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104415:	39 c6                	cmp    %eax,%esi
f0104417:	73 35                	jae    f010444e <memmove+0x47>
f0104419:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010441c:	39 d0                	cmp    %edx,%eax
f010441e:	73 2e                	jae    f010444e <memmove+0x47>
		s += n;
		d += n;
f0104420:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104423:	89 d6                	mov    %edx,%esi
f0104425:	09 fe                	or     %edi,%esi
f0104427:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010442d:	75 13                	jne    f0104442 <memmove+0x3b>
f010442f:	f6 c1 03             	test   $0x3,%cl
f0104432:	75 0e                	jne    f0104442 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104434:	83 ef 04             	sub    $0x4,%edi
f0104437:	8d 72 fc             	lea    -0x4(%edx),%esi
f010443a:	c1 e9 02             	shr    $0x2,%ecx
f010443d:	fd                   	std    
f010443e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104440:	eb 09                	jmp    f010444b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104442:	83 ef 01             	sub    $0x1,%edi
f0104445:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104448:	fd                   	std    
f0104449:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010444b:	fc                   	cld    
f010444c:	eb 1d                	jmp    f010446b <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010444e:	89 f2                	mov    %esi,%edx
f0104450:	09 c2                	or     %eax,%edx
f0104452:	f6 c2 03             	test   $0x3,%dl
f0104455:	75 0f                	jne    f0104466 <memmove+0x5f>
f0104457:	f6 c1 03             	test   $0x3,%cl
f010445a:	75 0a                	jne    f0104466 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010445c:	c1 e9 02             	shr    $0x2,%ecx
f010445f:	89 c7                	mov    %eax,%edi
f0104461:	fc                   	cld    
f0104462:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104464:	eb 05                	jmp    f010446b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104466:	89 c7                	mov    %eax,%edi
f0104468:	fc                   	cld    
f0104469:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010446b:	5e                   	pop    %esi
f010446c:	5f                   	pop    %edi
f010446d:	5d                   	pop    %ebp
f010446e:	c3                   	ret    

f010446f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010446f:	55                   	push   %ebp
f0104470:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104472:	ff 75 10             	pushl  0x10(%ebp)
f0104475:	ff 75 0c             	pushl  0xc(%ebp)
f0104478:	ff 75 08             	pushl  0x8(%ebp)
f010447b:	e8 87 ff ff ff       	call   f0104407 <memmove>
}
f0104480:	c9                   	leave  
f0104481:	c3                   	ret    

f0104482 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104482:	55                   	push   %ebp
f0104483:	89 e5                	mov    %esp,%ebp
f0104485:	56                   	push   %esi
f0104486:	53                   	push   %ebx
f0104487:	8b 45 08             	mov    0x8(%ebp),%eax
f010448a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010448d:	89 c6                	mov    %eax,%esi
f010448f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104492:	eb 1a                	jmp    f01044ae <memcmp+0x2c>
		if (*s1 != *s2)
f0104494:	0f b6 08             	movzbl (%eax),%ecx
f0104497:	0f b6 1a             	movzbl (%edx),%ebx
f010449a:	38 d9                	cmp    %bl,%cl
f010449c:	74 0a                	je     f01044a8 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010449e:	0f b6 c1             	movzbl %cl,%eax
f01044a1:	0f b6 db             	movzbl %bl,%ebx
f01044a4:	29 d8                	sub    %ebx,%eax
f01044a6:	eb 0f                	jmp    f01044b7 <memcmp+0x35>
		s1++, s2++;
f01044a8:	83 c0 01             	add    $0x1,%eax
f01044ab:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01044ae:	39 f0                	cmp    %esi,%eax
f01044b0:	75 e2                	jne    f0104494 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01044b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01044b7:	5b                   	pop    %ebx
f01044b8:	5e                   	pop    %esi
f01044b9:	5d                   	pop    %ebp
f01044ba:	c3                   	ret    

f01044bb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01044bb:	55                   	push   %ebp
f01044bc:	89 e5                	mov    %esp,%ebp
f01044be:	53                   	push   %ebx
f01044bf:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01044c2:	89 c1                	mov    %eax,%ecx
f01044c4:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01044c7:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01044cb:	eb 0a                	jmp    f01044d7 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01044cd:	0f b6 10             	movzbl (%eax),%edx
f01044d0:	39 da                	cmp    %ebx,%edx
f01044d2:	74 07                	je     f01044db <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01044d4:	83 c0 01             	add    $0x1,%eax
f01044d7:	39 c8                	cmp    %ecx,%eax
f01044d9:	72 f2                	jb     f01044cd <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01044db:	5b                   	pop    %ebx
f01044dc:	5d                   	pop    %ebp
f01044dd:	c3                   	ret    

f01044de <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01044de:	55                   	push   %ebp
f01044df:	89 e5                	mov    %esp,%ebp
f01044e1:	57                   	push   %edi
f01044e2:	56                   	push   %esi
f01044e3:	53                   	push   %ebx
f01044e4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01044e7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01044ea:	eb 03                	jmp    f01044ef <strtol+0x11>
		s++;
f01044ec:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01044ef:	0f b6 01             	movzbl (%ecx),%eax
f01044f2:	3c 20                	cmp    $0x20,%al
f01044f4:	74 f6                	je     f01044ec <strtol+0xe>
f01044f6:	3c 09                	cmp    $0x9,%al
f01044f8:	74 f2                	je     f01044ec <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01044fa:	3c 2b                	cmp    $0x2b,%al
f01044fc:	75 0a                	jne    f0104508 <strtol+0x2a>
		s++;
f01044fe:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104501:	bf 00 00 00 00       	mov    $0x0,%edi
f0104506:	eb 11                	jmp    f0104519 <strtol+0x3b>
f0104508:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010450d:	3c 2d                	cmp    $0x2d,%al
f010450f:	75 08                	jne    f0104519 <strtol+0x3b>
		s++, neg = 1;
f0104511:	83 c1 01             	add    $0x1,%ecx
f0104514:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104519:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010451f:	75 15                	jne    f0104536 <strtol+0x58>
f0104521:	80 39 30             	cmpb   $0x30,(%ecx)
f0104524:	75 10                	jne    f0104536 <strtol+0x58>
f0104526:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010452a:	75 7c                	jne    f01045a8 <strtol+0xca>
		s += 2, base = 16;
f010452c:	83 c1 02             	add    $0x2,%ecx
f010452f:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104534:	eb 16                	jmp    f010454c <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104536:	85 db                	test   %ebx,%ebx
f0104538:	75 12                	jne    f010454c <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010453a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010453f:	80 39 30             	cmpb   $0x30,(%ecx)
f0104542:	75 08                	jne    f010454c <strtol+0x6e>
		s++, base = 8;
f0104544:	83 c1 01             	add    $0x1,%ecx
f0104547:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010454c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104551:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104554:	0f b6 11             	movzbl (%ecx),%edx
f0104557:	8d 72 d0             	lea    -0x30(%edx),%esi
f010455a:	89 f3                	mov    %esi,%ebx
f010455c:	80 fb 09             	cmp    $0x9,%bl
f010455f:	77 08                	ja     f0104569 <strtol+0x8b>
			dig = *s - '0';
f0104561:	0f be d2             	movsbl %dl,%edx
f0104564:	83 ea 30             	sub    $0x30,%edx
f0104567:	eb 22                	jmp    f010458b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104569:	8d 72 9f             	lea    -0x61(%edx),%esi
f010456c:	89 f3                	mov    %esi,%ebx
f010456e:	80 fb 19             	cmp    $0x19,%bl
f0104571:	77 08                	ja     f010457b <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104573:	0f be d2             	movsbl %dl,%edx
f0104576:	83 ea 57             	sub    $0x57,%edx
f0104579:	eb 10                	jmp    f010458b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010457b:	8d 72 bf             	lea    -0x41(%edx),%esi
f010457e:	89 f3                	mov    %esi,%ebx
f0104580:	80 fb 19             	cmp    $0x19,%bl
f0104583:	77 16                	ja     f010459b <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104585:	0f be d2             	movsbl %dl,%edx
f0104588:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010458b:	3b 55 10             	cmp    0x10(%ebp),%edx
f010458e:	7d 0b                	jge    f010459b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104590:	83 c1 01             	add    $0x1,%ecx
f0104593:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104597:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104599:	eb b9                	jmp    f0104554 <strtol+0x76>

	if (endptr)
f010459b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010459f:	74 0d                	je     f01045ae <strtol+0xd0>
		*endptr = (char *) s;
f01045a1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01045a4:	89 0e                	mov    %ecx,(%esi)
f01045a6:	eb 06                	jmp    f01045ae <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01045a8:	85 db                	test   %ebx,%ebx
f01045aa:	74 98                	je     f0104544 <strtol+0x66>
f01045ac:	eb 9e                	jmp    f010454c <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01045ae:	89 c2                	mov    %eax,%edx
f01045b0:	f7 da                	neg    %edx
f01045b2:	85 ff                	test   %edi,%edi
f01045b4:	0f 45 c2             	cmovne %edx,%eax
}
f01045b7:	5b                   	pop    %ebx
f01045b8:	5e                   	pop    %esi
f01045b9:	5f                   	pop    %edi
f01045ba:	5d                   	pop    %ebp
f01045bb:	c3                   	ret    
f01045bc:	66 90                	xchg   %ax,%ax
f01045be:	66 90                	xchg   %ax,%ax

f01045c0 <__udivdi3>:
f01045c0:	55                   	push   %ebp
f01045c1:	57                   	push   %edi
f01045c2:	56                   	push   %esi
f01045c3:	53                   	push   %ebx
f01045c4:	83 ec 1c             	sub    $0x1c,%esp
f01045c7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01045cb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01045cf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01045d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01045d7:	85 f6                	test   %esi,%esi
f01045d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01045dd:	89 ca                	mov    %ecx,%edx
f01045df:	89 f8                	mov    %edi,%eax
f01045e1:	75 3d                	jne    f0104620 <__udivdi3+0x60>
f01045e3:	39 cf                	cmp    %ecx,%edi
f01045e5:	0f 87 c5 00 00 00    	ja     f01046b0 <__udivdi3+0xf0>
f01045eb:	85 ff                	test   %edi,%edi
f01045ed:	89 fd                	mov    %edi,%ebp
f01045ef:	75 0b                	jne    f01045fc <__udivdi3+0x3c>
f01045f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01045f6:	31 d2                	xor    %edx,%edx
f01045f8:	f7 f7                	div    %edi
f01045fa:	89 c5                	mov    %eax,%ebp
f01045fc:	89 c8                	mov    %ecx,%eax
f01045fe:	31 d2                	xor    %edx,%edx
f0104600:	f7 f5                	div    %ebp
f0104602:	89 c1                	mov    %eax,%ecx
f0104604:	89 d8                	mov    %ebx,%eax
f0104606:	89 cf                	mov    %ecx,%edi
f0104608:	f7 f5                	div    %ebp
f010460a:	89 c3                	mov    %eax,%ebx
f010460c:	89 d8                	mov    %ebx,%eax
f010460e:	89 fa                	mov    %edi,%edx
f0104610:	83 c4 1c             	add    $0x1c,%esp
f0104613:	5b                   	pop    %ebx
f0104614:	5e                   	pop    %esi
f0104615:	5f                   	pop    %edi
f0104616:	5d                   	pop    %ebp
f0104617:	c3                   	ret    
f0104618:	90                   	nop
f0104619:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104620:	39 ce                	cmp    %ecx,%esi
f0104622:	77 74                	ja     f0104698 <__udivdi3+0xd8>
f0104624:	0f bd fe             	bsr    %esi,%edi
f0104627:	83 f7 1f             	xor    $0x1f,%edi
f010462a:	0f 84 98 00 00 00    	je     f01046c8 <__udivdi3+0x108>
f0104630:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104635:	89 f9                	mov    %edi,%ecx
f0104637:	89 c5                	mov    %eax,%ebp
f0104639:	29 fb                	sub    %edi,%ebx
f010463b:	d3 e6                	shl    %cl,%esi
f010463d:	89 d9                	mov    %ebx,%ecx
f010463f:	d3 ed                	shr    %cl,%ebp
f0104641:	89 f9                	mov    %edi,%ecx
f0104643:	d3 e0                	shl    %cl,%eax
f0104645:	09 ee                	or     %ebp,%esi
f0104647:	89 d9                	mov    %ebx,%ecx
f0104649:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010464d:	89 d5                	mov    %edx,%ebp
f010464f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104653:	d3 ed                	shr    %cl,%ebp
f0104655:	89 f9                	mov    %edi,%ecx
f0104657:	d3 e2                	shl    %cl,%edx
f0104659:	89 d9                	mov    %ebx,%ecx
f010465b:	d3 e8                	shr    %cl,%eax
f010465d:	09 c2                	or     %eax,%edx
f010465f:	89 d0                	mov    %edx,%eax
f0104661:	89 ea                	mov    %ebp,%edx
f0104663:	f7 f6                	div    %esi
f0104665:	89 d5                	mov    %edx,%ebp
f0104667:	89 c3                	mov    %eax,%ebx
f0104669:	f7 64 24 0c          	mull   0xc(%esp)
f010466d:	39 d5                	cmp    %edx,%ebp
f010466f:	72 10                	jb     f0104681 <__udivdi3+0xc1>
f0104671:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104675:	89 f9                	mov    %edi,%ecx
f0104677:	d3 e6                	shl    %cl,%esi
f0104679:	39 c6                	cmp    %eax,%esi
f010467b:	73 07                	jae    f0104684 <__udivdi3+0xc4>
f010467d:	39 d5                	cmp    %edx,%ebp
f010467f:	75 03                	jne    f0104684 <__udivdi3+0xc4>
f0104681:	83 eb 01             	sub    $0x1,%ebx
f0104684:	31 ff                	xor    %edi,%edi
f0104686:	89 d8                	mov    %ebx,%eax
f0104688:	89 fa                	mov    %edi,%edx
f010468a:	83 c4 1c             	add    $0x1c,%esp
f010468d:	5b                   	pop    %ebx
f010468e:	5e                   	pop    %esi
f010468f:	5f                   	pop    %edi
f0104690:	5d                   	pop    %ebp
f0104691:	c3                   	ret    
f0104692:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104698:	31 ff                	xor    %edi,%edi
f010469a:	31 db                	xor    %ebx,%ebx
f010469c:	89 d8                	mov    %ebx,%eax
f010469e:	89 fa                	mov    %edi,%edx
f01046a0:	83 c4 1c             	add    $0x1c,%esp
f01046a3:	5b                   	pop    %ebx
f01046a4:	5e                   	pop    %esi
f01046a5:	5f                   	pop    %edi
f01046a6:	5d                   	pop    %ebp
f01046a7:	c3                   	ret    
f01046a8:	90                   	nop
f01046a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01046b0:	89 d8                	mov    %ebx,%eax
f01046b2:	f7 f7                	div    %edi
f01046b4:	31 ff                	xor    %edi,%edi
f01046b6:	89 c3                	mov    %eax,%ebx
f01046b8:	89 d8                	mov    %ebx,%eax
f01046ba:	89 fa                	mov    %edi,%edx
f01046bc:	83 c4 1c             	add    $0x1c,%esp
f01046bf:	5b                   	pop    %ebx
f01046c0:	5e                   	pop    %esi
f01046c1:	5f                   	pop    %edi
f01046c2:	5d                   	pop    %ebp
f01046c3:	c3                   	ret    
f01046c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01046c8:	39 ce                	cmp    %ecx,%esi
f01046ca:	72 0c                	jb     f01046d8 <__udivdi3+0x118>
f01046cc:	31 db                	xor    %ebx,%ebx
f01046ce:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01046d2:	0f 87 34 ff ff ff    	ja     f010460c <__udivdi3+0x4c>
f01046d8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01046dd:	e9 2a ff ff ff       	jmp    f010460c <__udivdi3+0x4c>
f01046e2:	66 90                	xchg   %ax,%ax
f01046e4:	66 90                	xchg   %ax,%ax
f01046e6:	66 90                	xchg   %ax,%ax
f01046e8:	66 90                	xchg   %ax,%ax
f01046ea:	66 90                	xchg   %ax,%ax
f01046ec:	66 90                	xchg   %ax,%ax
f01046ee:	66 90                	xchg   %ax,%ax

f01046f0 <__umoddi3>:
f01046f0:	55                   	push   %ebp
f01046f1:	57                   	push   %edi
f01046f2:	56                   	push   %esi
f01046f3:	53                   	push   %ebx
f01046f4:	83 ec 1c             	sub    $0x1c,%esp
f01046f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01046fb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01046ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104703:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104707:	85 d2                	test   %edx,%edx
f0104709:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010470d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104711:	89 f3                	mov    %esi,%ebx
f0104713:	89 3c 24             	mov    %edi,(%esp)
f0104716:	89 74 24 04          	mov    %esi,0x4(%esp)
f010471a:	75 1c                	jne    f0104738 <__umoddi3+0x48>
f010471c:	39 f7                	cmp    %esi,%edi
f010471e:	76 50                	jbe    f0104770 <__umoddi3+0x80>
f0104720:	89 c8                	mov    %ecx,%eax
f0104722:	89 f2                	mov    %esi,%edx
f0104724:	f7 f7                	div    %edi
f0104726:	89 d0                	mov    %edx,%eax
f0104728:	31 d2                	xor    %edx,%edx
f010472a:	83 c4 1c             	add    $0x1c,%esp
f010472d:	5b                   	pop    %ebx
f010472e:	5e                   	pop    %esi
f010472f:	5f                   	pop    %edi
f0104730:	5d                   	pop    %ebp
f0104731:	c3                   	ret    
f0104732:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104738:	39 f2                	cmp    %esi,%edx
f010473a:	89 d0                	mov    %edx,%eax
f010473c:	77 52                	ja     f0104790 <__umoddi3+0xa0>
f010473e:	0f bd ea             	bsr    %edx,%ebp
f0104741:	83 f5 1f             	xor    $0x1f,%ebp
f0104744:	75 5a                	jne    f01047a0 <__umoddi3+0xb0>
f0104746:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010474a:	0f 82 e0 00 00 00    	jb     f0104830 <__umoddi3+0x140>
f0104750:	39 0c 24             	cmp    %ecx,(%esp)
f0104753:	0f 86 d7 00 00 00    	jbe    f0104830 <__umoddi3+0x140>
f0104759:	8b 44 24 08          	mov    0x8(%esp),%eax
f010475d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104761:	83 c4 1c             	add    $0x1c,%esp
f0104764:	5b                   	pop    %ebx
f0104765:	5e                   	pop    %esi
f0104766:	5f                   	pop    %edi
f0104767:	5d                   	pop    %ebp
f0104768:	c3                   	ret    
f0104769:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104770:	85 ff                	test   %edi,%edi
f0104772:	89 fd                	mov    %edi,%ebp
f0104774:	75 0b                	jne    f0104781 <__umoddi3+0x91>
f0104776:	b8 01 00 00 00       	mov    $0x1,%eax
f010477b:	31 d2                	xor    %edx,%edx
f010477d:	f7 f7                	div    %edi
f010477f:	89 c5                	mov    %eax,%ebp
f0104781:	89 f0                	mov    %esi,%eax
f0104783:	31 d2                	xor    %edx,%edx
f0104785:	f7 f5                	div    %ebp
f0104787:	89 c8                	mov    %ecx,%eax
f0104789:	f7 f5                	div    %ebp
f010478b:	89 d0                	mov    %edx,%eax
f010478d:	eb 99                	jmp    f0104728 <__umoddi3+0x38>
f010478f:	90                   	nop
f0104790:	89 c8                	mov    %ecx,%eax
f0104792:	89 f2                	mov    %esi,%edx
f0104794:	83 c4 1c             	add    $0x1c,%esp
f0104797:	5b                   	pop    %ebx
f0104798:	5e                   	pop    %esi
f0104799:	5f                   	pop    %edi
f010479a:	5d                   	pop    %ebp
f010479b:	c3                   	ret    
f010479c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01047a0:	8b 34 24             	mov    (%esp),%esi
f01047a3:	bf 20 00 00 00       	mov    $0x20,%edi
f01047a8:	89 e9                	mov    %ebp,%ecx
f01047aa:	29 ef                	sub    %ebp,%edi
f01047ac:	d3 e0                	shl    %cl,%eax
f01047ae:	89 f9                	mov    %edi,%ecx
f01047b0:	89 f2                	mov    %esi,%edx
f01047b2:	d3 ea                	shr    %cl,%edx
f01047b4:	89 e9                	mov    %ebp,%ecx
f01047b6:	09 c2                	or     %eax,%edx
f01047b8:	89 d8                	mov    %ebx,%eax
f01047ba:	89 14 24             	mov    %edx,(%esp)
f01047bd:	89 f2                	mov    %esi,%edx
f01047bf:	d3 e2                	shl    %cl,%edx
f01047c1:	89 f9                	mov    %edi,%ecx
f01047c3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01047c7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01047cb:	d3 e8                	shr    %cl,%eax
f01047cd:	89 e9                	mov    %ebp,%ecx
f01047cf:	89 c6                	mov    %eax,%esi
f01047d1:	d3 e3                	shl    %cl,%ebx
f01047d3:	89 f9                	mov    %edi,%ecx
f01047d5:	89 d0                	mov    %edx,%eax
f01047d7:	d3 e8                	shr    %cl,%eax
f01047d9:	89 e9                	mov    %ebp,%ecx
f01047db:	09 d8                	or     %ebx,%eax
f01047dd:	89 d3                	mov    %edx,%ebx
f01047df:	89 f2                	mov    %esi,%edx
f01047e1:	f7 34 24             	divl   (%esp)
f01047e4:	89 d6                	mov    %edx,%esi
f01047e6:	d3 e3                	shl    %cl,%ebx
f01047e8:	f7 64 24 04          	mull   0x4(%esp)
f01047ec:	39 d6                	cmp    %edx,%esi
f01047ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01047f2:	89 d1                	mov    %edx,%ecx
f01047f4:	89 c3                	mov    %eax,%ebx
f01047f6:	72 08                	jb     f0104800 <__umoddi3+0x110>
f01047f8:	75 11                	jne    f010480b <__umoddi3+0x11b>
f01047fa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01047fe:	73 0b                	jae    f010480b <__umoddi3+0x11b>
f0104800:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104804:	1b 14 24             	sbb    (%esp),%edx
f0104807:	89 d1                	mov    %edx,%ecx
f0104809:	89 c3                	mov    %eax,%ebx
f010480b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010480f:	29 da                	sub    %ebx,%edx
f0104811:	19 ce                	sbb    %ecx,%esi
f0104813:	89 f9                	mov    %edi,%ecx
f0104815:	89 f0                	mov    %esi,%eax
f0104817:	d3 e0                	shl    %cl,%eax
f0104819:	89 e9                	mov    %ebp,%ecx
f010481b:	d3 ea                	shr    %cl,%edx
f010481d:	89 e9                	mov    %ebp,%ecx
f010481f:	d3 ee                	shr    %cl,%esi
f0104821:	09 d0                	or     %edx,%eax
f0104823:	89 f2                	mov    %esi,%edx
f0104825:	83 c4 1c             	add    $0x1c,%esp
f0104828:	5b                   	pop    %ebx
f0104829:	5e                   	pop    %esi
f010482a:	5f                   	pop    %edi
f010482b:	5d                   	pop    %ebp
f010482c:	c3                   	ret    
f010482d:	8d 76 00             	lea    0x0(%esi),%esi
f0104830:	29 f9                	sub    %edi,%ecx
f0104832:	19 d6                	sbb    %edx,%esi
f0104834:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104838:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010483c:	e9 18 ff ff ff       	jmp    f0104759 <__umoddi3+0x69>
