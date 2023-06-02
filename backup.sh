#!/bin/bash
user=root
passwd='IDDORHwcCOtVhSt@12Whc'
host=localhost
tools=/root/xtrbackup
backdir=/root/.backup
fullback=mysql_full_backup
appendback=mysql_app_backup_$(date +'%F_%s')
remote='192.168.10.213'
remote_dir=/root/.restore


mkdir -p $backdir
mkdir -p $remote_dir

#failure
echo_fail() {
  printf "\e[31m✘ \033\e[0m$@\n"
  exit 2
}

#success
echo_pass() {
  printf "\e[32m✔ \033\e[0m$@\n"
}

#warn
echo_warn() {
  printf "\e[33m‼ \033\e[0m$@\n"
}



mysql_backup(){
    cd /root

    ssh root@$remote "mkdir -p $remote_dir"
    if [ ! -d $backdir/$fullback ];then
        $tools/bin/xtrabackup  --defaults-file=/etc/my.cnf  --user=$user --host=$host --password=$passwd  --backup --target-dir=$backdir/$fullback  
        $tools/bin/xtrabackup  --prepare --apply-log-only --target-dir=$backdir/$fullback 

        cd $backdir

        tar cvzf ${fullback}.tar.gz $fullback 
        if [ $? -eq 0 ];then
            scp ${fullback}.tar.gz root@${remote}:${remote_dir} && echo_pass "全量备份，已传输到$remote:$remote_dir" ||echo_fail "全量备份文件传输失败"
            
        else
            echo_fail "全量备份文件，打包失败。"
        fi
    elif [ ! -d $backdir/$appendback ];then
        cd $backdir
        if [ -f .up ];then
            appold=$(cat .up)
            $tools/bin/xtrabackup --defaults-file=/etc/my.cnf  --user=$user --host=$host --password=$passwd --backup --target-dir=$backdir/$appendback  --incremental-basedir=$backdir/$appold
            #echo ""

        else
            $tools/bin/xtrabackup --defaults-file=/etc/my.cnf  --user=$user --host=$host --password=$passwd --backup --target-dir=$backdir/$appendback  --incremental-basedir=$backdir/$fullback
           
        fi
        
        if [ -n "$appold" ];then
            rm -fr $appold
        fi


        echo "$appendback" >.up

        
        tar cvzf ${appendback}.tar.gz $appendback  
        if [ $? -eq 0 ];then
            scp ${appendback}.tar.gz root@$remote:${remote_dir} 
            if [ $? -eq 0 ];then
                rm -fr ${appendback}.tar.gz 
                echo_pass "增量备份${appendback}，已经传输到$remote:$remote_dir"  
            else
                echo_fail "增量备份，传输失败"
            fi
        else
            echo_fail "增量备份，打包失败"
        fi    
    fi
}


mysql_restore(){
    
    cd $remote_dir 
    append=$(ls -1tr mysql_app_backup*.tar.gz 2>/dev/null | head -n1)
    if [ -f $remote_dir/${fullback}.tar.gz ];then

        tar xf ${fullback}.tar.gz

        rm -fr ${fullback}.tar.gz
        
   

        
    elif [ -n $append ];then
         tar xf $append 
         app_name=$(echo $append|awk -F'.' '{print $1}')
         
         $tools/bin/xtrabackup  --prepare --apply-log-only --target-dir=${fullback} --incremental-dir=$app_name 
         if [ $? -eq 0 ];then
            echo_pass "预恢复成功 $(date +'%F_%T')"
            rm -fr $append $app_name
        else
            
            rm -fr $app_name
            mkdir -p nothing
            mv $append nothing
            echo_fail "预恢复失败 $(date +'%F_%T')" 

        fi
    else
        echo_warn "未发现备份 $(date +'%F_%T')"

    fi

}



case $1 in 
    restore)
        mysql_restore
        ;;

    backup)
        mysql_backup
        ;;
    *)
        echo "fuck"
        ;;
esac
