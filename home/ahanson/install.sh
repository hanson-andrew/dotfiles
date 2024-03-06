dotfiles_dir=~/dotfiles

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc

sudo rm -rf ~/.zshrc > /dev/null 2>&1

ln -sf $dotfiles_dir/home/ahanson/.zshrc ~/.zshrc

sudo chsh -s /bin/zsh

