cp .zshrc ~/
cp .vimrc ~/
cp -r .vim ~/
cp -r .oh-my-zsh ~/
cp -r elisp ~/
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/godlygeek/tabular ~/.vim/pack/plugins/start/tabular
git clone https://github.com/ervandew/supertab ~/.vim/pack/plugins/start/supertab
cp .gitconfig ~/
