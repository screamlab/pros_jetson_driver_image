FROM ghcr.io/screamlab/pros_base_image:latest
ENV ROS2_WS /workspaces
ENV ROS_DOMAIN_ID=1
ENV ROS_DISTRO=humble
ARG THREADS=4
ARG TARGETPLATFORM

SHELL ["/bin/bash", "-c"]

##### Copy Source Code #####
COPY . /tmp

##### Environment Settings #####
WORKDIR ${ROS2_WS}

# System Upgrade
RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt autoclean -y && \

    pip3 install --no-cache-dir --upgrade pip

##### colcon Installation #####
# Copy Source Code
RUN mkdir -p ${ROS2_WS}/src && \
    mv /tmp/src/* ${ROS2_WS}/src && \

# Bootstrap rosdep and setup colcon mixin and metadata ###
    rosdep update --rosdistro $ROS_DISTRO && \
    colcon mixin update && \
    colcon metadata update && \

# Install the system dependencies for all ROS packages located in the `src` directory.
    rosdep install -q -y -r --from-paths src --ignore-src

### Rplidar Installation ###
RUN apt install ros-${ROS_DISTRO}-navigation2 ros-${ROS_DISTRO}-nav2-bringup -y && \
    . /opt/ros/humble/setup.sh && \
    colcon build --packages-select rplidar_ros --symlink-install --parallel-workers ${THREADS} --mixin release && \
    colcon build --packages-select csm --symlink-install --parallel-workers ${THREADS} --mixin release && \
    colcon build --packages-select ros2_laser_scan_matcher --symlink-install --parallel-workers ${THREADS} --mixin release && \
    colcon build --packages-select slam_toolbox --symlink-install --parallel-workers ${THREADS} --mixin release && \

    apt install ros-humble-rplidar-ros

### Astra Camera Installation ###
# install dependencies
RUN apt install -y libgflags-dev ros-${ROS_DISTRO}-image-geometry ros-${ROS_DISTRO}-camera-info-manager \
                    ros-${ROS_DISTRO}-image-transport ros-${ROS_DISTRO}-image-publisher && \
    apt install -y libgoogle-glog-dev libusb-1.0-0-dev libeigen3-dev libopenni2-dev nlohmann-json3-dev && \
    apt install ros-${ROS_DISTRO}-image-transport-plugins -y && \
    git clone https://github.com/libuvc/libuvc.git /temp/libuvc && \
    mkdir -p /temp/libuvc/build
WORKDIR /temp/libuvc/build
RUN cmake .. && \
    make -j${THREADS} && \
    make install && \
    ldconfig

# Build
WORKDIR ${ROS2_WS}
RUN . /opt/ros/humble/setup.sh && \
    colcon build --packages-select pros_image --symlink-install --parallel-workers ${THREADS} --mixin release && \
    colcon build --packages-select astra_camera_msgs --symlink-install --parallel-workers ${THREADS} --mixin release && \
    colcon build --packages-select astra_camera --symlink-install --parallel-workers ${THREADS} --mixin release

### Dabai Camera ###
RUN . /opt/ros/humble/setup.sh && \
    colcon build --packages-select orbbec_camera_msgs --symlink-install --parallel-workers ${THREADS} --mixin release && \
    colcon build --packages-select orbbec_camera --symlink-install --parallel-workers ${THREADS} --mixin release && \
    colcon build --packages-select orbbec_description --symlink-install --parallel-workers ${THREADS} --mixin release && \

##### Post-Settings #####
# Clear tmp and cache
    rm -rf /tmp/* && \
    rm -rf /temp/* && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/ros_entrypoint.bash"]
CMD ["bash", "-l"]
