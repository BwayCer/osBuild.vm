作業系統建造
=======


> 版本： v0.0.0

建立可選步驟的作業系統建造腳本。



## 使用方式


**1. 使用註冊器建立 殼層腳本命令次序 的腳本：**

```sh
# ./bin/shorderRegister <殼層腳本命令次序目錄>
./bin/shorderRegister ./example/sample
```

成功執行後會在 `./example/sample` 目錄下自動建立的可執行腳本。


**2. 執行 殼層腳本命令次序 的腳本：**


```sh
# 本地端可直接執行
./example/sample/sample.os.sh

# 遠端主機可參考以下命令
sh <(curl http://<host>:<port>/path/to/sample.os.sh)
```

```
sh <(curl http://192.168.100.80:8023/src/startPrivateVmPass.sh)
sh <(curl http://192.168.100.80:8023/src/Ariados.arch.sh) 9-11,4,12-14,5,15-18
sh <(curl http://192.168.100.80:8023/src/Ariados.arch.sh) 6-7,20-23,27,28
```

