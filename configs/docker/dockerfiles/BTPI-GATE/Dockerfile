FROM kasmweb/remnux-focal-desktop:1.16.1
USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
WORKDIR $HOME

######### Customize Container Here ###########


EXPOSE 22 443 3000 3128 3306 8000 8500 9443 10443

VOLUME ["/var/run", "/var/lib/docker/volumes", "/portainer_data"]

RUN apk update
RUN apk upgrade

RUN apk add bash
RUN apk add nano
RUN apk add curl
RUN apk add wget
RUN apk add sudo
RUN mkdir /opt/btpi-gate/
RUN echo = "127.0.0.1   {$PREFIX}-gate {$PREFIX}-gate-mgmt {$PREFIX}-gate-waf {$PREFIX}-gate-grr-g"

#-------------------------------
## Prep the Environment
WORKDIR "/opt"
RUN apk add bash tar curl
RUN curl https://raw.githubusercontent.com/cmndcntrlcyber/btpi-gate/refs/heads/main/portainer/install_portainer.sh > /opt/btpi-gate/portainer/install_portainer.sh
RUN sudo bash /opt/btpi-gate/portainer/install_portainer.sh
#-------------------------------

#-------------------------------
## Install portainer
WORKDIR "/opt"
RUN apk add bash tar curl
RUN curl https://raw.githubusercontent.com/cmndcntrlcyber/btpi-gate/refs/heads/main/portainer/install_portainer.sh > /opt/btpi-gate/portainer/install_portainer.sh
RUN sudo bash /opt/btpi-gate/portainer/install_portainer.sh
#-------------------------------

#-------------------------------
## Install Kasm
# Set up environment for Kasm installation
WORKDIR /tmp
# Add necessary tools
RUN apk add bash tar curl

## Automated Install
RUN curl https://raw.githubusercontent.com/cmndcntrlcyber/btpi-react/refs/heads/main/kasm/install_kasm.sh > /opt/btpi-gate/install_kasm.sh
RUN bash /opt/btpi-gate/install_kasm.sh

#---------------------------------
# Install Google Rapid Response
WORKDIR "/opt"
RUN apk add bash tar curl

## Automated Install
RUN curl https://github.com/cmndcntrlcyber/btpi-nexus/grr/install_grr.sh > /opt/btpi-nexus/install_grr.sh
RUN bash /opt/btpi-nexus/install_grr.sh
#---------------------------------

#-------------------------------
# Install Safeline WAF

WORKDIR "/opt"
RUN apk add bash tar curl

## Automated Install
RUN curl https://raw.githubusercontent.com/cmndcntrlcyber/btpi-gate/refs/heads/main/safeline/install_safeline.sh > /opt/btpi-gate/install_safeline.sh
RUN bash /opt/btpi-gate/install_safeline.sh
#-------------------------------

######### End Customizations ###########

RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME

ENV HOME /home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000