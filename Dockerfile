FROM ubuntu:18.04

run apt-get update && apt-get install -y software-properties-common wget

run wget -qO- https://dl.winehq.org/wine-builds/winehq.key | apt-key add -
run apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main'
run add-apt-repository ppa:cybermax-dexter/sdl2-backport

RUN apt-get update && \
    apt-get upgrade -y && \
    dpkg --add-architecture i386 && \
    apt-get update

run DEBIAN_FRONTEND=noninteractive apt-get install -y  \
						-o APT::Immediate-Configure=false \
						winehq-stable python msitools python-simplejson \
                       	python-six ca-certificates xvfb && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/msvc

#env WINEARCH=win64

COPY lowercase fixinclude install.sh vsdownload.py ./
COPY wrappers/* ./wrappers/

add http://mirrors.kernel.org/ubuntu/pool/universe/m/msitools/msitools_0.100-1_amd64.deb /tmp/msitools.deb
run dpkg -i /tmp/msitools.deb

RUN ./vsdownload.py --accept-license --dest /opt/msvc \
	Microsoft.VisualStudio.Workload.VCTools \
	Microsoft.VisualStudio.Component.VC.CMake.Project

RUN ./install.sh /opt/msvc && \
    rm lowercase fixinclude install.sh vsdownload.py && \
    rm -rf wrappers

# Initialize the wine environment. Wait until the wineserver process has
# exited before closing the session, to avoid corrupting the wine prefix.
RUN wine wineboot --init && \
    while pgrep wineserver > /dev/null; do sleep 1; done

add https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks /usr/local/bin/winetricks
run chmod +x /usr/local/bin/winetricks

RUN set -xe && \
	Xvfb :99 -screen 0 1280x1024x24 -ac & export DISPLAY=:99 && \
	export WINEARCH=win64 && \
	wineserver -w && \
    wine wineboot && \
	winetricks -q vcrun2013 vcrun2015

add https://s3.amazonaws.com/naturalpoint/software/Motive/Motive_2.2.0_Final.exe /tmp/motive.exe
run wine /tmp/motive.exe /S /v/qn

