# !/bin/bash

# Download of the latest Version of PhantomBot from Github
curl -s https://api.github.com/repos/PhantomBot/PhantomBot/releases/latest \
| grep "browser_download_url.*zip" \
| cut -d : -f 2,3 \
| tr -d \" \
| wget -qi -

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
