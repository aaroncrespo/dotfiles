#!/usr/bin/env bash

echo "SSH Key check and or generate"
	[[ -f ~/.ssh/id_rsa.pub ]] || ssh-keygen -t rsa

echo "Copying public key to clipboard. Paste it into Github account ..."
  [[ -f ~/.ssh/id_rsa.pub ]] && cat ~/.ssh/id_rsa.pub | pbcopy
  open https://github.com/account/ssh

echo "Installing RVM (Ruby Version Manager) ..."
  curl -L https://get.rvm.io | bash -s stable --ruby

echo "Installing Bundler to build gem dependencies ..."
  gem install bundler --no-rdoc --no-ri

echo "Installing Rails to write and run web applications ..."
  gem install rails --no-rdoc --no-ri

echo "Installing the Heroku gem to interact with the http://heroku.com API ..."
  gem install heroku --no-rdoc --no-ri

echo "Installing the foreman gem for serving your Rails apps in development mode ..."
  gem install foreman --no-rdoc --no-ri

echo "Installing Homebrew, a good OS X package manager ..."
  ruby <(curl -fsS https://raw.github.com/mxcl/homebrew/go)
  brew update

echo "Installing coreutils"
	brew install coreutils

echo "Installing brews"
	brew install git
	brew install apple-gcc42

echo "dotfiles"
	git  clone git://github.com/aaroncrespo/dotfiles.git /dotfiles
	cp -R dotfiles/bash/ ~/
	cp -R dotfiles/git/ ~/
	cp -R dotfiles/vim/ ~/
	./dotfiles/osx

echo "cleanup"
	rm -r dotfiles