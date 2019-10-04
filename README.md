# AVR Toolchain for CS120B and CS122A at UC Riverside
This repository provides template Makefiles, main.c and header files along with a project creation script for embedded systems courses at UC Riverside. 
# Installation
You need to make sure that you have downloaded and installed [SimAVR](https://github.com/buserror/simavr), [AVR toolchain](http://maxembedded.com/2015/06/setting-up-avr-gcc-toolchain-on-linux-and-mac-os-x/) which includes: AVR-GCC, AVR-GDB, and (optionally) AVRDUDES. You can also try installing [AVRDUDESS](https://github.com/zkemble/AVRDUDESS) (yes the extra 's' is intentional) for a graphical programming interface.  
 - Clone or download the repository to a location on your computer.
 - Edit the `SIMAVRDIR=SET YOUR SIMAVR DIRECTORY HERE` line in the `templates/MakefileTemplate` to be the path to your SimAVR installation.
 - Edit the `#include "include/simavr/avr/avr_mcu_section.h"` in the `createProject.sh` to be the relative path from your SIMAVRDIR (from the previous step) to the `avr_mcu_section.h` file
## Usage 
 - /path/to/repo/createProject.sh
```
 Creating a new AVR project. Input the following or hit enter for the [default].
 Project name: <newProject>
 Partners name [none]: 
 Microcontroller [atmega1284]: 
 Clock Frequency [8000000]: 
 Creating project...
 Creating project directory structure...
 Creating project templates for source, tests, and Makefile...
 Project created, to continue working: 

	1) Change working directory into project directory
	2) Initialize the directory to a GitHub repo: 
		$git init
	3) Add the files to the github repo: 
		$git add .
	4) Make a first commit: 
		$git commit -m "Initializing repositor"
	5) Create a project at github.com
	6) In terminal, add the URL to your project: 
		$git remote add origin <remote repository URL>
	7) Verify the remote repository: 
		$git remote -v
	8) Push the changes to GitHub: 
		$git push -u origin master
```
 - And start developing
