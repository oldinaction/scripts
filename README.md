
## 使用

```
# 法1(需要是raw类型的连接)。tee 实时重定向日志(同时也会在控制台打印，并且可进行交互)
source <(curl -L https://raw.githubusercontent.com/oldinaction/scripts/master/shell/prod/conf-recode-cmd-history.sh) 2>&1 | tee my.log # 此处 source 也可改成 bash
# 法2(需要是raw类型的连接)
wget --no-check-certificate https://raw.githubusercontent.com/oldinaction/scripts/master/shell/prod/conf-recode-cmd-history.sh && bash bbr.sh 2>&1 | tee my.log
```