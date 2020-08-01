import re
import gdb
import time
import math
import logging

logging.basicConfig(level=logging.INFO)
gdbLogger = logging.getLogger(name='GDB Logger')
resultsFN = 'build/results/test_out.txt'

def report(msg,*args,**kwargs):
    with open(resultsFN,'a') as f:
        ending = '\n' if 'end' not in kwargs else kwargs['end']
        f.write(f'{msg}{ending}')
    print(msg,*args,**kwargs)

def report(msg,*args,**kwargs):
    with open(resultsFN,'a') as f:
        ending = '\n' if 'end' not in kwargs else kwargs['end']
        f.write(f'{msg}{ending}')
    print(msg,*args,**kwargs)

class SyncCatch(gdb.Breakpoint):
    def __init__(self,avr,**kw):
        super(SyncCatch,self).__init__('TimerSet',temporary=True,*kw)
        self.avr = avr
        self.commands = 'silent'

    def stop(self):
        self.avr.period=gdb.newest_frame().read_var("M")
        gdbLogger.info(f'Running with user set period of {self.avr.period}')
        return True

class PortWatch(gdb.Breakpoint):
    def __init__(self,addr,mask=0xFF,**kw):
        super(PortWatch,self).__init__(f'*(char *) {hex(addr)}',type=gdb.BP_WATCHPOINT,internal=True,**kw)
        self.mask = mask
    def stop(self):
        print(f'Stop?')
        return True

class AVR:
    base=0x800000
    pins = { 'PINA': 0x20, 'PINB': 0x23, 'PINC': 0x26, 'PIND': 0x29 }
    ddrs = { 'DDRA': 0x21, 'DDRB': 0x24, 'DDRC': 0x27, 'DDRD': 0x2A }
    ports = { 'PORTA': 0x22, 'PORTB': 0x25, 'PORTC': 0x28, 'PORTD': 0x2B }
    registers = [pins,ddrs,ports]
    endian = 'big' #?
    def __init__(self,inf,while1,period=None):
        self.inferior = inf
        self.period = period
        self.pinMapping = {}
        self.bp = gdb.Breakpoint(source='main.c',line=while1)
        #self.bp.commands = '\n'.join(['silent']) #TODO: Verbosity?
        self.bp.enabled = True
        self.watchList = []

    def __str__(self):
        return self.inferior.architecture().name()

    def is_valid(self):
        return self.inferior.is_valid()

    def runForNIterations(self,n):
        self.bp.ignore_count = n-1
        gdb.execute(f'continue')
        self.bp.ignore_count = 0

    def runForNms(self,n):
        if self.period:
            self.runForNIterations(math.ceil(n/self.period))
        else:
            gdbLogger.warning(f'No known period, running for 1 iterations instead of {n} ms')
            self.runForNIterations(1)

    def runUntilPinChange(self,port,mask=0xFF):
        if port in self.pinMapping:
            mask = self.pinMapping[port][1]
            port = self.pinMapping[port][0]
        self.bp = PortWatch(port,mask,temporary=True)
        gdb.execute(f'continue')
        del self.bp

    def memoryToBits(self,offset):
        bits=8
        return list(format(int.from_bytes(self.inferior.read_memory(self.base+offset,1),
            byteorder=self.endian),f'0{bits}b'))

    def display(self):
        # TODO: Analog? PWM output? Can we tell if a pin is configured specially
        pina,porta = self.memoryToBits(self.pins['PINA']), self.memoryToBits(self.ports['PORTA'])
        pinb,portb = self.memoryToBits(self.pins['PINB']), self.memoryToBits(self.ports['PORTB'])
        pinc,portc = self.memoryToBits(self.pins['PINC']), self.memoryToBits(self.ports['PORTC'])
        pind,portd = self.memoryToBits(self.pins['PIND']), self.memoryToBits(self.ports['PORTD'])

        A = [(pina[i],'i') if d == '0' else (porta[i],'o') for i,d in 
                enumerate(self.memoryToBits(self.ddrs['DDRA']))]
        B = [(pinb[i],'i') if d == '0' else (portb[i],'o') for i,d in 
                enumerate(self.memoryToBits(self.ddrs['DDRB']))]
        C = [(pinc[i],'i') if d == '0' else (portc[i],'o') for i,d in 
                enumerate(self.memoryToBits(self.ddrs['DDRC']))]
        D = [(pind[i],'i') if d == '0' else (portd[i],'o') for i,d in 
                enumerate(self.memoryToBits(self.ddrs['DDRD']))]
        print(f' {"".join([v for v,_ in D[1:]])}     {"".join([v for v,_ in B])}')
        print(f' {"".join([d for _,d in D[1:]])}     {"".join([d for _,d in B])}')
        print(' --------------------')
        print('|6543210     76543210|')
        print('|                   c|')
        print('|701234567   76543210|')
        print(' --------------------')
        print(f' {D[0][1]}{"".join([d for _,d in C])}   {"".join([d for _,d in A])}')
        print(f' {D[0][0]}{"".join([v for v,_ in C])}   {"".join([v for v,_ in A])}')
        return

    def addWatch(self,watch):
        gdb.execute(f'display {watch}')
        self.watchList.append(watch)

    def mapPins(self,pinMapping):
        for alias in pinMapping:
            if 'mask' in pinMapping[alias]:
                port = pinMapping[alias]['port']
                mask = pinMapping[alias]['mask']
            else:
                port = pinMapping[alias]
                mask = 0xFF # Variable by bitwidth
            avr.mapPin(alias,port,mask)

    def mapPin(self,alias,port=None,mask=None): 
        if not port and not mask:
            if alias not in self.pinMapping:
                #Exception
                return alias,None
            return self.pinMapping[alias]
        self.pinMapping[alias] = (port,mask if mask else 0xFF)

    def write(self,var,val):
        if var in self.ports:
            # Can't write to ports
            return False
        elif var in self.ddrs:
            # Tests shouldn't write to DDR
            self._writeDDR(var,val)
        elif var in self.pins:
            return self._writePort(var,val)
        else:
            # Find the variable and write to it.
            symbol = gdb.lookup_symbol(var)[0]
            if symbol and symbol.is_valid():
                gdb.execute(f'set {var}={val}')
                return True
            return False

    def _writePort(self,port,value): #TODO Is formatting handled correctly?
        port,mask = self.mapPin(port)
        if port not in self.pins:
            # Throw exception
            return False
        # Need to mask out value
        buff=bytes([value])
        self.inferior.write_memory(self.base+self.pins[port],buff,1)
        return True

    def read(self,var):
        # Handle pin mapping
        symbol = gdb.lookup_symbol(var)[0]
        if symbol and symbol.is_valid():
            return symbol.value(gdb.selected_frame())

    def _readPort(self,port):
        mask = 0xFF
        if port in self.pinMapping:
            mask = self.pinMapping[port][1]
            port = self.pinMapping[port][0]
        value = int.from_bytes(self.inferior.read_memory(self.base+self.ports[port],1),
                byteorder=self.endian,signed='signed') 
        return (value & mask)

class displayChip(gdb.Command):
    '''Display the AVR device
    Only works on Atmega1284 devices
    '''
    def __init__(self,avr):
        super(displayChip,self).__init__('displayChip',gdb.COMMAND_USER)
        self.avr = avr
    def invoke(self,arg,tty):
        self.avr.display()

class runTests(gdb.Command):
    '''Run user defined tests
    Usage: runTests [N]
    The number N may be used as an argument, which will run the next N tests. 
    Default is to run all tests.
    '''
    def __init__(self,tests):
        super(runTests,self).__init__('runTests',gdb.COMMAND_USER)
        self.i,self.passed,self.skipped = 0,0,0
        self.tests = []
        for i,test in enumerate(tests):
            try:
                self.tests.append(Test(avr,**test))
            except TypeError as te:
                self.skipped += 1

    def _report(self):
        report('='*50)
        report(f'Passed {self.passed}/{self.i} tests. Skipped {self.skipped} tests.')
        report('='*50)

    def _runOne(self):
        while self.i < len(self.tests) and self.tests[self.i].skip:
            gdbLogger.info(f'Skipping test {self.i+1}.')
            self.i += 1
            self.skipped += 1
        if self.i < len(self.tests):
            report('='*50)
            report(f'Test {self.i+1}: \"{self.tests[self.i].description}\"...',end='')
            passed,message = self.tests[self.i].run()
            report(message)
            self.passed += 1 if passed else 0
            self.i += 1
    def invoke(self,arg,tty):
        args = gdb.string_to_argv(arg)
        testsToRun = int(args[0]) if args else len(self.tests)-self.i
        while testsToRun:
            self._runOne()
            testsToRun -= 1
        if self.i >= len(self.tests):
            self._report()

class Test():
    def __init__(self,program,description,steps,expected,preconditions=None,skip=False):
        self.description = description
        self.preconditions = preconditions
        self.program = program
        self.steps = steps
        self.expected = expected
        self.skip = skip
    
    def run(self):
        gdbLogger.debug('Setting preconditions')
        if self.preconditions:
            # Setup preconditions for test
            for var,val in self.preconditions:
                self.program.write(var,val)
        gdbLogger.debug(f'Running through {len(self.steps)} steps.')
        for step in self.steps:
            # Set inputs
            if 'inputs' in step:
                gdbLogger.debug(f'Setting inputs: {step["inputs"]}')
                for pin,value in step['inputs']:
                    if not self.program.write(pin,value):
                        return False,f'failed. Failed to write {value} to {pin}'
            # Run for specified amount of time/iterations
            if 'time' in step:
                gdbLogger.debug(f'Run for {step["time"]}ms')
                self.program.runForNms(step['time'])
            elif 'iterations' in step:
                gdbLogger.debug(f'Run for {step["iterations"]} iterations')
                self.program.runForNIterations(step['iterations'])
            else: # If not specified, run once
                gdbLogger.debug(f'Run for 1 iterations')
                self.program.runForNIterations(1)
            # Check any step level expectations
            if 'expected' in step:
                gdbLogger.debug(f'Checking expected values: {step["expected"]}')
                for port,value in step['expected']:
                    actual = self.program.read(port)
                    try:
                        expected = hex(value)
                    except TypeError:
                        expected = value
                    if actual != value:
                        return False,f'failed.\n\tExpected {port} := {value} but got {actual}'
        gdbLogger.debug(f'Checking expected values in results: {self.expected}')
        for port,value in self.expected:
            actual = self.program.read(port)
            if isinstance(value,int) and actual == value:
                return True,'passed'
            elif isinstance(value,str) and str(actual) == value:
                return True,'passed'
            else:
                return False,f'failed.\n\tExpected {port} := {value} but got {actual}'
        return True,'passed'

gdb.execute('target remote :1234') # connect to SimAVR

sync = False
while1 = None
timerRE = re.compile('(?P<line>\d+)\s*TimerSet\s*\(')
whileRE = re.compile('(?P<line>\d+)\s*while\s*\(\s*1\s*\)')
gdb.execute('set listsize unlimited')
for line in gdb.execute('list main,',to_string=True).split('\n'):
    whileMatch = whileRE.search(line)
    timerMatch = timerRE.search(line)
    if whileMatch:
        while1 = int(whileMatch.group('line'))
    elif timerMatch:
        sync = True
gdb.execute('set listsize 10')
inf = gdb.selected_inferior()
avr = AVR(inf,while1)

if sync:
    capturePeriod = SyncCatch(avr)
    gdb.execute('continue')
gdb.execute('continue')

if 'pinMapping' in globals():
    avr.mapPins(pinMapping)
if 'watch' in globals():
    for watchVariable in watch:
        avr.addWatch(watchVariable)
runTests(tests)
displayChip(avr)
#avr.bp.commands = 'displayChip\n' # Uncomment if you'd like to see the chip displayed at every break
