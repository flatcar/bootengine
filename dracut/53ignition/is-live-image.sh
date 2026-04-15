#!/bin/bash

re='\b(mount\.)?usr=\S'
[[ $(< /proc/cmdline) =~ ${re} || ! -f /usr.squashfs ]]
