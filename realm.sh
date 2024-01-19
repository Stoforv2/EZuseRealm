#! /bin/bash
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
shell_version="1.0.3"
ct_new_ver="2.5.2"
realm_conf_path="/etc/realm/config.json"
raw_conf_path="/etc/realm/rawconf"
function checknew() {
  checknew=$(realm -V 2>&1 | awk '{print $2}')
  # check_new_ver
  echo "你的realm版本为:""$checknew"""
  echo -n 是否更新\(y/n\)\:
  read checknewnum
  if test $checknewnum = "y"; then
    cp -r /etc/realm/config.json /tmp/
    Install_ct
    rm -rf /etc/realm/config.json
    mv /tmp/config.json /etc/realm/
    systemctl restart realm
  else
    exit 0
  fi
}
function check_sys() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif cat /etc/issue | grep -q -E -i "debian"; then
    release="debian"
  elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  elif cat /proc/version | grep -q -E -i "debian"; then
    release="debian"
  elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="ubuntu"
  elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="centos"
  fi
  bit=$(uname -m)
  if test "$bit" != "x86_64"; then
    echo "请输入你的芯片架构，暂不支持arm /aarch64"
    read bit
  else
    bit="x86_64"
  fi
}
function Installation_dependency() {
  gzip_ver=$(gzip -V)
  if [[ -z ${gzip_ver} ]]; then
    if [[ ${release} == "centos" ]]; then
      yum update
      yum install -y gzip wget tar
    else
      apt-get update
      apt-get install -y gzip wget tar
    fi
  fi
}
function choose_libc_version() {
  echo "请选择需要安装的版本："
  echo "1. glibc (gnu)"
  echo "2. musl (musl)"
  read -p "输入选择（默认为 1）: " user_choice
  # 设置默认值为 gnu
  libc_type="gnu"
  # 如果用户输入了具体选项，则更新 libc_type
  if [ "$user_choice" = "2" ]; then
    libc_type="musl"
  fi
  echo "您选择的版本是：$libc_type"
}
function check_root() {
  [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}
function check_new_ver() {
  # deprecated
  ct_new_ver=$(wget --no-check-certificate -qO- -t2 -T3 https://api.github.com/repos/zhboner/realm/releases/latest | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g')
  if [[ -z ${ct_new_ver} ]]; then
    ct_new_ver="2.5.2"
    echo -e "${Error} realm 最新版本获取失败，正在下载v${ct_new_ver}版"
  else
    echo -e "${Info} realm 目前最新版本为 ${ct_new_ver}"
  fi
}
function check_file() {
  if test ! -d "/etc/systemd/system/"; then
    mkdir /etc/systemd/system
  fi
  if test ! -d "/etc/realm/"; then
    mkdir /etc/realm/
  fi
}
function check_nor_file() {
  rm -rf "$(pwd)"/realm
  rm -rf "$(pwd)"/realm.service
  rm -rf "$(pwd)"/config.json
  rm -rf /etc/realm/realm
  rm -rf /etc/systemd/system/realm.service
}
function Install_ct() {
  check_root
  check_nor_file
  Installation_dependency
  check_file
  check_sys
  # check_new_ver
  choose_libc_version
  echo -e "若为国内机器建议使用大陆镜像加速下载（暂不支持）"
  read -e -p "是否使用？（是否都为默认国外源）[y/n]:" addyn
  [[ -z ${addyn} ]] && addyn="n"
  if [[ ${addyn} == [Yy] ]]; then
    rm -rf realm-"$bit"-unknown-linux-"$libc_type".tar.gz
    wget --no-check-certificate https://github.com/zhboner/realm/releases/download/v"$ct_new_ver"/realm-"$bit"-unknown-linux-"$libc_type".tar.gz
    tar -xzf realm-"$bit"-unknown-linux-"$libc_type".tar.gz
    mv realm /etc/realm/realm
    chmod -R 777 /etc/realm/realm
    wget --no-check-certificate https://raw.githubusercontent.com/Stoforv2/EZuseRealm/master/realm.service && chmod -R 777 realm.service && mv realm.service /etc/systemd/system
    wget --no-check-certificate https://raw.githubusercontent.com/Stoforv2/EZuseRealm/master/config.json && mv config.json /etc/realm && chmod -R 777 /etc/realm
  else
    rm -rf realm-"$bit"-unknown-linux-"$libc_type".tar.gz
    wget --no-check-certificate https://github.com/zhboner/realm/releases/download/v"$ct_new_ver"/realm-"$bit"-unknown-linux-"$libc_type".tar.gz
    tar -xzf realm-"$bit"-unknown-linux-"$libc_type".tar.gz
    mv realm /etc/realm/realm
    chmod -R 777 /etc/realm/realm
    wget --no-check-certificate https://raw.githubusercontent.com/Stoforv2/EZuseRealm/master/realm.service && chmod -R 777 realm.service && mv realm.service /etc/systemd/system
    wget --no-check-certificate https://raw.githubusercontent.com/Stoforv2/EZuseRealm/master/config.json && mv config.json /etc/realm && chmod -R 777 /etc/realm
  fi

  systemctl enable realm && systemctl restart realm
  echo "------------------------------"
  if test -a /etc/realm -a /etc/systemctl/realm.service -a /etc/realm/config.json; then
    echo "realm安装成功"
    rm -rf "$(pwd)"/realm
    rm -rf "$(pwd)"/realm.service
    rm -rf "$(pwd)"/config.json
  else
    echo "realm没有安装成功"
    rm -rf "$(pwd)"/realm
    rm -rf "$(pwd)"/realm.service
    rm -rf "$(pwd)"/config.json
  fi
}
function Uninstall_ct() {
  rm -rf /etc/realm/realm
  rm -rf /etc/systemd/system/realm.service
  echo "realm已经成功删除，保留配置，若要彻底删除配置请使用 rm -rf /etc/realm "
}
function Start_ct() {
  systemctl start realm
  echo "已启动"
}
function Stop_ct() {
  systemctl stop realm
  echo "已停止"
}
function Restart_ct() {
  systemctl restart realm
  echo "已重读配置并重启"
}
function Stat_ct() {
  systemctl status realm
}

update_sh() {
  ol_version=$(curl -L -s --connect-timeout 5 https://raw.githubusercontent.com/Stoforv2/EZuseRealm/master/realm.sh | grep "shell_version=" | head -1 | awk -F '=|"' '{print $3}')
  if [ -n "$ol_version" ]; then
    if [[ "$shell_version" != "$ol_version" ]]; then
      echo -e "存在新版本，是否更新 [Y/N]?"
      read -r update_confirm
      case $update_confirm in
      [yY][eE][sS] | [yY])
        wget -N --no-check-certificate https://raw.githubusercontent.com/Stoforv2/EZuseRealm/master/realm.sh
        echo -e "更新完成"
        exit 0
        ;;
      *) ;;

      esac
    else
      echo -e "                 ${Green_font_prefix}当前版本为最新版本！${Font_color_suffix}"
    fi
  else
    echo -e "                 ${Red_font_prefix}脚本最新版本获取失败，请检查与github的连接！${Font_color_suffix}"
  fi
}

function main_menu() {
  echo && echo -e "                 realm 一键安装脚本${Red_font_prefix}[${shell_version}]${Font_color_suffix}"
  echo "  ----------- Stoforv2 -----------"
  echo "  特性: (1)本脚本采用systemd及realm配置文件对realm进行管理"
  echo "  功能: 安装 | 更新 | 快速重启"

  echo -e " ${Green_font_prefix}0.${Font_color_suffix} 退出脚本"
  echo "————————————"
  echo -e " ${Green_font_prefix}1.${Font_color_suffix} 安装 realm"
  echo -e " ${Green_font_prefix}2.${Font_color_suffix} 更新 realm"
  echo -e " ${Green_font_prefix}3.${Font_color_suffix} 卸载 realm"
  echo "————————————"
  echo -e " ${Green_font_prefix}4.${Font_color_suffix} 启动 realm"
  echo -e " ${Green_font_prefix}5.${Font_color_suffix} 停止 realm"
  echo -e " ${Green_font_prefix}6.${Font_color_suffix} 重启 realm"
  echo "————————————"
  echo -e " ${Green_font_prefix}7.${Font_color_suffix} 查看 realm 状态"
  echo -e " ${Green_font_prefix}8.${Font_color_suffix} 更新脚本"
  echo "————————————" && echo
}

while true; do
  main_menu
  read -e -p "请输入数字 [0-8]:" num
  case "$num" in
    0)
      exit 0
      ;;
    1)
      Install_ct
      read -p "按回车键返回主菜单..."
      ;;
    2)
      checknew
      read -p "按回车键返回主菜单..."
      ;;
    3)
      Uninstall_ct
      read -p "按回车键返回主菜单..."
      ;;
    4)
      Start_ct
      read -p "按回车键返回主菜单..."
      ;;
    5)
      Stop_ct
      read -p "按回车键返回主菜单..."
      ;;
    6)
      Restart_ct
      read -p "按回车键返回主菜单..."
      ;;
    7)
      Stat_ct
      read -p "按回车键返回主菜单..."
      ;;
    8)
      update_sh
      read -p "按回车键返回主菜单..."
      ;;
    *)
      echo "请输入正确数字 [0-8]"
      read -p "按回车键继续..."
      ;;
  esac
done
