#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"

cont=Y # Default to Y
if grep -q FREERTOS "Makefile"; then
    echo -e 'FreeRTOS possibly already added to project\nAdding again can cause problems compiling'
    read -p 'Continue? (Y)es/(N)o: ' cont
fi
    
if [ $cont == "Y" ]; then 
    echo "Copying FreeRTOS files and updating Makefile..."
    cp -R $SCRIPTDIR/FreeRTOS ./
    # Insert FreeRTOS directories
    echo "Copying FreeRTOS files..."
    cp -R $SCRIPTDIR/FreeRTOS ./
    cp ./$name/FreeRTOS/Source/portable/MemMang/heap_1.c ./$name/FreeRTOS/Source
    echo "Updating Makefile..."
    freertosdefs='# FreeRTOS specific\nFREERTOSDIR=FreeRTOS/\nFREERTOSSRC=FreeRTOS/Source/\nFREERTOSSOURCES=$(wildcard $(FREERTOSSRC)*.c)\nFREERTOSMEGAPORT=$(FREERTOSSRC)portable/GCC/ATMega1284/\nFREERTOSMEGAPORTSOURCES=$(wildcard $(FREERTOSMEGAPORT)*.c)\nFREERTOSOBJS=$(patsubst $(FREERTOSSRC)%,$(PATHO)%,$(FREERTOSSOURCES:.c=.o)) \\\n\t$(patsubst $(FREERTOSMEGAPORT)%,$(PATHO)%,$(FREERTOSMEGAPORTSOURCES:.c=.o))\nFREERTOSINC=-I$(FREERTOSSRC)include/ -I$(FREERTOSMEGAPORT) -I$(FREERTOSDIR)\nOBJS+= $(FREERTOSOBJS)\n'
    freertosrules='$(PATHO)%.o: $(FREERTOSSRC)%.c\n\t@$(AVR) $(DEBUGFLAGS) $(SIMFLAGS) $(FLAGS) $(INCLUDES) -c -o $@ $<\n\n$(PATHO)%.o: $(FREERTOSMEGAPORT)%.c\n\t@$(AVR) $(DEBUGFLAGS) $(SIMFLAGS) $(FLAGS) $(INCLUDES) -c -o $@ $<\n'

    awk -v "freertosdefs=$freertosdefs" '/^CLEAN.*/ && !x {print freertosdefs; x=1} 1' $name/Makefile > $name/Makefile.new
    mv Makefile.new Makefile

    sed '/^INCLUDES/ s/$/ $(FREERTOSINC)/' Makefile > Makefile.new
    mv Makefile.new Makefile

    awk -v "freertosrules=$freertosrules" '/^clean.*/ && !x {print freertosrules; x=1} 1' $name/Makefile > $name/Makefile.new
    mv Makefile.new Makefile
fi

