#! /bin/bash

set -e

function wait() {
	read -p "Enter when ready to continue, otherwise ctrl-c"
}

echo
read -p "walk through manual setup steps? [Y/n] " do_manual_steps
if [[ "${do_manual_steps}" != "n" ]] ; then
	echo "starting manual setup steps..."

	echo
	echo "Opening about settings.  Set the following:"
	echo "- Name: something reasonable"
	open x-apple.systempreferences:com.apple.SystemProfiler.AboutExtension
	wait

	echo
	echo "Opening sharing settings.  Set the following:"
	echo "- Remote Login: true"
	open x-apple.systempreferences:com.apple.Sharing-Settings.extension
	wait

	echo
	echo "Opening sound settings.  Set the following:"
	echo "- Alert volume = 0"
	echo "- Play sound on startup = false"
	echo "- Play user interface sound effects = false"
	open x-apple.systempreferences:com.apple.Sound-Settings.extension
	wait

	echo
	echo "Opening trackpad settings.  Set the following:"
	echo "- Scroll & Zoom > Natural scrolling = false"
	open x-apple.systempreferences:com.apple.Trackpad-Settings.extension
	wait

	echo
	echo "Opening keyboard settings.  Set the following:"
	echo "- Keyboard Shortcuts > Modifier Keys > Caps Lock = Control"
	echo "- App Shortcuts > + Application = Safari, Menu title = 'Show Sidebar', Keyboard Shortcut = Ctrl + Shift + Cmd + L"
	echo "- App Shortcuts > + Application = Safari, Menu title = 'Hide Sidebar', Keyboard Shortcut = Ctrl + Shift + Cmd + L"
	open x-apple.systempreferences:com.apple.Keyboard-Settings.extension
	wait

	echo
	echo "Opening desktop & dock settings.  Set the following:"
	echo "- Desktop & Dock > Automatically hide and show the Dock = true"
	echo "- Desktop & Dock > Show suggested and recent apps in Dock = false"
	echo "- Desktop & Dock > Click wallpaper to reveal desktop = Only in Stage Manager"
	open x-apple.systempreferences:com.apple.Desktop-Settings.extension
	wait

	echo
	echo "Opening battery settings.  Set the following:"
	echo "- Battery > Low Power Mode = Only on Battery"
	open x-apple.systempreferences:com.apple.Battery-Settings.extension
	wait

	echo
	echo "Opening wallpaper settings.  Set the following:"
	echo "- Wallpaper > Colors: Black"
	open x-apple.systempreferences:com.apple.Wallpaper-Settings.extension
	wait

	echo
	echo "Opening Internet Accounts seettings.  Set the following:"
	echo "- Internet Accounts > Add Account > Add google account for contacts only"
	open x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension
	wait

	echo
	echo "Opening lock screen seettings.  Set the following:"
	echo "- Lock Screen > Turn display off on battery when inactive: for 10 minutes"
	open x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension
	wait

	echo
	echo "Opening Passwords settings.  Set the following:"
	echo "- Autofill Passwords and Passkeys: false"
	open x-apple.systempreferences:com.apple.Passwords-Settings.extension
	wait
else
	echo "skipping manual setup steps"
fi

# One interactive sudo prompt to make everything else smoother.
echo
sudo true

echo
echo -n "checking ssh authorized keys ... "
if [[ -d ~/.ssh ]] ; then
	echo "already set up"
else
	echo "needs setup"

	echo -n "- creating ssh directory ... "
	mkdir -p ~/.ssh
	echo "success"

	echo -n "- setting ssh directory permissions ... "
	chmod 0700 ~/.ssh
	echo "success"

	echo -n "- downloading public keys from github ... "
	curl https://github.com/krelinga.keys > ~/.ssh/authorized_keys 2>/dev/null
	echo "success"

	echo -n "- setting authorized_keys file permissions ... "
	chmod 0600 ~/.ssh/authorized_keys
	echo "success"
fi

changed_any_ssh_setting=false
function ssh_setup() {
	local prompt="$1"
	local string="$2"

	echo -n "checking SSH login config: $prompt ... "
	if grep -qxF "$string" /etc/ssh/sshd_config ; then
		echo "already configured"
	else
		echo "$string" | sudo tee -a /etc/ssh/sshd_config > /dev/null
		echo "added config"
		changed_any_ssh_setting=true
	fi
}

echo
ssh_setup "do not allow passwords          " "PasswordAuthentication no"
ssh_setup "do not permit root login        " "PermitRootLogin no"
ssh_setup "do not permit empty passwords   " "PermitEmptyPasswords no"
ssh_setup "do not permit challenge/response" "ChallengeResponseAuthentication no"
if $changed_any_ssh_setting ; then
	echo -n "Restarting ssh sever ... "
	sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
	sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
	echo "success"
fi

echo
echo -n "checking mac CLI dev tooling ... "
if xcode-select -p > /dev/null 2> /dev/null ; then
	echo "already installed"
else
	echo "opening prompt"
	sudo xcode-select --install
	wait
fi

