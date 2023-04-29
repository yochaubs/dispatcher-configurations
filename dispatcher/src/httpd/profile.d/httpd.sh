
# This is for convinience if somebody is used to run "httpd -t" directly
alias httpd='bash -c "set -a && . /etc/sysconfig/httpd && exec httpd \"\${BASH_ARGV[@]}\"" sh'
