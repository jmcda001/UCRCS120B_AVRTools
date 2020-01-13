# commands.gdb provides the following functions for ease:
#   test "<message>"
#   checkResult
#   expectPORTx <val>
#   setPINx <val>
#   printPINx f 
#   printDDRx
#   printPORTx f OR printPINx f 

#   printPINx f 
#       With x as the port or pin (A,B,C,D)
#       With f as a format option which can be: [d] decimal, [x] hexadecmial (default), [t] binary 
#       Example: printPORTC d
define printPINA
    echo PINA addr 
    if $argc == 1
        x/1$arg0b 0x800020
    else
        x/1xb 0x800020
    end
end
define printPINB
    echo PINB addr 
    if $argc == 1
        x/1$arg0b 0x800023
    else
        x/1xb 0x800023
    end
end
define printPINC
    echo PINC addr 
    if $argc == 1
        x/1$arg0b 0x800026
    else
        x/1xb 0x800026
    end
end
define printPIND
    echo PIND addr 
    if $argc == 1
        x/1$arg0b 0x800029
    else
        x/1xb 0x800029
    end
end

#   printDDRx
#       With x as the DDR (A,B,C,D)
#       Example: printDDRB
define printDDRA
    echo DDRA addr 
    x/1xb 0x800021
end
define printDDRB
    echo DDDRB addr 
    x/1xb 0x800024
end
define printDDRC
    echo DDRC addr 
    x/1xb 0x800027
end
define printDDRD
    echo DDRD addr 
    x/1xb 0x80002A
end

#   printPORTx f OR printPINx f 
#       With x as the port or pin (A,B,C,D)
#       With f as a format option which can be: [d] decimal, [x] hexadecmial (default), [t] binary 
#       Example: printPORTC d
define printPORTA
    echo PORTA addr 
    if $argc == 1
        x/1$arg0b 0x800022
    else
        x/1xb 0x800022
    end
end
define printPORTB
    echo PORTB addr 
    if $argc == 1
        x/1$arg0b 0x800025
    else
        x/1xb 0x800025
    end
end
define printPORTC
    echo PORTC addr
    if $argc == 1
        x/1$arg0b 0x800028
    else 
        x/1xb 0x800028
    end
end
define printPORTD
    echo PORTD addr 
    if $argc == 1
        x/1$arg0b 0x80002B
    else
        x/1xb 0x80002B
    end
end

#   setPINx <val>
#       With x as the port or pin (A,B,C,D)
#       The value to set the pin to (can be decimal or hexidecimal
#       Example: setPINA 0x01
define setPINA
    set {char}0x800020=$arg0
end
define setPINB
    set {char}0x800023=$arg0
end
define setPINC
    set {char}0x800026=$arg0
end
define setPIND
    set {char}0x800029=$arg0
end

#   test "<message>"
#       Where <message> is the message to print. Must call this at the beginning of every test
#       Example: test "PINA: 0x00 => expect PORTC: 0x01"
define test
    set $tests = $tests+1
    set $passed = 1
    eval "shell echo -n Test %d: ",$tests
    echo $arg0...
end

#   checkResult
#       Verify if the test passed or failed. Prints "passed." or "failed." accordingly, 
#       Must call this at the end of every test.
define checkResult
    if $passed == 1
        eval "shell echo -e \\\\e[32mpassed\\\\e[0m.\n\n"
    else
        set $failed = $failed + 1
        eval "shell echo -e \\\\e[31mfailed\\\\e[0m.\n\n"
    end
end

#   expectPORTx <val>
#       With x as the port (A,B,C,D)
#       The value the port is epected to have. If not it will print the erroneous actual value
#       val is unsigned
define expectPORTA
    set $actual = {unsigned char}0x800022
    if $actual != $arg0
        set $passed = 0
        echo \n\tExpected $arg0 \n\t
        echo PORTA '
        x/1xb 0x800022
    end
end
define expectPORTB
    set $actual = {unsigned char}0x800025
    if $actual != $arg0
        set $passed = 0
        echo \n\tExpected $arg0 \n\t
        echo PORTB '
        x/1xb 0x800025
    end
end
define expectPORTC
    set $actual = {unsigned char}0x800028
    if $actual != $arg0
        set $passed = 0
        echo \n\tExpected $arg0 \n\t
        echo PORTC '
        x/1xb 0x800028
    end
end
define expectPORTD
    set $actual = {unsigned char}0x80002B
    if $actual != $arg0
        set $passed = 0
        echo \n\tExpected $arg0 \n\t
        echo PORTD '
        x/1xb 0x80002B
    end
end
#   expectSignedPORTx <val>
#       With x as the port (A,B,C,D)
#       The value the port is epected to have. If not it will print the erroneous actual value
#       val is a signed value (-128 == 0x80)
define expectSignedPORTA
    set $actual = {char}0x800022
    if $actual != $arg0
        set $passed = 0
        echo \n\tExpected $arg0 \n\t
        echo PORTA '
        x/1xb 0x800022
    end
end
define expectSignedPORTB
    set $actual = {char}0x800025
    if $actual != $arg0
        set $passed = 0
        echo \n\tExpected $arg0 \n\t
        echo PORTB '
        x/1xb 0x800025
    end
end
define expectSignedPORTC
    set $actual = {char}0x800028
    if $actual != $arg0
        set $passed = 0
        echo \n\tExpected $arg0 \n\t
        echo PORTC '
        x/1xb 0x800028
    end
end
define expectSignedPORTD
    set $actual = {char}0x80002B
    if $actual != $arg0
        set $passed = 0
        echo \n\tExpected $arg0 \n\t
        echo PORTD '
        x/1xb 0x80002B
    end
end

# expect <var> <val>
define expect
    if $arg0 != $arg1
        set $passed = 0
        echo \n\tExpected $arg1 but got $arg0:
        output /d $arg0
    end
end
