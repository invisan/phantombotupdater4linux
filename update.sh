# !/bin/bash

if [ -z "$1" ]; then
       echo "Config file not set. Using sample.cfg"
        conf="sample.cfg"
else
        conf=$1
        echo "Config found."
fi

# Check if conf file present
if [ -f "$conf" ]; then
        echo "File exists. Continuing."
else
        echo "File not found. Exiting."
        exit
fi


# Function to check the Version 
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

# Grepping the variables from the conf File.
home=$(grep -Po 'home="\K[^"]*' $conf)
path=$(grep -Po 'path="\K[^"]*' $conf)
user=$(grep -Po 'user="\K[^"]*' $conf)
build=$(grep -Po 'build="\K[^"]*' $conf)
port=$(grep -Po 'port="\K[^"]*' $conf)


installed=$(unzip -p $path/PhantomBot.jar "META-INF/MANIFEST.MF" | grep -oP "(?<=Implementation-Version: )(\d+|\.)*")

if [ $build = "stable" ]; then
wget https://raw.githubusercontent.com/PhantomBot/PhantomBot/master/build.xml
newest=$(grep -Po '<property name="version".*?value="\K[^"]*' build.xml)
rm ./build.xml
else
        if [ $build = "nightly" ]; then
                wget https://github.com/PhantomBot/nightly-build/raw/master/PhantomBot-nightly-lin.zip -O phantombot.zip
                unzip ./phantombot.zip
                mv ./PhantomBot* nightly
                newest=$(unzip -p nightly/PhantomBot.jar "META-INF/MANIFEST.MF" | grep -oP "(?<=Implementation-Version: )(\d+|\.|\-|\d+|\-\d+)*")
        else
                if [ $build = "pbotde" ]; then
                        wget https://raw.githubusercontent.com/PhantomBotDE/PhantomBotDE/master/build.xml
                        newest=$(grep -Po '<property name="version".*?value="\K[^"]*' build.xml)
                        rm ./build.xml
                else
                        echo "No config found."
                fi
        fi
fi


echo "Installed Version is:" $installed
echo "Newest Version is:" $newest

if [ $(version $installed) -ge $(version $newest) ]; then
        echo "Newest Version already installed."
else
        echo "Newer Version found. Downloading now."

# Download of the latest Version of PhantomBot from Github
if [ $build = "stable" ]; then

        curl -s https://api.github.com/repos/PhantomBot/PhantomBot/releases/latest \
        | grep "browser_download_url.*zip" \
        | cut -d : -f 2,3 \
        | tr -d \" \
        | wget -qi - -O phantombot.zip

else
        if [ $build = "pbotde" ]; then

        curl -s https://api.github.com/repos/PhantomBotDE/PhantomBotDE/releases/latest \
        | grep "browser_download_url.*zip" \
        | cut -d : -f 2,3 \
        | tr -d \" \
        | wget -qi - -O phantombot.zip


        else
                echo "Neither pbotde or stable specified. Must be nightly or something else."
        fi
fi


# Check if PhantomBot is running
running=$(lsof -t -i :$port -s TCP:LISTEN)

if [ -z "$running" ]; then
                echo "Bot seems to be not running. Continuing with update."
else
                echo "Pid found. Stopping Bot."
                systemctl stop phantombot
                # Check again if Bot is still running
                running=$(lsof -t -i :$port -s TCP:LISTEN)
                        if [ -z "$running" ]; then
                                echo "Bot stopped. Continuing with update."
                        else
                                echo "Seems systemctl wasnt working. Trying kill."
                                kill $(pgrep -f PhantomBot)
                                # Check again if Bot is still running
                                running=$(lsof -t -i :$port -s TCP:LISTEN)
                                        if [ -z "$running" ]; then
                                                echo "Bot stopped. Continuing with update."
                                        else
                                                echo "Seems kill did not work. Trying skill -9."
                                                skill -9 $running
                                        fi
                        fi
fi

if [ -d "$path" ]; then

        if [ -d "$path-old" ]; then

                # Remove the old phantombot-old Folder
                rm -R ./$path-old

        fi

# Move phantombot Folder to phantombot-old
mv ./$path $path-old

fi

if [ $build = "nightly" ]; then

        mv nightly $path

else

# Unzip the Zip File 
unzip phantombot.zip

# "Rename" the extracted Folder through Move
mv ./PhantomBot*/ $path

fi

if [ -d "$path-old" ]; then

# Copy the Old Configs
cp -R ./$path-old/config/ ./$path/
cp -R ./$path-old/scripts/lang/custom/ ./$path/scripts/lang/

fi

# Make the sh files executable
chmod u+x $home/$path/launch-service.sh
chmod u+x $home/$path/launch.sh
chmod u+x $home/$path/java-runtime-linux/bin/java

# Remove the Zip File
rm ./phantombot.zip

fi
