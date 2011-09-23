# All the aliases a sysadmin could want.

# Ever accidently remove something very important with rm? Let's fix that. Also, no -rf required for folders!
rm () { mv $1 /tmp/Trash; }
alias emptytrash="/bin/rm -rf /tmp/Trash/*"

# Apt stuff
alias install="apt-get -y install "
alias update="apt-get -y -q update"
alias upgrade="apt-get -y -q update && apt-get -y -q upgrade"
alias remove="apt-get -y remove"
alias uninstall="apt-get -y remove"
alias purge="sudo apt-get -y remove --purge"

# Handy git aliases
alias ga="git add -A --ignore-errors"
alias gc="git commit -a"
alias gs="git status"
alias gb="git branch"
alias gp="git push origin"
#Git feature branch
gfb () { git checkout -b $1 develop; }
#Merge feature branch
gmfb () { git checkout develop; git merge --no-ff $1; git branch -d $1; git push origin develop; }


