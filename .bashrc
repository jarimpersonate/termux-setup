# Username
USER_NAME="$(whoami)"

# Prompt PS1
PS1='\[\e[1;35m\]'"${USER_NAME}"'@\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[1;33m\]$\[\e[0m\] '

# Format waktu untuk perintah history
HISTTIMEFORMAT="%F %T "

export XDG_CONFIG_HOME="$HOME/.config"
[[ ! -d "$XDG_CONFIG_HOME" ]] && mkdir -p "$XDG_CONFIG_HOME"

# Tambahkan direktori bin pengguna ke PATH
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Tambahkan direktori bin pengguna ke PATH
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

# Aktifkan dukkungan warna $LS_COLORS
if [[ -n "$(command -v dircolors)" ]]; then
	export DIRCOLORS_CONFIG_FILE="$XDG_CONFIG_HOME/dircolors.sh"
	# Buat file config dircolors dari database (default), jika tidak ada
	[[ ! -r "$DIRCOLORS_CONFIG_FILE" ]] && dircolors --print-database > "$DIRCOLORS_CONFIG_FILE"

	[[ -r "$DIRCOLORS_CONFIG_FILE" ]] && eval "$(dircolors -b $DIRCOLORS_CONFIG_FILE)"
	# Buat juga alias yang relevan
	alias ls="ls --color=auto"
	alias grep="grep --color=auto"
fi

# Source file .bash_aliases untuk kustomisasi alias yang lainnya
[[ -r "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"

# Aktifkan python virtual environment
if [[ -r "$HOME/.venv/bin/activate" ]]; then
	source "$HOME/.venv/bin/activate"
	if [[ -d "$HOME/.venv/share/man" ]]; then
		makewhatis "$HOME/.venv/share/man"
		export MANPATH="$HOME/.venv/share/man:$MANPATH"
	fi
fi
