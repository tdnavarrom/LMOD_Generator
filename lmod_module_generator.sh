#!/bin/bash
# script for generating module files in Lua
# <Tomas David Navarro Munera> <tdnavarrom@eafit.edu.co>
# <07-31-2020>
# Universidad EAFIT
# http://www.eafit.edu.co
# Medellín - Colombia
# 2020

# Font variables (color and bold style)
BOLD=$(tput bold)
GREEN='\033[1;32m'
RED='\033[0;31m'
YELLOW='\033[33m'
NC='\033[0m'
PS2='> '

#Global Variables
pre_requisites_modules_path=""
installation_path=""
customPath=false
name_of_app=""
version_of_app=""

LOCAL_MODULES_UNAVAILABLE=false

# Function that asks if your pre-requisites are in your local environment
# Or in production
function where_to_modules() {
    echo -e "${YELLOW}${BOLD}Are the prerequesites modules in your local environment(1) or in production(2): ${NC}"
    
    while
        read -e -p "$PS2" option
        [ -z "$option" ]
    do true; done

    if [ $LOCAL_MODULES_UNAVAILABLE = 'true' ] && [ $option = 1 ]; then
        echo -e "${YELLOW}${BOLD}WARNING: \nYour module is for production, you chose option 1, but the script will only look for production modules. ${NC}"
        option=2
    fi

    if [ $option = 1 ]; then
        echo -e "${YELLOW}Setting Up variables!.. ${NC}"
        pre_requisites_modules_path=$HOME/apps/modules
    elif [ $option = 2 ]; then
        echo -e "${YELLOW}Setting Up variables!.. ${NC}"
        pre_requisites_modules_path=/share/apps/modules
    else
        echo -e "${RED}${BOLD}Error: Option not valid!${NC}"
        exit 3
    fi

}

# Function that aks if you are going to install a module in your local environment
# Or for production
function user_set_up() {
    echo -e "${YELLOW}${BOLD}Is your module for your local environment(1) or for production(2): ${NC}"

    while
        read -e -p "$PS2" option
        [ -z "$option" ]
    do true; done
    
    if [ $option = 1 ]; then
        echo -e "${YELLOW}Module will be installed in your local environment. ${NC}"
	    installation_path="$HOME/apps/modules"
    elif [ $option = 2 ] ; then
        echo -e "${YELLOW}Checking Root${NC}"
        LOCAL_MODULES_UNAVAILABLE=true
        root_check
	    installation_path="/share/apps/modules"
        echo -e "${YELLOW}${BOLD}Module will be installed in for production.${NC}"
    else
        echo -e "${RED}${BOLD}Error: Option not valid!${NC}"
        exit 3
    fi

}

# Function that checks if you have the needed permissions
function root_check() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}${BOLD}### Please run as root ###${NC}"
        exit 3
    fi
}


# Function that asks the user to input the version of the app
# If path of app does not follow Lmod hierarchy
# Lmod hierarchy: dir/app/version
# ex: /share/apps/gcc/8.3.1
function custom_path() {
    echo -e "${YELLOW}${BOLD}Does your app path follow this hierarchy? [Y/n]${NC}"
    echo -e "${YELLOW}${BOLD}* 1) Lmod hierarchy: /dir/app/version${NC}"
    echo -e "${YELLOW}${BOLD}* ex: /share/apps/gcc/8.3.1${NC}"
    echo -e "${YELLOW}${BOLD}* 2) Default hierarchy V1: /dir/app/version/compiler/compiler_version${NC}"
    echo -e "${YELLOW}${BOLD}* ex: /share/apps/gcc/8.3.1/gcc/7.4.0${NC}"
    echo -e "${YELLOW}${BOLD}* 3) Default hierarchy V2: /dir/app/version/compiler-compiler_version${NC}"
    echo -e "${YELLOW}${BOLD}* ex: /share/apps/gcc/8.3.1/gcc-7.4.0${NC}"
    echo -e "${YELLOW}${BOLD}* 4) Other${NC}"
    

    while
        while
            read -e -p "$PS2" option
            [ -z "$option" ]
        do true; done

        if [ "$option" = 1 ]; then
            echo "Lmod hierarchy chosen."
            customPath=1
            break
        elif [ "$option" = 2 ]; then
            echo "Default hierarchy v1 chosen."
            customPath=2
            break
        elif [ "$option" = 3 ]; then
            echo "Default hierarchy v2 chosen."
            customPath=3
            break 
        elif [ "$option" = 4 ]; then
            customPath=4
            echo "Please input the name of your app: "
            echo -n "> "
            read name
            name_of_app=${name}
            echo "Please input the version of your app: "
            echo -n "> "
            read version
            version_of_app=${version}
            break
        else
            echo -e "${RED}${BOLD}Error: Option not valid!${NC}"
        fi

    do true; done
    
}


# Function that prints the array elements
function print_vector() {
    vector=("$@")
    for i in "${vector[@]}"; do
        printf '%s\n' "$i"
    done
}

# Function that checks if the path exists and is a directory
function check_path() {
    # echo "Checking if Directory exists ...."
    if [[ -f $1 ]]; then
        echo -e "${RED}${BOLD}Error: $1 is a file. Path given must be a directory.${NC}"
        exit 3
    fi

    if [[ ! -d $1 ]]; then
        echo -e "${RED}${BOLD}Error: $1 does not exists on your filesystem. Please put your path correctly.${NC}"
        exit 3
    fi
    # echo "Directory exists ..."
}

# Function that creates the directory
function create_directory() {
    if [[ ! -d $1 ]]; then
        echo -e "${YELLOW}Creatin directory ...${NC}"
        mkdir -p $1
    fi
}


#Main Program

echo -e "${GREEN}${BOLD}####Module Generator####${NC}"

user_set_up

echo -e "${YELLOW}${BOLD}Write the directory path of the application:${NC} "

while
  read -e -p "$PS2" path
  [ -z "$path" ]
do true; done


if [ "${path: -1}" = "/" ]; then
        path=${path:0:${#path}-1}
	#echo "Path: $path"
fi


check_path ${path}

IFS="/" read -ra vector_path <<<"${path}"

topdir=$path
sys="x86_64-redhat-linux"

custom_path

if [ $customPath = '4' ]; then
    nameOfModule=$name_of_app
    version=$version_of_app
    filedir=$installation_path/$nameOfModule
elif [ $customPath = '1' ]; then
    filedir=${installation_path}/${vector_path[-2]}
    version=${vector_path[-1]}
    nameOfModule=${vector_path[-2]}
elif [ $customPath = '2' ]; then
    filedir=${installation_path}/${vector_path[-4]}
    version=${vector_path[-3]}
    nameOfModule=${vector_path[-4]}
    compilers=${vector_path[-2]}-${vector_path[-1]}
elif [ $customPath = '3' ]; then
    filedir=${installation_path}/${vector_path[-3]}
    version=${vector_path[-2]}
    nameOfModule=${vector_path[-3]}
    compilers=${vector_path[-1]}

fi

create_directory ${filedir}

echo -e "${GREEN}Module Directory:${NC} " $filedir
echo -e "${GREEN}App Version:${NC} " $version
echo -e "${GREEN}App Name:${NC} " $nameOfModule


echo -e "${YELLOW}${BOLD}Write your name:${NC} "

while  
  read -e -p "$PS2" author
  [ -z "$author" ]
do true; done

echo -e "${YELLOW}${BOLD}Write the name of the dependencies and it's versions:${NC}"
echo -e "${YELLOW}${BOLD}* (This information is going to be written in the whatis() section and will search for corresponding modules ${NC}"
echo -e "${YELLOW}${BOLD}* make sure those modules have been created) ${NC}"
echo -e "${YELLOW}${BOLD}* Write None if you don't have any. ${NC}"
echo -e "${YELLOW}${BOLD}* Don't use white spaces or quotation marks, don't start or end with white spaces.${NC}"
echo -e "${YELLOW}${BOLD}* Only use a comma to separate them. ${NC}"
echo -e "${YELLOW}${BOLD}* Example: lapack/3.0,fftw/4.2,gcc/8.4.0${NC}"
echo -e "${YELLOW}${BOLD}* Example: None${NC}"

while
  read -e -p "$PS2" libraries
  [ -z "$libraries" ]
do true; done

IFS="," read -ra vector_libraries <<<"${libraries}"

if [ $customPath = '1' ] || [ $customPath = '4' ]; then

    echo -e "${YELLOW}${BOLD}Write the name of the compilers and it's versions:${NC}"
    echo -e "${YELLOW}${BOLD}* (This information is going to be written in the whatis() section )${NC}"
    echo -e "${YELLOW}${BOLD}* Example: gcc-4.9.4_cuda-7.0${NC}"

    while
      read -e -p "$PS2" compilers
      [ -z "$compilers" ]
    do true; done

fi

echo -e "${YELLOW}${BOLD}Write the name of the set intructions used when the application was compiled:${NC}"
echo -e "${YELLOW}${BOLD}If you are not sure, write 'generic'.${NC}"
echo -e "${YELLOW}${BOLD}* Example: AVX512${NC}"
echo -e "${YELLOW}${BOLD}* Example: AVX2${NC}"
echo -e "${YELLOW}${BOLD}* Example: generic${NC}"

while
  echo -n "> "
  read set_instructions
  [ -z "$set_instructions" ]
do true; done



if [ $set_instructions = 'generic' ]; then
    filename=$filedir/${version}_${compilers}".lua"

else
    filename=$filedir/${version}_${compilers}_${set_instructions}".lua"
fi



>$filename
cat <<EOF >>$filename
help([[
    Module file for $nameOfModule version: $version
    module load $nameOfModule/$version
    Written by $author
]])
EOF

cat <<EOF >>$filename

whatis("Name:  $nameOfModule")
whatis("Version:  $version")
whatis("Compilers: $compilers")
whatis("Set Instructions: $set_instructions")
whatis("System: $sys")
whatis("Libraries: $libraries")

conflict("$nameOfModule")

EOF

#Ask if the user is going to add pre-requisit modules
#If the answer is 'y' o 'Y', read the name of the module
#If the module doesn't exists, prints an error message
#Then ask again if the user is going to add pre-requisit modules

condition=false
pre_requisites="depends_on("

if [ $libraries != 'None' ]; then

    where_to_modules

    FIRST_TRY_ERROR=0
    cont=0
    for module in "${vector_libraries[@]}"
    do
        if [ -f $pre_requisites_modules_path/$module.lua ]; then
            echo -e "${YELLOW}${BOLD}* Lua Module detected! ${NC}"
            pre_requisites+="'$module',"
        elif [ -f $pre_requisites_modules_path/$module ]; then
            echo -e "${YELLOW}${BOLD}* TCL Module detected! ${NC}"
            pre_requisites+="'$module',"
        else
            if [ $cont = 0 ]; then
            FIRST_TRY_ERROR=1
            fi
            echo -ne "${RED}${BOLD}ERROR: ${NC}"
            echo -e "${RED}${BOLD}Module not found, will not be added${NC}"
            echo "path of module: $pre_requisites_modules_path"
            echo "$module"
        fi
        ((cont=cont+1))
    done

    pre_requisites=${pre_requisites:0:${#pre_requisites}-1}
    pre_requisites+=")"
    if [ $FIRST_TRY_ERROR = 1 ] && [ $cont = 0 ]; then
        pre_requisites=''
    fi

    echo -e "${GREEN}${BOLD}$pre_requisites${NC}"
else
    condition=true
fi

if [ $condition = 'false' ]; then
    echo $pre_requisites >>$filename
fi

#Ask if the user is going to set environment variables
#If the answer is 'y' o 'Y', read the name of the variable and its value
#If the value contains spaces, the user has to add them at the beginning
#and at the end.
#Then ask again if the user is going to set environment variables

echo -e "${YELLOW}${BOLD}The following loop is for you to add an environmental variable or various${NC}"
echo -e "${YELLOW}${BOLD}Just press [N/n] whenever you are finished setting them, ${NC}"
echo -e "${YELLOW}${BOLD}or if you choose to skip this section${NC}"

while :; do
    echo -e "${YELLOW}${BOLD}Are you going to set an environment variable? [Y/n] :${NC}"
    echo -n "[yes] >>> "
    read temp
    if [ -z $temp ] || [ $temp = Y ] || [ $temp = y ]; then

        echo -ne "${YELLOW}${BOLD}ADVISE:${NC}"
        echo -e "${YELLOW}Don't use spaces or quotation marks.${NC}"
        echo -e "${YELLOW}write the variable folowed with an equal sign and the value${NC}"
        echo -e "${YELLOW}Ex: ENVIRONMENTAL_VAR=ENVIRONMENTALVALUE ${NC}"
        echo -e "${YELLOW}Write the environmental variable:${NC} "

        while  
            read -e -p "$PS2" var
            [ -z "$var" ]
        do true; done

        IFS="=" read -ra vector_var <<<"${var}"

        tempEnv=${vector_var[0]}
        pathEnv=${vector_var[1]}

        cat <<EOF >>$filename

setenv("$tempEnv","$pathEnv")

EOF
    elif [ $temp = N ] || [ $temp = n ]; then
        break
    fi

done

#Verify if the directories bin, lib, lib64, include, lib/pkgconfig and
#share/man exist. In affirmative case, if writes in the modulefile the
#lines of prepend-path of each existing directory.

if [ -d $topdir/bin ]; then
    cat <<EOF >>$filename
prepend_path("PATH","$topdir/bin")
EOF
fi

if [ -d $topdir/sbin ]; then
    cat <<EOF >>$filename
prepend_path("PATH","$topdir/sbin")
EOF
fi

if [ -d $topdir/lib ]; then
    cat <<EOF >>$filename

prepend_path("LD_LIBRARY_PATH","$topdir/lib")
prepend_path("LIBRARY_PATH","$topdir/lib")
prepend_path("LD_RUN_PATH","$topdir/lib")

EOF
fi

if [ -d $topdir/lib32 ]; then
    cat <<EOF >>$filename

prepend_path("LD_LIBRARY_PATH","$topdir/lib32")
prepend_path("LIBRARY_PATH","$topdir/lib32")
prepend_path("LD_RUN_PATH","$topdir/lib32")

EOF
fi

if [ -d $topdir/lib64 ]; then
    cat <<EOF >>$filename

prepend_path("LD_LIBRARY_PATH","$topdir/lib64")
prepend_path("LIBRARY_PATH","$topdir/lib64")
prepend_path("LD_RUN_PATH","$topdir/lib64")

EOF
fi

if [ -d $topdir/include ]; then
    cat <<EOF >>$filename

prepend_path("C_INCLUDE_PATH","$topdir/include")
prepend_path("CXX_INCLUDE_PATH","$topdir/include")
prepend_path("CPLUS_INCLUDE_PATH","$topdir/include")

EOF
fi

if [ -d $topdir/include/$nameOfModule ]; then
    cat <<EOF >>$filename

prepend_path("C_INCLUDE_PATH","$topdir/include/$nameOfModule")
prepend_path("CXX_INCLUDE_PATH","$topdir/include/$nameOfModule")
prepend_path("CPLUS_INCLUDE_PATH","$topdir/include/$nameOfModule")

EOF
fi

if [ -d $topdir/lib/pkgconfig ]; then
    cat <<EOF >>$filename

prepend_path("PKG_CONFIG_PATH","$topdir/lib/pkgconfig")
EOF
fi

if [ -d $topdir/lib32/pkgconfig ]; then
    cat <<EOF >>$filename
prepend_path("PKG_CONFIG_PATH","$topdir/lib32/pkgconfig")
EOF
fi

if [ -d $topdir/lib64/pkgconfig ]; then
    cat <<EOF >>$filename
prepend_path("PKG_CONFIG_PATH","$topdir/lib64/pkgconfig")

EOF
fi

if [ -d $topdir/share/man ]; then
    cat <<EOF >>$filename

prepend_path("MANPATH","$topdir/share/man")

EOF
fi

echo -e "${GREEN}${BOLD}Module Written Succesfully!!${NC}"
