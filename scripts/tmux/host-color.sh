#!/usr/bin/env bash

colors=("#FF8F40" "#E6B450" "#AAD94C" "#59C2FF" "#D2A6FF" "#F07178" "#39BAE6" "#FFB454")
hash=$(uname -n | cksum | cut -d' ' -f1)
tmux set -g @host-color "${colors[hash % ${#colors[@]}]}"
