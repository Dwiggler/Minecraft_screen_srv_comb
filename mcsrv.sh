#!/bin/sh
#v0.9

#get command flag passed
workdir="/opt/minecraft/mainsurvival/"
ARG=$(echo $1 | tr '[:upper:]' '[:lower:]')

#relocate to working WorkingDirectory
cd $workdir

#for creating time stamps on log files
timestamp() {
	date +"%Y%m%d_%H:%M:%S"
}

#checks to see if service is already running
service_check () {
        ps -ef | grep mainsurvival | grep -v grep | wc -l
}

#grabs the PID for the minecrat process and screen pid/name
create_info_file() {

	echo "$(ps -ef | grep minecraft | grep java | awk {'print $2'})" > /opt/minecraft/mainsurvival/pid.txt
	echo "SCREEN= $(screen -ls | grep minecraft | awk {'print $1'})" > /opt/minecraft/mainsurvival/screeninfo.txt
}


srv_start() {
		#removing previous startup log
		startlog=$(ls -l /opt/minecraft/mainsurvival/startup.log | wc -l)
		echo "number of startup.log files is $startlog" >> /opt/minecraft/mainsurvival/startup.log

		if [ $startlog != 0 ]
		then
	       echo "removing statup.log file" >> /opt/minecraft/mainsurvival/startup.log
	       rm -f /opt/minecraft/mainsurvival/startup.log
		fi

		#starting new startup log
		echo "$(timestamp): Script beginning run"  > /opt/minecraft/mainsurvival/startup.log

		#making sure no screen for service exists, if it does, script exits with error in startup log
		screen_run=$(screen -list | grep minecraft | wc -l)
		echo "$(timestamp): Number of running instances of screen with the name of minecraft $screen_run" >> /opt/minecraft/mainsurvival/startup.log

		if [ $screen_run != 0 ]
		then
	         echo "$(timestamp): There was already a screen with the name minecraft running" >> /opt/minecraft/mainsurvival/startup.log
	         exit

		else
	         screen -d -m -S minecraft
	         echo "$(timestamp): screen with the name minecraft started in disconneded mode" >> /opt/minecraft/mainsurvival/startup.log

		fi

		#providing time for screen to start
		echo "Sleep for 1 second" >> /opt/minecraft/mainsurvival/startup.log
		sleep 1

		#checks if screen is running before executing server start command
		screen_chk=$(screen -list | grep minecraft | wc -l)
		echo "$(timestamp): output of screen_chk value = $screen_chk" >> /opt/minecraft/mainsurvival/startup.log
		if [ $screen_chk = 1 ]
				then
						screen -S minecraft -p 0 -X stuff '/usr/bin/java -Xmx1024M -Xms1024M -jar /opt/minecraft/mainsurvival/minecraft.server nogui^M'
						echo "$(timestamp): Command to execute minecraft server .jar block" >> /opt/minecraft/mainsurvival/startup.log
				else
						echo "$(timestamp): screen_chk did not = 1" >> /opt/minecraft/mainsurvival/startup.log
		fi

		#get info about running process
		SRVRUN=$(ps -ef | grep minecraft.server | grep -v grep)
		echo "$(timestamp): ps output: $SRVRUN" >> /opt/minecraft/mainsurvival/startup.log

		#run funtion to create info file with PID and Screen info
		echo "running loop check for service" >> /opt/minecraft/mainsurvival/startup.log
		x=0
		while [ $x -gt 0 ]; do x=$(service_check); done

		echo "creating pid and screeninfo files" >> /opt/minecraft/mainsurvival/startup.log
		create_info_file
}

srv_stop() {

		#passing the service stop command
		screen -S minecraft -p 0 -X stuff "stop^M"
		echo "stop command was passed" >> /opt/minecraft/mainsurvival/startup.log

		#monitors service until full stop and then lets script continue
		echo "running loop check for service" >> /opt/minecraft/mainsurvival/startup.log
		x=1
		while [ $x != 0 ]; do	x=$(service_check); done

		#sends exit command to close out of the screen page
		screen -S minecraft -p 0 -X stuff "exit^M"
		echo "sent command to kill screen session" >> /opt/minecraft/mainsurvival/startup.log

		#removing previous info file to indicate system is not running
		screeninfo_file=$(ls -l /opt/minecraft/mainsurvival/screeninfo.txt | wc -l)
		pid_file=$(ls -l /opt/minecraft/mainsurvival/pid.txt | wc -l)
		echo "number of screeninfo.txt is $screeninfo_file" >> /opt/minecraft/mainsurvival/startup.log
		echo "number of pid.txt is $pid_file" >> /opt/minecraft/mainsurvival/startup.log

		if [ $screeninfo_file -gt 0 ]
		then
        echo "removing screeninfo.txt and pid.txt files" >> /opt/minecraft/mainsurvival/startup.log
        rm -f /opt/minecraft/mainsurvival/screeninfo.txt
				rm -f /opt/minecraft/mainsurvival/pid.txt
		fi
}

case $ARG in

	start)
	srv_start
	;;

	stop)
	srv_stop
	;;

	restart)
	srv_stop
	srv_start
	;;

esac
