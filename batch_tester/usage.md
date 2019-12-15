# Usage of batch tester
The script makes a batch command:<br>
<u>start /wait terminal.exe "testfile.txt"</u><br>

This "testfile.txt" contains several parameters including credentials for a demo account (see more at https://github.com/EA31337/EA-Tester/blob/master/conf/mt4-tester.ini)<br>
A row taken from the original testfile.txt:<br>
<u>TestPeriod=M15</u><br>
The script is able to recognize multiple values divided by an asterisk (\*), for example:<br>
<u>TestPeriod=M15\*M5\*M1</u><br>
From this the script makes one file with each setting in the "working folder", copies it to 
the "app instance folder", runs the backtesting, then moves the files to the 
"output folder". The needed parameters can be set via command line arguments or a json file.<br>
If a json file is used, it is **important** to use the same variables as described here:<br> 
{<br>
	"expert_advisor":"",<br>
	"test_file":"",<br>
	"setting":"",<br>
	"working_folder":"",<br>
	"instance_folder":"",<br>
	"output_folder":""<br>
}<br>
