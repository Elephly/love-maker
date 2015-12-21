#!/bin/bash

# love-maker.sh

## This file is intended for cross-platform use, so long as the
## system is capable of running shell scripts.

## Functions
function GetConfigProperty
{
  if [ ! -z $1 ]; then
    propName=$1:
    propertyLine=`grep -a $propName love-maker.config`
    if [ ! -z "$propertyLine" ]; then
      propertyLine=${propertyLine//[[:blank:]]/}
      if [ ${propertyLine:0:${#propName}} == "$propName" ]; then
        propertyValue=${propertyLine:${#propName}}
        if [ ! -z "$propertyValue" ]; then
          echo $propertyValue
        else
          echo
        fi
      else
        echo
      fi
    else
      echo
    fi
  else
    echo
  fi
}

## Miscellaneous variables
DOWNLOAD_DIR=love-downloads
if [ ! -e $DOWNLOAD_DIR ]; then
  mkdir $DOWNLOAD_DIR
fi

## LOVE version - potentially read through config file and/or retrieved online
MAJOR=$(GetConfigProperty VERSION_MAJOR)
if [ -z "$MAJOR" ]; then
  MAJOR=0
fi
MINOR=$(GetConfigProperty VERSION_MINOR)
if [ -z "$MINOR" ]; then
  MINOR=9
fi
BUILD=$(GetConfigProperty VERSION_BUILD)
if [ -z "$BUILD" ]; then
  BUILD=2
fi
URL=https://bitbucket.org/rude/love/downloads/

## Get architecture
os=""
arch=$(uname -m)

case "$OSTYPE" in
  *bsd*)    os="bsd" ;;
  cygwin*)  os="win" ;;
  darwin*)  os="mac" ;;
  linux*)   os="linux" ;;
  msys*)    os="win" ;;
  solaris*) os="solaris" ;;
  *)        os="unknown" ;;
esac

myos=$os
echo "OSTYPE: $OSTYPE ($os)"

echo "ARCHITECTURE: $arch"

echo "Platforms:"
echo "  (1) Windows 64-bit"
echo "  (2) Windows 32-bit"
echo "  (3) Mac OS X"
echo "  (4) Linux"
echo "  (Default) Current Platform"

## Ask for the target platform
choice="-1"
while [ ! -z $choice ] && [ $choice != "0" ] && [ $choice != "1" ] &&
  [ $choice != "2" ] && [ $choice != "3" ] && [ $choice != "4" ]; do
  read -p "Select desired platform (0 to exit): " choice
done

if [ ! -z $choice ]; then
  if [ $choice == "1" ]; then
    os="win"
    arch="x86_64"
    echo "Building distribution for Windows 64-bit."
  elif [ $choice == "2" ]; then
    os="win"
    arch="x86"
    echo "Building distribution for Windows 32-bit."
  elif [ $choice == "3" ]; then
    os="macosx"
    arch="x64"
    echo "Building distribution for Mac OS X."
  elif [ $choice == "4" ]; then
    os="linux"
    echo "Building distribution for Linux."
  elif [ $choice == "0" ]; then
    exit
  fi
else
  echo "Building distribution for current platform."
fi
echo

PATH_ARR=$(echo $(pwd) | tr "/" "\n")

## Finding the directory name for ../
p1=
p2=
for i in $PATH_ARR
do
  p2=$p1
  p1=$i
done

PROJ_ROOT=..
PROJ_NAME=$p2
SRC_DIR=$PROJ_ROOT/src
BIN_DIR=$PROJ_ROOT/bin/$os-$arch

## If a bin directory for the target platform exists, ask to either update or clean.
if [ -e $BIN_DIR ]; then
  choice="-1"
  echo "A distribution for this platform already exists."
  while [ ! -z $choice ] && [ $choice != "y" ] && [ $choice != "n" ]; do
    read -p "Would you like to update it (y) or clean and update (n)? (default y/n): " choice
  done
  if [ ! -z $choice ] && [ $choice == "n" ]; then
    rm -rf $BIN_DIR
  fi
fi

## Ask if we should still go forward with the build.
choice="-1"
echo "Build will start."
while [ ! -z $choice ] && [ $choice != "y" ] && [ $choice != "n" ]; do
  read -p "Do you want to continue? (default y/n): " choice
done
if [ ! -z $choice ] && [ $choice == "n" ]; then
  exit
fi

## Making the binaries directory
ARR=$(echo $BIN_DIR | tr "/" "\n")
CURR_DIR=
for i in $ARR
do
  CURR_DIR=$CURR_DIR$i/
  if [ ! -e $CURR_DIR ]; then
    mkdir $CURR_DIR
  fi
done

## Making the Project zip/love file
if [ -e $PROJ_NAME.love ]; then
  rm -f $PROJ_NAME.love
fi
if [ $myos == "win" ]; then
  powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::CreateFromDirectory('$SRC_DIR/', '$PROJ_NAME.love'); }"
else
  zip -9 -q -r $PROJ_NAME.love $SRC_DIR/*
fi

## Setting platform specific names
if [ $os == "win" ]; then
  LOVE_ESS=
  if [ $arch == "x86_64" ]; then
    LOVE_ESS=love-$MAJOR.$MINOR.$BUILD-win64
  else
    LOVE_ESS=love-$MAJOR.$MINOR.$BUILD-win32
  fi
  OUT_PRODUCT=$BIN_DIR/$PROJ_NAME.exe
elif [ $os == "macosx" ]; then
  COM_NAME=""
  while [ -z $COM_NAME ]; do
    read -p "Enter a company name: " COM_NAME
  done
  LOVE_ESS=love-$MAJOR.$MINOR.$BUILD-macosx-x64
  OUT_PRODUCT=$BIN_DIR/$PROJ_NAME.app
elif [ $os == "linux" ]; then
  ## TODO: change for the sake of downloading the proper linux files
  LOVE_ESS=linux
  OUT_PRODUCT=$BIN_DIR/$PROJ_NAME
else
  ## Copying love/zip file
  cp $PROJ_NAME.love $BIN_DIR

  ## Removing the love/zip file
  rm $PROJ_NAME.love

  ## Copying license
  cp license.txt $BIN_DIR

  echo "Unsupported platform."
  echo "Exiting."
  read
  exit
fi

## Checking for love files, downloading if not found
if [ $os == "win" ] || [ $os == "macosx" ]; then
  if [ ! -e $DOWNLOAD_DIR/$LOVE_ESS ]; then
    echo "No LOVE installation files found."
    echo "Downloading $LOVE_ESS..."
    LOVE_DOWNLOAD_URL=$URL$LOVE_ESS.zip
    if [ $myos == "win" ]; then
      powershell.exe -nologo -noprofile -command "& { wget $LOVE_DOWNLOAD_URL -UseBasicParsing -OutFile $LOVE_ESS.zip; }"
    else
      wget $LOVE_DOWNLOAD_URL
    fi
    
    echo "Extracting..."
    if [ $myos == "win" ]; then
      powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('$LOVE_ESS.zip', 'temp') }"
    else
      unzip $LOVE_ESS.zip -d temp
    fi
    
    rm -rf "$LOVE_ESS.zip"
    mv temp/love* $DOWNLOAD_DIR/$LOVE_ESS
    rm -rf temp
  fi
else
  if [ $os == "linux" ]; then
    ## TODO: download appropriate linux files
    echo "Skip"
  fi
fi

## Performing platform specific build
if [ $os == "win" ]; then
  ## Merging the love executable with the love game
  cat $DOWNLOAD_DIR/$LOVE_ESS/love.exe $PROJ_NAME.love > $OUT_PRODUCT

  ## Copying dll files
  cp $DOWNLOAD_DIR/$LOVE_ESS/*.dll $BIN_DIR
elif [ $os == "macosx" ]; then
  ## Copying app data to bin directory
  cp -r $DOWNLOAD_DIR/$LOVE_ESS $OUT_PRODUCT
  cp -r $PROJ_NAME.love $OUT_PRODUCT/Contents/Resources/

  ## Modifying Info.plist
  INFOPLIST=$OUT_PRODUCT/Contents/Info.plist

  OLDBIDENT="<string>org.love2d.love<\/string>"
  NEWBIDENT="<string>com.$COM_NAME.$PROJ_NAME<\/string>"
  sed -i 's/'"$OLDBIDENT"'/'"$NEWBIDENT"'/g' $INFOPLIST

  OLDBNAME="<string>LÖVE<\/string>"
  NEWBNAME="<string>$PROJ_NAME<\/string>"
  sed -i 's/'"$OLDBNAME"'/'"$NEWBNAME"'/g' $INFOPLIST

  TOREMOVE="\t<key>UTExportedTypeDeclarations<\/key>"
  ENDFILE="<\/dict>\n<\/plist>CUTHERE\n"
  sed -i 's/'"$TOREMOVE"'/'"$ENDFILE"'/g' $INFOPLIST
  TEMP=`cat $INFOPLIST`
  echo "${TEMP%%'CUTHERE'*}" > $INFOPLIST
elif [ $os == "linux" ]; then
  ## TODO: make linux deb package
  
  cp $PROJ_NAME.love $BIN_DIR
fi

## Removing the love/zip file
rm $PROJ_NAME.love

## Copying license
cp license.txt $BIN_DIR

echo
echo "Press enter to exit."
read
