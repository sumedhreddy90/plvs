#!/bin/bash

# N.B.:
# 1) you can kill all the spawned terminals together by right clicking on
# the X icon on the left bar and selecting "Quit"

#echo "usage: ./${0##*/} "

source ../ros_ws/devel/setup.bash

USE_LIVE=0

# possible dataset smallOfficeDIAG.bag bigOfficeDIAG.bag outdoorDIAG.bag
RGBD_DATASET_FOLDER="$HOME/Work/datasets/rgbd_datasets/TRADR_r200"
#DATASET="smallOfficeDIAG.bag"
#DATASET="new_2018-04-06-15-52-27.bag"
DATASET="new_2018-04-06-16-21-57.bag"
#ROS_BAG_PLAY_OPTIONS="--rate 0.5"  # comment this to remove rate adjustment

USE_RVIZ=0

export CAMERA_SETTINGS="../Settings/r200.yaml"

#export REMAP_COLOR_TOPIC="/camera/rgb/image_raw:=/camera/rgb/image_raw"
#export REMAP_DEPTH_TOPIC="camera/depth_registered/image_raw:=/camera/depth_registered/sw_registered/image_rect_raw"

export REMAP_COLOR_TOPIC="/camera/rgb/image_raw:=/camera/rgb/image_rect_color"
export REMAP_DEPTH_TOPIC="camera/depth_registered/image_raw:=/camera/depth_registered/sw_registered/image_rect"

#export DEBUG_PREFIX="--prefix 'gdb -ex run --args'"  # uncomment this in order to debug with gdb

# ======================================================================

xterm -e "echo ROSCORE ; roscore ; bash" &
sleep 3

if [ $USE_LIVE -eq 0 ]
then
	# set before launching any node    (https://answers.ros.org/question/217588/error-in-rosbag-play-despite-setting-use_sim_time-param/)
    #rosparam set use_sim_time true
    sleep 1
fi

# ======================================================================

xterm -e "echo plvs ; rosrun $DEBUG_PREFIX  plvs RGBD ../Vocabulary/ORBvoc.txt $CAMERA_SETTINGS  $REMAP_COLOR_TOPIC  $REMAP_DEPTH_TOPIC; bash" &

# ======================================================================

if [ $USE_LIVE -eq 1 ]
then
    xterm -e "echo LIVE ; roslaunch plvs r200_nodelet_rgbd.launch ; bash" &
else
    sleep 8
    rosparam set use_sim_time true
    xterm -e "echo RECORDED ; rosbag play --clock $ROS_BAG_PLAY_OPTIONS $RGBD_DATASET_FOLDER/$DATASET; bash" &
fi

# NOTE: you can use the following command to get the xterm window live if the app terminates or crashes
# xterm -e "<you_command>; bash" &

# ======================================================================

if [ $USE_RVIZ -eq 1 ]
then
    xterm -e "echo RVIZ ; roslaunch plvs rviz_plvs.launch ; bash" &
fi

# ======================================================================

echo "DONE "

# record "/camera/rgb/image_rect_color",/camera/depth_registered/sw_registered/image_rect"

