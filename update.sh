# !/bin/bash

# Function to check the Version 
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }



installed=$(unzip -p phantombot/PhantomBot.jar "META-INF/MANIFEST.MF" | grep -oP "(?<=Implementation-Version: )(\d+|\.)*")
wget https://raw.githubusercontent.com/PhantomBot/PhantomBot/master/build.xml
newest=$(grep -Po '<property name="version".*?value="\K[^"]*' build.xml)
echo "Installed Version is:" $installed
echo "Newest Version is:" $newest
rm build.xml

if [ $(version $installed) -ge $(version $newest) ]; then
        echo "Newest Version already installed."
else
        echo "Newer Version found. Downloading now."

# Download of the latest Version of PhantomBot from Github
curl -s https://api.github.com/repos/PhantomBot/PhantomBot/releases/latest \
| grep "browser_download_url.*zip" \
| cut -d : -f 2,3 \
| tr -d \" \
| wget -qi -

# Check if PhantomBot is running
running=$(ps -ef | grep '[P]hantomBot' | awk '{print $2}')

if [ -z "$running" ]; then
                echo "Bot seems to be not running. Continuing with update."
else
                # Check if PhantomBot Service is installed
                service="/etc/systemd/system/phantombot.service"
                if [ -f "$service" ]; then
                        echo "Pid found. Stopping Bot."
                        systemctl stop phantombot &>> ./updater.log
                        sleep 15
                else
                        echo "Service not installed. Continuing with kill."
                fi
                # Check again if Bot is still running
                running=$(ps -ef | grep '[P]hantomBot' | awk '{print $2}')
                        if [ -z "$running" ]; then
                                echo "Bot stopped. Continuing with update."
                        else
                                echo "Seems service wasnt running or systemctl wasnt working. Trying kill."
                                kill $(pgrep -f PhantomBot)
                                echo "Waiting for 15 Seconds to check if the Bot is stopped."
                                sleep 15
                                # Check again if Bot is still running
                                running=$(ps -ef | grep '[P]hantomBot' | awk '{print $2}')
                                        if [ -z "$running" ]; then
                                                echo "Bot stopped. Continuing with update."
                                        else
                                                echo "Seems kill did not work. Trying skill -9."
                                                skill -9 $running
                                                sleep 15
                                                echo "Waiting for 15 Seconds to check if the Bot has stopped."
                                                running=$(ps -ef | grep '[P]hantomBot' | awk '{print $2}')
                                                        if [ -z "$running" ]; then
                                                                echo "Bot stopped. Continuing with update."
                                                        else
                                                                FILE="./updater.log"
                                                                        if [ -f "$FILE" ]; then
                                                                                echo "File exists. Continuing." >> /dev/null
                                                                        else
                                                                                touch ./updater.log
                                                                        fi;
                                                                        datum=$(date +'%x %X')
                                                                        log=$(echo " Seems the Bot could not be stopped succesfully. Exiting Script. Please stop the Bot manually. PID of the Process is: $running")
                                                                        string=$datum$log
                                                                        echo $string >> ./updater.log
                                                                exit
                                                        fi
                                        fi
                        fi
fi


# Remove the old phantombot-old Folder
rm -R ./phantombot-old

# Move phantombot Folder to phantombot-old
mv ./phantombot phantombot-old

# Unzip the Zip File 
unzip PhantomBot*.zip

# "Rename" the extracted Folder through Move
mv ./PhantomBot*/ phantombot

# Copy the Old Configs
cp -R ./phantombot-old/config/ ./phantombot/
cp -R ./phantombot-old/scripts/lang/custom/ ./phantombot/scripts/lang/

# Change to the phantombot Folder to make the sh files executable
cd phantombot

# Make the sh files executable
chmod u+x launch-service.sh launch.sh
chmod u+x ./phantombot/java-runtime-linux/bin/java

# Remove the Zip File
rm PhantomBot*.zip

fi
