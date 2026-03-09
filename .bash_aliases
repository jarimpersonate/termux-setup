#!/data/data/com.termux/files/usr/bin/bash

# Alias Dasar dan Sistem
alias ll="ls -l --almost-all --human-readable --classify"
alias ln="ln --interactive --verbose"
alias c="clear"
alias q="exit"
alias upg="apt update && apt full-upgrade"
alias mkdir="mkdir --verbose"
alias mv="mv --interactive"
alias cp="cp --interactive"
alias rm="rm --interactive"
alias rmdir="rmdir --verbose"
alias nano="nano --modernbindings"
alias securedel="shred -u --force --zero --verbose"

if [[ -n "$(command -v openssl)" ]]; then
	alias sslenc="openssl enc -e -pbkdf2 -salt -v"
	alias ssldec="openssl enc -d -pbkdf2 -salt -v"
fi

if [[ -n "$(command -v python)" || -n "$(command -v python3)" ]]; then
	alias py="python"
	alias py3="python3"
fi

if [[ -n "$(command -v proot-distro)" ]]; then
	alias debian-login="proot-distro login debian --shared-tmp"
fi
