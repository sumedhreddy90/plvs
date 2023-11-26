#!/usr/bin/env bash


. config.sh  # source configuration file and utils 

# ====================================================

print_blue '================================================'
print_blue "Building ROS catkin packages"
print_blue '================================================'

set -e 

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) # get script dir (this should be the main folder directory of PLVS)
SCRIPT_DIR=$(readlink -f $SCRIPT_DIR)  # this reads the actual path if a symbolic directory is used
cd $SCRIPT_DIR # this brings us in the actual used folder (not the symbolic one)
#echo "current dir: $SCRIPT_DIR"

UBUNTU_VERSION=$(lsb_release -a 2>&1)  # to get ubuntu version 

# ====================================================
# check if we have external options
EXTERNAL_OPTION=$1
if [[ -n "$EXTERNAL_OPTION" ]]; then
    echo "external option: $EXTERNAL_OPTION" 
fi

# check if we set a C++ standard
if [[ -n "$CPP_STANDARD_VERSION" ]]; then
    echo "forcing C++$CPP_STANDARD_VERSION compilation"	
    echo "CPP_STANDARD_VERSION: $CPP_STANDARD_VERSION" 
    EXTERNAL_OPTION="$EXTERNAL_OPTION -DCPP_STANDARD_VERSION=$CPP_STANDARD_VERSION -DCMAKE_CXX_STANDARD=$CPP_STANDARD_VERSION"
    #-DCMAKE_CXX_FLAGS+=-std=c++$CPP_STANDARD_VERSION
fi

# check the use of local opencv
if [[ -n "$OpenCV_DIR" ]]; then
    echo "OpenCV_DIR: $OpenCV_DIR" 
    EXTERNAL_OPTION="$EXTERNAL_OPTION -DOpenCV_DIR=$OpenCV_DIR"
    export OpenCV_DIR=$OpenCV_DIR  
fi

# check CUDA options
if [ $USE_CUDA -eq 1 ]; then
    echo "USE_CUDA: $USE_CUDA" 
    EXTERNAL_OPTION="$EXTERNAL_OPTION -DWITH_CUDA=ON"
fi

if [[ $OPENCV_VERSION == 4* ]]; then
    EXTERNAL_OPTION="$EXTERNAL_OPTION -DOPENCV_VERSION=4"
fi

print_blue  "external option: $EXTERNAL_OPTION"
# ====================================================

# create the ros workspace folder 
if [ ! -d ros_ws/src ]; then
	mkdir -p ros_ws/src
fi

# install catkin tools
if [ $INSTALL_CATKIN_TOOLS -eq 1 ]; then
    if [[ $UBUNTU_VERSION == *"18.04"* ]] ; then
        DO_INSTALL_CATKIN_TOOLS=$(check_package python-catkin-tools)
        echo "DO_INSTALL_CATKIN_TOOLS $DO_INSTALL_CATKIN_TOOLS"
        if [ $DO_INSTALL_CATKIN_TOOLS -eq 1 ] ; then
            print_blue "installing catkin tools..."
            sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -sc` main" > /etc/apt/sources.list.d/ros-latest.list'
            wget http://packages.ros.org/ros.key -O - | sudo apt-key add -
            sudo apt-get update
            sudo apt-get install python-catkin-tools
            print_blue "...done"
        fi
    else
        DO_INSTALL_CATKIN_TOOLS=$(check_package python3-catkin-tools)
        echo "DO_INSTALL_CATKIN_TOOLS $DO_INSTALL_CATKIN_TOOLS"
        if [ $DO_INSTALL_CATKIN_TOOLS -eq 1 ] ; then
            print_blue "installing catkin tools..."
            sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -sc` main" > /etc/apt/sources.list.d/ros-latest.list'
            wget http://packages.ros.org/ros.key -O - | sudo apt-key add -
            sudo apt-get update
            sudo apt-get install python3-catkin-tools
            print_blue "...done"
        fi
    fi
fi

# install catkin_simple
#if [ ! -d ros_ws/src/catkin_simple ]; then
    #print_blue "downloading catkin_simple..."
	#cd ros_ws/src
	#git clone https://github.com/catkin/catkin_simple.git catkin_simple
	#cd $SCRIPT_DIR
#fi

# download and recompile vision_opencv
if [ $USE_LOCAL_OPENCV -eq 1 ]; then
    cd ros_ws/src
    if [ ! -d vision_opencv-$ROS_DISTRO ]; then
        print_blue "downloading vision_opencv-$ROS_DISTRO stack ... "

        wget https://github.com/ros-perception/vision_opencv/archive/$ROS_DISTRO.zip
        unzip $ROS_DISTRO.zip 
        rm $ROS_DISTRO.zip 
        print_blue "...done"	    
    fi
    # if [ ! -d image_common-$ROS_DISTRO-devel ]; then
    #     print_blue "downloading image_common-$ROS_DISTRO stack... "

    #     wget https://github.com/ros-perception/image_common/archive/$ROS_DISTRO-devel.zip
    #     unzip $ROS_DISTRO-devel.zip 
    #     rm $ROS_DISTRO-devel.zip 

    #     print_blue "...done"	    
    # fi    
    cd $SCRIPT_DIR
fi

# install zed camera stuff  ( you need to install the last zed camera SDK )
if [ $USE_ZED_CAMERA -eq 1 ]; then
    if [ ! -d ros_ws/src/zed-ros-wrapper ]; then
        print_blue "downloading zed ros wrapper... "
        #sudo apt-get install libcublas10 
        #if [ ! -d /usr/local/cuda-10.1 ]; then
        #	sudo ln -s /usr/lib/x86_64-linux-gnu/stubs/libcublas.so /usr/local/cuda-10.1/lib64/libcublas.so
        #fi
        #if [ -d /usr/local/cuda ] && [ -f /usr/lib/x86_64-linux-gnu/libcublas.so ]; then
        #    sudo ln -sf /usr/lib/x86_64-linux-gnu/libcublas.so /usr/local/cuda/lib64/libcublas.so
        #fi
        cd ros_ws/src
        #git clone https://gitlab.com/pctools/zed_ros_wrapper.git zed-ros-wrapper
        git clone https://github.com/stereolabs/zed-ros-wrapper.git 
        USED_ZED_WRAPPER_REVISION=24f00b6
        git checkout $USED_ZED_WRAPPER_REVISION
        cd $SCRIPT_DIR
    fi
fi

# install realsense stuff
if [ $USE_REALSENSE_D435 -eq 1 ]; then
    DO_INSTALL_REALSENSE=$(check_package librealsense2-dev)
    echo "DO_INSTALL_REALSENSE $DO_INSTALL_REALSENSE"

    # these are alread installed by the script install_dependencies.sh 
    # if [ $DO_INSTALL_REALSENSE -eq 1 ] ; then
    #     # install Intel® RealSense™ SDK 2.0 ( from https://github.com/IntelRealSense/librealsense/blob/master/doc/distribution_linux.md)
    #     #sudo apt-key adv --keyserver keys.gnupg.net --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE || sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE
    #     sudo mkdir -p /etc/apt/keyrings
    #     curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | sudo tee /etc/apt/keyrings/librealsense.pgp > /dev/null        
    #     sudo apt-get install apt-transport-https
    #     echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" | \
    #     sudo tee /etc/apt/sources.list.d/librealsense.list      
    #     # if [[ $UBUNTU_VERSION == *"18.04"* ]] ; then
    #     #     sudo add-apt-repository "deb http://realsense-hw-public.s3.amazonaws.com/Debian/apt-repo bionic main" -u
    #     # fi 
    #     # if [[ $UBUNTU_VERSION == *"16.04"* ]] ; then
    #     #     sudo add-apt-repository "deb http://realsense-hw-public.s3.amazonaws.com/Debian/apt-repo xenial main" -u
    #     # fi 
    #     #sudo rm -f /etc/apt/sources.list.d/realsense-public.list
    #     sudo apt-get update
    #     sudo apt-get install -y librealsense2-dkms librealsense2-utils librealsense2-dev librealsense2-dbg
    # fi

    if [ ! -d ros_ws/src/realsense2 ]; then
        print_blue "downloading realsense2... "
        cd ros_ws/src
        git clone https://github.com/intel-ros/realsense.git realsense2
        cd $SCRIPT_DIR
    fi
fi


# install elas ros
if [ $USE_ELAS_ROS -eq 1 ]; then
    if [ ! -d ros_ws/src/cyphy-elas-ros ]; then
        print_blue "downloading elas ros... "
        cd ros_ws/src
        #git clone https://github.com/jeffdelmerico/cyphy-elas-ros.git cyphy-elas-ros
        git clone https://gitlab.com/pctools/cyphy-elas-ros.git cyphy-elas-ros
        cd $SCRIPT_DIR
    fi
fi


# now install PLVS module
cd ros_ws/src
if [ ! -L plvs ]; then
    print_blue "installing plvs module... "
    ln -s ../../Examples_old/ROS/PLVS plvs
fi

#catkin_init_workspace
cd $SCRIPT_DIR/ros_ws/
print_blue "catkin init... "
catkin init
#catkin config --extend /opt/ros/$ROS_DISTRO
cd $SCRIPT_DIR

# check and install dependencies 
# rosdep update  # N.B: you should have updated rosdep first!
#rosdep install --from-paths ros_ws/src --ignore-src -r

cd ros_ws

# TODO for OpenCV 4: 
# all the ros packages require OpenCV 3, we need to replace this version "3" with nothing
# Recursively find and replace in files
# find . -type f -name "*.txt" -print0 | xargs -0 sed -i '' -e 's/foo/bar/g'

print_blue "compiling with catkin build... "
#catkin_make --cmake-args -DCMAKE_BUILD_TYPE=Release -DCATKIN_ENABLE_TESTING=False $EXTERNAL_OPTION
catkin build --cmake-args  -DCMAKE_BUILD_TYPE=Release -DCATKIN_ENABLE_TESTING=False $EXTERNAL_OPTION  # add "--verbose" option if needed 

