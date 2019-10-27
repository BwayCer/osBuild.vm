# /bin/bash


fnLibSay() {
    local txt="$1"
    echo "$txt"
}


#
# 範例說明
#
fnShorder_register "sayHW:Say Hello World"
fnOrder_sayHW() {
    fnLibSay "Hello World"
}

fnShorder_register "whatName:お名前は何ですか？"
fnOrder_whatName() {
    echo "What is your name ?"
}

fnShorder_register "sayBway:Say BwayCer"
fnOrder_sayBway() {
    fnLibSay "BwayCer"
}

