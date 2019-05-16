
file build/objects/main.elf
target remote :1234
set logging file build/results/tests_out.txt 
set logging overwrite on
set logging on
set $passed=1
set $failed=0
set $tests=0

# Break at the top of the while loop (:# needs to have the line number at the top of the while(1))
break main.c:#
commands
silent
# Add all variables you want to inspect (printPORTx f, printPINx f)
# f can be: [d] decimal, [x] hexadecmial (default), [t] binary
# Example: printPORTC d 
end
continue 
