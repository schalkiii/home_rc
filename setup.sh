#git remote add zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
#git subtree add --prefix=.oh-my-zsh/custom/plugins/zsh-autosuggestions zsh-autosuggestions master --squash
#git remote add zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
#git subtree add --prefix=.oh-my-zsh/custom/plugins/zsh-syntax-highlighting zsh-syntax-highlighting master --squash
#git remote add tabular https://github.com/godlygeek/tabular.git
#git subtree add --prefix=.vim/pack/plugins/start/tabular tabular master --squash
#git remote add supertab https://github.com/ervandew/supertab.git
#git subtree add --prefix=.vim/pack/plugins/start/supertab supertab master --squash
cp .zshrc ~/
cp .vimrc ~/
cp -r .vim ~/
cp -r .oh-my-zsh ~/
cp -r elisp ~/
gvim -c "%so"  .vim/plugin/supertab.vmb

git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/godlygeek/tabular ~/.vim/pack/plugins/start/tabular
git clone https://github.com/ervandew/supertab ~/.vim/pack/plugins/start/supertab
cp .gitconfig ~/
