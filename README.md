# mysql_restore

```text
------------------                          ------------------                        
|                 |                         |                 |
|       A         |          sync >         |       b         |           
|                 |                         |                 |
-------------------                         -------------------
```
a为需要备份的机器，b为接收备份的机器
> a和b需要实现root用户的ssh互信

使用方式很简单：
1. 修改user、passwd、host变量设置为a机器上mysql信息
2. 修改remote、remote_dir为b机器的主机信息
3. 数据库默认为3306
4. 基于xtrbackup工具，修改tools变量指定xtrbackup目录的位置

在a节点备份
```bash
bash backup.sh backup
```


在b节点实现预备份
```bash
bash backup.sh restore
```

>只有第一次执行时才是全量备份，接下基于全量进行增量备份。
>a节点将在/root/.backup下生成备份数据，b节点将在/root/.restore生成接收的备份数据

# 实践
脚本可以结合crontab服务，进行周而复始的调用，作为用户只需要控制好备份间隔
