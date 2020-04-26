#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"

echo 'Creating a new AVR project. Input the following or hit enter for the [default].'
read -p 'Project name: ' name
read -p 'Partners name [none]: ' partner
read -p 'Microcontroller [atmega1284]: ' mmcu
read -p 'Clock Frequency [8000000]: ' freq
echo "Creating project..."

if [ -z "$name" ] 
then
    echo 'Must have a project name';
    exit 1;
fi

mmcu=${mmcu:-atmega1284}
freq=${freq:-8000000}

# Create the directory structure
echo "Creating project directory structure..."
mkdir -p "$name"/source
mkdir -p "$name"/header
mkdir -p "$name"/test
mkdir -p "$name"/build/results
mkdir -p "$name"/build/objects
mkdir -p "$name"/build/bin
mkdir -p "$name"/turnin

echo "Creating project templates for source, tests, and Makefile..."
# Create the main.c file
touch "$name"/source/main.c
cat > "$name"/source/main.c << EOF
/*	Author: $USER
 *  Partner(s) Name: $partner
 *	Lab Section:
 *	Assignment: Lab #  Exercise #
 *	Exercise Description: [optional - include for your own benefit]
 *
 *	I acknowledge all content contained herein, excluding template or example
 *	code, is my own original work.
 */
#include <avr/io.h>
#ifdef _SIMULATE_
#include "simAVRHeader.h"
#endif

int main(void) {
    /* Insert DDR and PORT initializations */

    /* Insert your solution below */
    while (1) {

    }
    return 1;
}
EOF


# Create the Makefile
echo '# University of California, Riverside' > "$name"/Makefile
echo '# CS120B Makefile' >> "$name"/Makefile
echo "MMCU=${mmcu}" >> "$name"/Makefile
echo "FREQ=${freq}" >> "$name"/Makefile
cat $SCRIPTDIR/templates/MakefileTemplate >> "$name"/Makefile

# Create Simulator header
cat > "$name"/header/simAVRHeader.h << EOF
/* Debug information for SimAVR */
#include <stdio.h>
#ifndef F_CPU
#define F_CPU $freq
#endif

#include <avr/sleep.h>
#include "include/simavr/avr/avr_mcu_section.h"
AVR_MCU(F_CPU,"$mmcu");
AVR_MCU_VCD_FILE("build/results/${name}_trace.vcd",1000);

const struct avr_mmcu_vcd_trace_t _mytrace[] _MMCU_ = {
    { AVR_MCU_VCD_SYMBOL("PINA0"), .mask = 1 << 0,.what = (void*)&PINA, } , // Example individual pin
    { AVR_MCU_VCD_SYMBOL("PORTB"), .what = (void*)&PORTB, } , // Example full port
};

/* Function to output through UART */
static int uart_putchar(char c, FILE *stream) {
    if (c == '\n') {
        uart_putchar('\r',stream);
    }
    loop_until_bit_is_set(UCSR0A,UDRE0);
    UDR0 = c;
    return 0;
}

/* Setup filestream for debugging */
FILE mystdout = FDEV_SETUP_STREAM(uart_putchar,NULL,_FDEV_SETUP_WRITE);
/* End SimAVR section */
EOF

# Create commands file for debugger
cat $SCRIPTDIR/templates/commands.gdb > "$name"/test/commands.gdb 

# Create init file for debugger (sets break point)
cp $SCRIPTDIR/templates/initDebugger.gdb "$name"/test/initDebugger.gdb
# Create test template file
cat > "$name"/test/tests.gdb << EOF
# Test file for "$name"

EOF
cat $SCRIPTDIR/templates/tests.gdb >> "$name"/test/tests.gdb

echo -e "Project created, to continue working: \n"

# The following was generously supplied by @JiachengHou-PnR
echo -e "Initialize the directory to a GitHub repo."
echo -e "Please enter your GitHub repo URL to link this project to GitHub."
read -p 'git repo link [press ENTER to skip]: ' link

if [ -n "$link" ]
then
    echo -e 'Initializing repo...'
    cd "$name"
    git init
    git add .
    git commit -m 'Initializing repository'

    echo -e 'Adding repo to GitHub...'
    git remote add origin "$link"
    git remote -v

    echo -e 'Pushing changes to GitHub...'
    git push -u origin master

    echo
    echo -e "\e[42mProject Pushed.\033[0m You can change your directory and continue working."
else
    echo -e "\e[104mProject not initialized.\033[0m You can change your directory and continue working."
fi
