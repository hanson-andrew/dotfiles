dotfiles_dir=~/dotfiles

sudo rm -rf ~/.zshrc > /dev/null 2>&1

ln -sf $dotfiles_dir/home/ahanson/.zshrc ~/.zshrc

sudo chsh -s /bin/zsh

