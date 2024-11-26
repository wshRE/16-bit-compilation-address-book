assume cs:code,ds:data
data segment 
    ;主页
 	homepage      db  "homepage select:" ,0dh,0ah,'$'
	hp1           db  "1: addition" ,0dh, 0ah,'$'
	hp2           db  "2: delete" ,0dh, 0ah,'$'
	hp3           db  "3: modify" ,0dh, 0ah,'$'
	hp4           db  "4: enquiry name" ,0dh, 0ah,'$'
 	hp5           db  "5: enquiry phone" ,0dh, 0ah,'$'
	hp6           db  "6: enquiry addr" ,0dh, 0ah, '$'
	hp7           db  "7: show all" ,0dh, 0ah,'$'
	hp8           db  "8: save save" ,0dh, 0ah,'$'
	hp9           db  "9: exit process" ,0dh, 0ah,0dh, 0ah,'$'

	;增加
    add1          db  "enter name:" ,0dh, 0ah,'$'                                  
	add2          db  "enter telephone number:" ,0dh, 0ah,'$'                      
    add3          db  "enter address:" ,0dh, 0ah,'$'                               
	add4          db  0dh, 0ah, "Information added successfully" ,0dh, 0ah,'$'  

	;删除
	del1          db  "enter name will del:" ,0dh, 0ah,'$' 

	;修改
    mod1          db  "enter old name:" ,0dh, 0ah,'$'
	mod2          db  "enter new name:" ,0dh, 0ah,'$'
	mod3          db  "enter telephone number:" ,0dh, 0ah,'$'
    mod4          db  "enter address:" ,0dh, 0ah,'$'
	mod5          db  0dh, 0ah, "change successfully" ,0dh, 0ah,'$'

	;查
    findname  db  "enter the name looking for" ,0dh, 0ah,'$' 
    findphone  db  "enter the phone looking for" ,0dh, 0ah,'$'  
    findaddr  db  "enter the addr looking for" ,0dh, 0ah,'$'

	;错误
	inputerror  db  "input error" ,0dh, 0ah, 0dh, 0ah,'$'
    ;回车换行
    enterline        db  0dh, 0ah,'$'
	spaceline        db  "    " , '$'                                
    ;分割符
    symbol      db  "------------" ,0dh, 0ah, '$'

    ;缓存
	pname   		db  50, 0ffh
    bname    		db  50 dup('$')
	pphone  		db  50, 0ffh
    bphone   		db  50 dup('$')
    paddr  			db  50, 0ffh
	baddr   		db  50 dup('$')
	datastore       db  5001 dup('$')
	total       	db  1 dup(0)
	filename   		db  "two.bin", 0h
	filenum     	db   0h, 0h
	filesavesucc  	db "save success",0dh, 0ah,'$' 
data ends

stack segment stack
	db 1000 dup(0)
stack ends

;函数声明
ReadFile proto stdcall				;读取文件并放入内存
InputChoose proto stdcall        	;功能选择,最终结果放在al
Show proto stdcall               	;显示主页
StrLen proto stdcall :word			;求字符串长度(返回值AX)
StrCpy proto stdcall  :word, :word	;字符串拷贝
StrCmpBlu proto stdcall :word, :word ;字符串模糊比较(nArg2 <= nArg1),成功ax为0
AddUser proto stdcall				;添加新用户
ShowAllUser proto stdcall            ;显示所有用户
StrCmp proto stdcall  :word, :word   ;字符串完全比较,失败ax为1,成功ax为0
DelUser proto stdcall				;删除
ModUser proto stdcall				;修改
FindUserByNameBlu proto stdcall		;通过姓名模糊查找
FindUserByPhoneBlu proto stdcall		;通过手机号模糊查找
FindUserByAddrBlu proto stdcall		;通过地址模糊查找
SaveUser proto stdcall				;保存文件

code segment

    StrCmp proc stdcall uses bx si di dx bp nArg1:word, nArg2:word 
		local @length1:word  ;字串长度
		local @length2:word  ;字串长度

		invoke StrLen, nArg1
		mov @length1,bx
		invoke StrLen, nArg2
		cmp @length1,bx
		jnz memexit
        mov si, nArg1
        mov di, nArg2
        mov cx, @length1
        repe cmpsb
		memexit:
			mov ax,cx
        	ret
    StrCmp endp

	StrCmpBlu proc stdcall uses bx si di dx bp nArg1:word, nArg2:word
		local @length1:word  
		local @length2:word 


		;求串长度
		invoke StrLen,nArg1 
		mov @length1,ax
		invoke StrLen,nArg2
		mov @length2,ax
		

		;判断是否有外循环次数
		mov ax,@length1
		cmp ax,@length2 ;@length1小的话直接结束
		jb exitblu2
		
		;求外循环次数,存储在@length1
		mov ax,@length1
		sub ax,@length2
		mov cx,ax
        mov si, nArg1
		;外循环
		cmpblu: 
			mov di, nArg2
			mov dx,@length2 ;内层循环计数器
			cld             
			repe cmpsb      ;内循环
			jz exitblu1     ;查找成功,结束函数
            inc si
			loop cmpblu     ;继续外层循环，直到cx为0
			
		exitblu2:           ;比较失败
			mov ax,1        ;将ax置为1，表示没有找到相等的子串
			jmp exitend 
		exitblu1:           ;比较成功
			mov ax,0        ;将ax置为0，表示找到了相等的子串   
		exitend:                
			ret             
	StrCmpBlu endp          

	StrCpy proc stdcall uses bx cx si di dx bp nArg1:word, nArg2:word
        mov si,nArg1
        mov di,nArg2
		mov cx,0
        ;求1的长度
        get:
            lodsb
            cmp al,'$' ;捕获到0 结束
            jz cal
            inc cx     ;计数+1 
            jmp get
        cal:
            mov si,nArg1
            mov di,nArg2
			inc cx ;把$也复制进去
            rep movsb
            ret
	StrCpy endp

	StrLen proc stdcall uses si di bp nArg1:word
        mov si, nArg1
        mov bx,0
        get:
            lodsb
            cmp al,'$' ;捕获到0 结束
            jz strlenexit
            inc bx     ;计数+1 
            jmp get
        strlenexit:
			mov ax,bx
            ret
	StrLen endp

    Show proc stdcall uses bx cx si di dx bp
        mov ah,09h
		mov dx,offset enterline
		int 21h
		
        mov ah,09h
		mov dx,offset symbol
		int 21h

		mov ah,09h
		mov dx,offset homepage
		int 21h
		
		mov ah,09h
		mov dx,offset hp1
		int 21h
		
		mov ah,09h
		mov dx,offset hp2
		int 21h 
		
		mov ah,09h
		mov dx,offset hp3
		int 21h 
		
		mov ah,09h
		mov dx,offset hp4
		int 21h 
		
		mov ah,09h
		mov dx,offset hp5
		int 21h 
		
		mov ah,09h
		mov dx,offset hp6
		int 21h 
		
		mov ah,09h
		mov dx,offset hp7
		int 21h 

		mov ah,09h
		mov dx,offset hp8
		int 21h 

		mov ah,09h
		mov dx,offset hp9
		int 21h 

        mov ah,09h
		mov dx,offset symbol
		int 21h
        ret
    Show endp
	
	InputChoose proc stdcall uses bx cx si di dx bp
		;获取键盘输入的内容
		mov ah, 01h
        int 21h

		mov ah,0
		ret
	InputChoose endp

	;完成
	AddUser proc stdcall uses  bx cx si di dx bp
		mov ah,09h
		mov dx,offset enterline
		int 21h

		;打印输入提示
		mov ah,09h
		mov dx,offset add1;打印输入姓名
		int 21h
		getnamebuff:
			;获取输入的字符串   存内存时会自动加一个字节前缀(长度)和 一个字节后缀 0d-回车
			mov ah, 0ah
			mov dx, offset pname
			int 21h

			;空判断
			mov bx, offset pname
			mov al, [bx+1]
			cmp al,0 ;无输入回车
			je getnamebuff;跳转回去			

			;打印输入内容
			mov bx, offset pname
			mov al, [bx+1];起点
			mov ah, 0
			mov si, ax ;将地址写入si
			mov bx, offset bname
			mov byte ptr [bx+si], 24h;写入$---尾部改为$
			mov ah,09h
			mov dx,offset bname;待输出的地址
			int 21h

			;换行
			mov ah,09h
			mov dx,offset enterline
			int 21h
		getphonebuff:
			;输入电话提示
			mov ah, 09h
			mov dx, offset add2
			int 21h
			
			mov ah, 0ah
			mov dx, offset pphone
			int 21h

			;检查是否是空输入
			mov bx, offset pphone
			mov al, [bx+1]
			cmp al,0
			je getphonebuff

			;打印输入内容
			mov bx, offset pphone
			mov al, [bx+1]
			mov ah, 0
			mov si, ax
			mov bx, offset bphone
			mov byte ptr [bx+si], 24h
			mov ah,09h
			mov dx,offset bphone
			int 21h
		
			;换行
			mov ah,09h
			mov dx,offset enterline
			int 21h

		getaddrbuff:
			;输入地址提示
			mov ah, 09h
			mov dx, offset add3
			int 21h
			
			mov ah, 0ah
			mov dx, offset paddr
			int 21h

			;检查是否是空输入
			mov bx, offset paddr
			mov al, [bx+1]
			cmp al,0
			je getaddrbuff

			;打印输入内容
			mov bx, offset pphone
			mov al, [bx+1]
			mov ah, 0
			mov si, ax
			mov bx, offset baddr
			mov byte ptr [bx+si], 24h
			mov ah,09h
			mov dx,offset baddr
			int 21h
		
			;换行
			mov ah,09h
			mov dx,offset enterline
			int 21h
		
		;从分类缓存写入总缓存
		;获取已经存储的个数----数据放在ax中
		mov bx,offset total		
		mov ah,0
		mov al,ds:[bx]

		;计算总缓存的尾部地址
		mov bx, offset datastore
		mov dl, 150 ;定长 一位用户长度150
		mul dl
		add bx,ax

		;数据写入缓存
		invoke StrCpy,addr bname,bx  ;写入名字
		add bx,50
		invoke StrCpy,addr bphone,bx  ;写入电话
		add bx,50
		invoke StrCpy,addr baddr,bx  ;写入地址

		;全部写入完成,增加总计数
		mov bx,offset total	
		mov al,ds:[bx]
		inc al
		mov ds:[bx],al	

		;文件修改
		invoke SaveUser
		ret
	AddUser endp
	;完成
	ShowAllUser proc stdcall  uses bx cx si di dx bp
		;获取总数cx
		mov ch,0
		mov bx,offset total 
		mov cl,ds:[bx]
		cmp cx,0;cx等于0，则结束
		jz exitshow

		mov ah,09h
		mov dx,offset enterline

		;循环拿数据
		mov dx,offset datastore
		getmess:
			push dx 
			mov ah,09h
			mov dx,offset enterline
			int 21h
			pop dx

			;打印分割符号
			push dx
			mov ah,09h
			mov dx,offset symbol
			int 21h
			pop dx

			;打印名字
			mov ah,09h
			int 21h	

			push dx 
			mov ah,09h
			mov dx,offset spaceline
			int 21h
			pop dx
			add dx,50

			;打印手机号
			mov ah,09h
			int 21h	

			push dx
			mov ah,09h
			mov dx,offset spaceline
			int 21h
			pop dx
			add dx,50

			;打印地址
			mov ah,09h
			int 21h	

			add dx,50
		loop getmess
		exitshow:
			ret
	ShowAllUser endp

	DelUser proc stdcall  uses bx cx si di dx bp
		local @num1:word  ;总数量
		;打印
		mov ah,09h
		mov dx,offset del1
		int 21h
		;获取输入的字符串   存内存时会自动加一个字节前缀(长度)和 一个字节后缀 0d-回车
		inputname:
			mov ah, 0ah
			mov dx, offset pname
			int 21h
		;空判断
		mov bx, offset pname
		mov al, [bx+1]
		cmp al,0 ;无输入回车
		je inputname;跳转回去			



		;打印输入内容
		mov bx, offset pname
		mov al, [bx+1];起点
		mov ah, 0
		mov si, ax ;将地址写入si
		mov bx, offset bname
		mov byte ptr [bx+si], 24h;写入$---尾部改为$
		mov ah,09h
		mov dx,offset bname;待输出的地址
		int 21h


		;打印换行
		mov ah,09h
		mov dx,offset enterline
		int 21h

		;获取当前存储的用户数量  cx
		mov ch,0
		mov bx,offset total 
		mov cl,ds:[bx]
		cmp cx,0;cx等于0，则结束
		jz exitdel	
		mov @num1,cx

		;求输入名字的长度 结果放在bx
		invoke StrLen,addr bname

		;循环遍历全部用户名  
		mov dx,offset datastore 
		mov ax,1
		findmess:
			push cx
			push ax 

			invoke StrCmp,dx,addr bname

			cmp cx,0
			jz delusermod

			pop ax
			pop cx
			add dx,150
			inc ax
		loop findmess


		;显示 未找到 ---未完成
		jmp exitdel

		;删除用户 用户在dx处
		delusermod:

			;获取后面还有几个
			pop ax   ;当前位置
			pop cx
			mov cx,@num1
			sub cx,ax;剩余个数
			cmp cx,0
			jz decnum
			;移动
			movemess:
				mov bx,dx
				add bx,150
				invoke StrCmp,bx,dx
				add dx,50

				mov bx,dx
				add bx,150
				invoke StrCmp,bx,dx
				add dx,50

				mov bx,dx
				add bx,150
				invoke StrCmp,bx,dx
				add dx,50
			loop movemess
			decnum:
				;全部修改完成,减少总计数
				mov bx,offset total	
				mov al,ds:[bx]
				dec al
				mov ds:[bx],al	
				;文件修改
				invoke saveuser
		exitdel:
			ret
	DelUser endp

	ModUser proc stdcall uses bx cx si di dx bp
		oldmessfind:

			mov ah,09h
			mov dx,offset enterline
			int 21h

			;获取当前存储的用户数量  cx
			mov ch,0
			mov bx,offset total 
			mov cl,ds:[bx]


			;输入旧的名字
			mov ah,09h
			mov dx,offset enterline
			int 21h

			;打印输入提示
			mov ah,09h
			mov dx,offset mod1;打印输入姓名
			int 21h

			;获取输入的字符串   存内存时会自动加一个字节前缀(长度)和 一个字节后缀 0d-回车
			mov ah, 0ah
			mov dx, offset pname
			int 21h

			;空判断
			mov bx, offset pname
			mov al, [bx+1]
			cmp al,0 ;无输入回车
			je oldmessfind;跳转回去		

			;打印输入内容
			mov bx, offset pname
			mov al, [bx+1];起点
			mov ah, 0
			mov si, ax ;将地址写入si
			mov bx, offset bname
			mov byte ptr [bx+si], 24h;写入$---尾部改为$
			mov ah,09h
			mov dx,offset bname;待输出的地址
			int 21h


			;求输入名字的长度 结果放在bx
			invoke strlen,addr bname

			;循环遍历全部用户名  结果位置在dx
			mov dx,offset datastore 
			findmodmess:
				push cx
				invoke StrCmp,dx,addr bname
				cmp cx,0
				jz moduse

				pop cx
				add dx,150
			loop findmodmess
			jmp oldmessfind

			;修改
			moduse:
				pop  cx
				push dx
				modnamebuff:
					mov ah,09h
					mov dx,offset enterline
					int 21h

					;打印输入提示
					mov ah,09h
					mov dx,offset mod2;打印输入姓名
					int 21h

					;获取输入的字符串   存内存时会自动加一个字节前缀(长度)和 一个字节后缀 0d-回车
					mov ah, 0ah
					mov dx, offset pname
					int 21h
					;空判断
					mov bx, offset pname
					mov al, [bx+1]
					cmp al,0 ;无输入回车
					je modnamebuff;跳转回去			

					;打印输入内容
					mov bx, offset pname
					mov al, [bx+1];起点
					mov ah, 0
					mov si, ax ;将地址写入si
					mov bx, offset bname
					mov byte ptr [bx+si], 24h;写入$---尾部改为$
					mov ah,09h
					mov dx,offset bname;待输出的地址
					int 21h

					;换行
					mov ah,09h
					mov dx,offset enterline
					int 21h
				modphonebuff:
					;输入电话提示
					mov ah, 09h
					mov dx, offset mod3
					int 21h
					
					mov ah, 0ah
					mov dx, offset pphone
					int 21h

					;检查是否是空输入
					mov bx, offset pphone
					mov al, [bx+1]
					cmp al,0
					je modphonebuff

					;打印输入内容
					mov bx, offset pphone
					mov al, [bx+1]
					mov ah, 0
					mov si, ax
					mov bx, offset bphone
					mov byte ptr [bx+si], 24h
					mov ah,09h
					mov dx,offset bphone
					int 21h
				
					;换行
					mov ah,09h
					mov dx,offset enterline
					int 21h

				modaddrbuff:
					;输入地址提示
					mov ah, 09h
					mov dx, offset mod4
					int 21h
					
					mov ah, 0ah
					mov dx, offset paddr
					int 21h

					;检查是否是空输入
					mov bx, offset paddr
					mov al, [bx+1]
					cmp al,0
					je modaddrbuff

					;打印输入内容
					mov bx, offset pphone
					mov al, [bx+1]
					mov ah, 0
					mov si, ax
					mov bx, offset baddr
					mov byte ptr [bx+si], 24h
					mov ah,09h
					mov dx,offset baddr
					int 21h
				
					;换行
					mov ah,09h
					mov dx,offset enterline
					int 21h


				pop dx ;取出位置

				;数据写入缓存
				invoke StrCpy,addr bname,dx  ;写入名字
				add dx,50
				invoke StrCpy,addr bphone,dx  ;写入电话
				add dx,50
				invoke StrCpy,addr baddr,dx  ;写入地址
				;文件修改
				invoke SaveUser
			; int 3
			ret
	ModUser endp

	;正在审核
	FindUserByNameBlu proc stdcall uses bx cx si di dx bp
		;打印
		mov ah,09h
		mov dx,offset findname
		int 21h
		;获取输入的字符串   存内存时会自动加一个字节前缀(长度)和 一个字节后缀 0d-回车
		inputnameblu:
			mov ah, 0ah
			mov dx, offset pname
			int 21h
		;空判断
		mov bx, offset pname
		mov al, [bx+1]
		cmp al,0 ;无输入回车
		je inputnameblu;跳转回去

		;打印输入内容
		mov bx, offset pname
		mov al, [bx+1];起点
		mov ah, 0
		mov si, ax ;将地址写入si
		mov bx, offset bname
		mov byte ptr [bx+si], 24h;写入$---尾部改为$
		mov ah,09h
		mov dx,offset bname;待输出的地址
		int 21h


		;打印换行
		mov ah,09h
		mov dx,offset enterline
		int 21h

		;查找
		;获取当前存储的用户数量  cx
		mov ch,0
		mov bx,offset total 
		mov cl,ds:[bx]
		cmp cx,0;cx等于0，则结束
		jz exitblu4	


		;循环遍历全部用户名  
		mov dx,offset datastore 
		findnamemessblu:
			push cx
			invoke StrCmpBlu,dx,addr bname 
			cmp ax,0
			jz successblu
			continue:
				add dx,150
				pop cx
		loop findnamemessblu
		jmp exitblu4

		;显示,之后跳回
		successblu:
			;分割
			push dx
			mov ah,09h
			mov dx,offset symbol
			int 21h
			pop dx

			;打印名字
			mov ah,09h
			int 21h				
			add dx,50

			push dx
			mov ah,09h
			mov dx,offset spaceline
			int 21h
			pop dx

			;打印手机
			mov ah,09h
			int 21h		
			add dx,50

			push dx
			mov ah,09h
			mov dx,offset spaceline
			int 21h
			pop dx

			;打印地址
			mov ah,09h
			int 21h	
			sub dx,100

			push dx
			mov ah,09h
			mov dx,offset enterline
			int 21h
			pop dx

			; ;分割
			; push dx
			; mov ah,09h
			; mov dx,offset symbol
			; int 21h
			; pop dx

			jmp continue



		exitblu4:
			ret
	FindUserByNameBlu endp

	FindUserByPhoneBlu proc stdcall uses bx cx si di dx bp
		;打印
		mov ah,09h
		mov dx,offset findphone
		int 21h
		;获取输入的字符串   存内存时会自动加一个字节前缀(长度)和 一个字节后缀 0d-回车
		inputphoneblu:
			mov ah, 0ah
			mov dx, offset pphone
			int 21h
		;空判断
		mov bx, offset pphone
		mov al, [bx+1]
		cmp al,0 ;无输入回车
		je inputphoneblu;跳转回去			

		;打印输入内容
		mov bx, offset pphone
		mov al, [bx+1];起点
		mov ah, 0
		mov si, ax ;将地址写入si
		mov bx, offset bphone
		mov byte ptr [bx+si], 24h;写入$---尾部改为$
		mov ah,09h
		mov dx,offset bphone;待输出的地址
		int 21h


		;打印换行
		mov ah,09h
		mov dx,offset enterline
		int 21h

		;查找
		;获取当前存储的用户数量  cx
		mov ch,0
		mov bx,offset total 
		mov cl,ds:[bx]
		cmp cx,0;cx等于0，则结束
		jz exitblu5	


		;循环遍历全部用户名  
		mov dx,offset datastore 
		add dx,50
		findphonemessblu:
			push cx

			invoke StrCmpBlu,addr bphone,dx
			cmp cx,0
			jz successphblu
			continueph:
			add dx,150
			pop cx
		loop findphonemessblu
		jmp exitblu5

		;显示,之后跳回
		successphblu:
			;分割
			push dx
			mov ah,09h
			mov dx,offset symbol
			int 21h
			pop dx

			;打印名字
			sub dx,50
			mov ah,09h
			int 21h				
			add dx,50

			push dx
			mov ah,09h
			mov dx,offset spaceline
			int 21h
			pop dx

			;打印手机
			mov ah,09h
			int 21h		
			add dx,50

			push dx
			mov ah,09h
			mov dx,offset spaceline
			int 21h
			pop dx

			;打印地址
			mov ah,09h
			int 21h	
			sub dx,100

			push dx
			mov ah,09h
			mov dx,offset enterline
			int 21h
			pop dx

			add dx,50
			; ;分割
			; push dx
			; mov ah,09h
			; mov dx,offset symbol
			; int 21h
			; pop dx

			jmp continueph



		exitblu5:
			ret
	FindUserByPhoneBlu endp

	FindUserByAddrBlu proc stdcall uses bx cx si di dx bp
		;打印
		mov ah,09h
		mov dx,offset findaddr
		int 21h
		;获取输入的字符串   存内存时会自动加一个字节前缀(长度)和 一个字节后缀 0d-回车
		inputaddrblu:
			mov ah, 0ah
			mov dx, offset paddr
			int 21h
		;空判断
		mov bx, offset paddr
		mov al, [bx+1]
		cmp al,0 ;无输入回车
		je inputaddrblu;跳转回去			

		;打印输入内容
		mov bx, offset paddr
		mov al, [bx+1];起点
		mov ah, 0
		mov si, ax ;将地址写入si
		mov bx, offset baddr
		mov byte ptr [bx+si], 24h;写入$---尾部改为$
		mov ah,09h
		mov dx,offset baddr;待输出的地址
		int 21h


		;打印换行
		mov ah,09h
		mov dx,offset enterline
		int 21h

		;查找
		;获取当前存储的用户数量  cx
		mov ch,0
		mov bx,offset total 
		mov cl,ds:[bx]
		cmp cx,0;cx等于0，则结束
		jz exitblu6	


		;循环遍历全部用户名  
		mov dx,offset datastore 
		add dx,100
		findaddrmessblu:
			push cx

			invoke StrCmpBlu,addr baddr,dx
			cmp cx,0
			jz successphblu
			continueaddr:
			add dx,150
			pop cx
		loop findaddrmessblu
		jmp exitblu6

		;显示,之后跳回
		successphblu:
			;分割
			push dx
			mov ah,09h
			mov dx,offset symbol
			int 21h
			pop dx

			;打印名字
			sub dx,100
			mov ah,09h
			int 21h				
			add dx,50

			push dx
			mov ah,09h
			mov dx,offset spaceline
			int 21h
			pop dx

			;打印手机
			mov ah,09h
			int 21h		
			add dx,50

			push dx
			mov ah,09h
			mov dx,offset spaceline
			int 21h
			pop dx

			;打印地址
			mov ah,09h
			int 21h	
			sub dx,100

			push dx
			mov ah,09h
			mov dx,offset enterline
			int 21h
			pop dx
			
			add dx,100
			jmp continueaddr



		exitblu6:
			ret
	FindUserByAddrBlu endp

	SaveUser proc stdcall uses bx cx si di dx bp
		;打开文件
		
		mov dx,offset filename
		mov al,1 ;写
		mov ah,3dh
		int 21h

		;将返回的文件号写进内存
		mov bx,offset filenum
		mov ds:[bx],ax
		mov bx,ax


		;先写入长度
		mov dx,offset total
		mov cx,1  
		mov ah,40h
		int 21h

		;全部写入文件
		mov dx,offset datastore
		mov cx,5001
		mov ah,40h
		int 21h

		;关闭文件
		mov bx,offset filenum
		mov dx,ds:[bx]
		mov bx,dx
		mov ah,3eh
		int 21h		

		;打印成功提示
		mov ah,09h
		mov dx,offset filesavesucc
		int 21h
		ret
	SaveUser endp

	ReadFile proc stdcall uses bx cx si di dx bp
		;打开文件
		mov dx,offset FILENAME
		mov al,0  ;只读
		mov ah,3dh
		int 21h
		
		;将返回的文件号写进内存
		mov bx,offset FILENUM
		mov ds:[bx],ax;写入文件按句柄
		
		;先读个数
		mov si,offset FILENUM
		mov bx,ds:[si];-----文件句柄,用si中转
		mov dx,offset total
		mov cx,1  
		mov ah,3fh
		int 21h

		;读取5001字节信息----从打开的文件中读取指定长度的字节
		mov si,offset FILENUM
		mov bx,ds:[si]		;-----文件句柄,用si中转
		mov dx,offset datastore;写入缓冲区
		mov cx,5000			;写入长度
		mov ah,3fh
		int 21h
		; int 3

		;关闭文件
		mov dx,ds:[bx]
		mov bx,dx
		mov ah,3eh
		int 21h
		ret
	ReadFile endp



	start:
		;初始化
		Init:
			mov ax,data
			mov ds,ax
			mov es,ax
			mov ax,stack
			mov ss,ax
			mov sp,1000

			;文件读入内存
			invoke ReadFile

		;主程序循环
		MainStart:
            invoke Show
			invoke InputChoose	
			;新增31h	
			add_user:
				cmp al,31h  
				jne del_user
				invoke AddUser;处理函数
				jmp MainStart

			;删除32h
			del_user:
				cmp al,32h  
				jne modify_user
				;处理函数
				jmp MainStart				

			;修改33h
			modify_user:
				cmp al,33h  
				jne find_user_Name
				;处理函数
				jmp MainStart			

			;通过姓名查询34h
			find_user_Name:
				cmp al,34h  
				jne find_user_Phone
				invoke FindUserByNameBlu;处理函数
				jmp MainStart

			;通过手机查询35h
			find_user_Phone:
				cmp al,35h  
				jne find_user_Addr
				invoke FindUserByPhoneBlu;处理函数
				jmp MainStart

			;通过地址查询36h
			find_user_Addr:
				cmp al,36h  
				jne show_all 
				invoke FindUserByAddrBlu;处理函数
				jmp MainStart
		
			;显示所有 37h
			show_all:
				cmp al,37h  
				jne save_file
				invoke ShowAllUser;处理函数
				jmp MainStart	
			
			;保存文件38h
			save_file:
				cmp al,38h  
				jne code_exit
				;处理函数
				jmp MainStart	

			;终止程序--完成	
			code_exit:
				mov ax,4c00h
				int 21h	
code ends
end start