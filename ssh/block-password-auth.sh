#!/bin/bash

# SSH configuration is now handled during container build
# This script only starts the SSH daemon

/usr/sbin/sshd -D