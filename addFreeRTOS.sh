#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"

if grep -q FREERTOS "Makefile"; then
    echo -e 'FreeRTOS possibly already added to project\nAdding again can cause problems compiling'
    read -p 'Continue? (Y)es/(N)o: ' cont
fi
    
if [ $cont == "Y" ]; then 
    echo "Copying FreeRTOS files and updating Makefile..."
    cp -R $SCRIPTDIR/FreeRTOS ./
    # Insert FreeRTOS directories
    sed -i '/^# Simulator/i # FreeRTOS\nFREERTOSINC=-I./FreeRTOS/Source/include/ -I./FreeRTOS/Source/portable/GCC/ATMega323/ -I./FreeRTOS/' Makefile 
    sed -i '/^SOURCES.*/a FREERTOSSRC=FreeRTOS/Source/\nFREERTOSSOURCES=$(wildcard $(FREERTOSSRC)*.c)' Makefile 
    sed -i '/^OBJS/ s/$/ \\/' Makefile
    sed -i '/^OBJS.*/a \    $(patsubst $(FREERTOSSRC)%,$(PATHO)%,$(FREERTOSSOURCES:.c=.o))' Makefile 
    sed -i '/^clean.*/i $(PATHO)%.o: $(FREERTOSSRC)%.c\n\t$(AVR) $(DEBUGFLAGS) $(SIMFLAGS) $(FLAGS) $(INCLUDES) -c -o $@ $<\n' Makefile 
    sed -i '/^INCLUDES/ s/$/ $(FREERTOSINC)/' Makefile
fi
