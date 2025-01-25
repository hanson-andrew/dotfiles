dotfiles_dir=~/.dotfiles

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

sudo rm -rf ~/.zshrc > /dev/null 2>&1
sudo rm -rd ~/.p10k.zsh > /dev/null 2>&1

ln -sf $dotfiles_dir/home/ahanson/.zshrc ~/.zshrc
ln -sf $dotfiles_dir/home/ahanson/.p10k.zsh ~/.p10k.zsh

sudo chsh -s /bin/zsh

