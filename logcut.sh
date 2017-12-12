#!/bin/env bash

#获取上一小时日期字符串
SUFFIX=`date -d '-1 hours' +%Y%m%d%H`
EXCLUDE_FILE="*.`date '+%Y'`*"

#获取配置文件
function getConfig()
{
    logF=`echo $1 | awk '{print substr($i,18)}'`.conf
    if [ ! -e config/$logF ]; then
        return 1;
    else 
        echo $logF;
	return 0;
    fi
}
    
#获取不需要切割的文件
function getNoCut()
{
    cut=`cat config/$1 | jq '.nocut[]' -r`
    grepv=""
    for nocut in $cut; do
        grepv="$grepv |grep -Ev  \"$nocut\""
    done
	echo $grepv;
}

#重启
function reLoad ()
{
	signal=`cat config/$1 | jq '.signal' -r`
	$($signal)
} 

function mvFile() 
{
    	isReload=0;
	if [ ! -e $1.$SUFFIX ];then
        	mv $1 $1.$SUFFIX
		isReload=1;
	fi	
        touch $1
    	if [ $isReload -eq 1 ];then
		reLoad $2;
	fi;
}

#循环log下所有目录
for i in `find /xxx/log/* -type d`; do
    #获取配置文件
    logF=$(getConfig $i);
    if [ $? == 1 ]; then
        continue
    fi
    #获取不需要切割的文件
    noCut=$(getNoCut $logF);
    #循环所有文件、排除不需要切割的文件
    for path in $(eval find $i -type f ! -name $EXCLUDE_FILE -size +0 $noCut); do
	mvFile $path $logF;
    done
done
