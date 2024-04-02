INCLUDE Irvine32.inc
INCLUDE Macros.inc

COMMENT~
	- Brenda Gregan
	- 5/2/23
~
.data
	pos STRUCT
	x BYTE 0
	y BYTE 0
	pos ENDS

	num1 BYTE "0000", 0
	num2 BYTE "0000", 0
	num3 BYTE "0000", 0
	op BYTE 0
	isErr BYTE 0
	endC BYTE 0

	sz1 BYTE 0
	sz2 BYTE 0
	placeI BYTE 0
	placeO BYTE 0
	temp BYTE 5 DUP(0)
	temp2 BYTE 5 DUP(0)

	output pos <18,0> 
	startOp pos <18,1>
	clear pos <12,4>

.code
main proc
	mov eax, white
	call SetTextColor

	mov ecx, 3
	mov ebx, 0

	call display
	call runC
	invoke ExitProcess,0
main endp

COMMENT~
	- displays layout of calculator
~
display PROC
	mov bl, 1
	mGotoxy 0, bl
	mWrite "( 1 ) ( 2 ) ( 3 )"
	mWrite " ( * )"
	call crlf
	mWrite "( 4 ) ( 5 ) ( 6 )"
	mWrite " ( + )"
	call crlf
	mWrite "( 7 ) ( 8 ) ( 9 )"
	mWrite " ( - )"
	call crlf
	mWrite "(    0    ) ( C )"
	mWrite " ( = )"
	ret
display ENDP

COMMENT~
	- continues to collect input
	  and execute operatios until exit or 'e'
	  is pressed

~
runC PROC
	mov ecx, 1
	l1:
		cmp op, 0
		jne next
		mov esi, OFFSET num1
		call getSz
		cmp eax, 0
		jne s2

		s1:
		call getNum
		cmp endC, 1
		je return

		s2:
		cmp op, 0
		jne next
		call getOp
		cmp endC, 1
		je return

		next:	
		call execOp
		cmp endC, 1
		je return
		cmp isErr, 1
		jne cont
		call printErr

		cont:
		inc ecx
	loop l1

	return:
	call clrscr
	mov eax, black 
	call setTextColor
	ret
runC ENDP

COMMENT~
	- takes offset of 4 byte array in esi
	- collects and validates input
	- if digit is pressed digit is stored 
	  in passed array
	- if recognized button is pressed op or endC
	  are set
~
getNum PROC USES eax ebx ecx
	mov ecx, 4

	getDig:
		mov eax, 10
		call Delay
		call ReadKey
		jz getDig
		call isDigit
		jnz check
		PUSH ecx
		mov ecx, 4
		call shiftL
		POP ecx
		mov ebx, 3
		mov [esi][ebx], al
		mov edx, esi
		mGotoxy output.x, output.y
		call WriteString 
	loop getDig
	jmp return

	check:
	call isOp
	cmp op, 0
	jne return

	next:
	cmp al, 'e'
	jne getDig
	mov endC, 1
		
	return:
	ret
getNum ENDP

COMMENT~
	- prints error msg
	- clears all data in num 1 - 3
	- after delay, deletes error msg
~
printErr PROC USES eax
	;cmp isErr, 1
	;jne return
	call clearData
	mov al, output.x
	dec al
	mGotoxy al, output.y
	mWrite "ERROR"
	mov eax, 1000
	call Delay
	mov al, output.x
	dec al
	mGotoxy al, output.y
	mWriteSpace 5
	mov isErr, 0
	return:
	ret
printErr ENDP

COMMENT~
	- checks which operand was pressed and 
	  calls according fxn
	- num2 is cleared at end of fxn
~
execOp PROC USES ebx
	mov bl, startOp.y
	cmp op, '*'
	jne opt2
	call showOp
	call execMult
	jmp return

	opt2:
	inc bl
	cmp op, '+'
	jne opt3
	call execEqu
	call showOp
	call execAdd
	jmp return

	opt3:
	inc bl
	cmp op, '-'
	jne opt4
	call execEqu
	call showOp
	call execSub
	jmp return

	opt4:
	inc bl
	cmp op, '='
	jne opt5
	call showOp
	mov op, 0
	call execEqu
	
	opt5:
	cmp op, 'C'
	jne return
	call exeClear

	return:
	mov edi, OFFSET num2
	call clearNum
	ret
execOp ENDP

COMMENT~
	- displays value in num1
~
execEqu PROC
	mGotoxy output.x, output.y
	mWriteString num1
	ret
execEqu ENDP

COMMENT~
	- gets second operand for multiplication
	- calls multAscii
	- if an operator is also collected then
	  product is displayed
~
execMult PROC 
	mov op, 0
	mov esi, OFFSET num2
	call getNum
	mov esi, OFFSET num1
	mov edi, OFFSET num2
	call multAscii
	cmp isErr, 1
	je return
	cmp op, 0
	je return
	call execEqu
	return:
	ret
execMult ENDP

COMMENT~
	- gets second operand for addition
	  operation
	- once second operand is collected addAscii
	  is called 
	- if op other than * is pressed then result
	  is displayed
~
execAdd PROC USES ebx ecx esi edi
	mov ebx, 1

	mov op, 0
	mov esi, OFFSET num2
	call getNum
	checkMult:
		cmp op, '*'
		jne cont1
		PUSH ebx
		mov bl, startOp.y
		call showOp
		POP ebx
		cmp ebx, 0
		je mult
		call switchNum
		dec ebx
		mult:
		call execMult
		cmp isErr, 1
		je return
		mov edi, OFFSET num2
		call clearNum
	jmp checkMult

	cont1:
	cmp ebx, 1
	je  next
	mov esi, OFFSET num3
	mov edi, OFFSET num2
	mov ecx, 4
	cld
	rep movsb
	mov edi, OFFSET num3
	call clearNum

	next:
	mov esi, OFFSET num1
	mov edi, OFFSET num2
	call addAscii
	cmp op, 0
	je return
	call execEqu

	return:
	ret
execAdd ENDP

COMMENT~
	- gets second operand for subtraction
	  operation
	- once second operand is collected subascii
	  is called 
	- if op other than * is pressed then result
	  is displayed
~
execSub PROC USES ebx ecx esi edi
	mov ebx, 1
	mov op, 0
	mov esi, OFFSET num2
	call getNum
	checkMult:
		cmp op, '*'
		jne cont1
		PUSH ebx
		mov bl, startOp.y
		call showOp
		POP ebx
		cmp ebx, 0
		je mult
		call switchNum
		dec ebx
		mult:
		call execMult
		cmp isErr, 1
		je return
		mov edi, OFFSET num2
		call clearNum
	jmp checkMult

	cont1:
	cmp ebx, 1
	je  next
	mov esi, OFFSET num1
	mov edi, OFFSET num2
	mov ecx, 4
	cld
	rep movsb
	mov esi, OFFSET num3
	mov edi, OFFSET num1
	mov ecx, 4
	cld
	rep movsb
	mov edi, OFFSET num3
	call clearNum

	next:
	mov esi, OFFSET num1
	mov edi, OFFSET num2
	call subAscii
	cmp op, 0
	je return
	call execEqu

	return:
	ret
execSub ENDP

COMMENT~
	- bl holds y pos of button 
	- shows which button was pressed
	- then resets the button display
~
showOp PROC USES eax
	mGotoxy output.x, bl
	mov eax, green
	call SetTextColor
	mWrite "( "
	movzx eax, op
	call WriteChar
	mWrite " )"
	mov eax, white
	call SetTextColor
	mov eax, 1000
	call Delay
	mGotoxy output.x, bl
	mWrite "( "
	movzx eax, op
	call WriteChar
	mWrite " )"
	ret
showOp ENDP

COMMENT~
	- sets all 3 num arrays to be
	  filled with char zeros
~
clearData PROC

	mov edi, OFFSET num1
	call clearNum
	mov edi, OFFSET num2
	call clearNum
	mov edi, OFFSET num3
	call clearNum
	mov op, 0
	ret
clearData ENDP

COMMENT~
	- shows C button was presson on screen
	- calls clearData
	- erases input displayed on screen
	- shows cleared num1 onto screen
~
exeClear PROC
	mGotoxy clear.x, clear.y
	mov eax, green
	call SetTextColor
	mWrite "( C )"
	call clearData
	mov eax, white
	call SetTextColor
	mGotoxy clear.x, clear.y
	mov eax, 500
	call Delay
	mWrite "( C )"
	mGotoxy output.x, output.y
	mWriteString num1
	ret
exeClear ENDP

COMMENT~
	- moves value of num1 into num3
	- moves value of num2 into num1
	- clears num2
~
switchNum PROC USES eax ecx edi esi
	mov esi, OFFSET num1
	mov edi, OFFSET num3
	mov ecx, 4
	cld
	rep movsb				; moves num1 into num3
	mov esi, OFFSET num2
	mov edi, OFFSET num1
	mov ecx, 4
	cld
	rep movsb				; moves num2 into num1
	mov edi, OFFSET num2
	call clearNum			; clears num2
	ret
switchNum ENDP

COMMENT~
	- checks if al stores a recognized operator
	- if so, al is moved into op
	- if not, fxn exits
~
isOp PROC USES ebx
	cmp al, '*'
	je next
	cmp al, '+'
	je next
	cmp al, '-'
	je next
	cmp al, '='
	je next
	cmp al, 'C'
	je next
	jmp return

	next:
	mov op, al
	
	return:
	ret
isOp ENDP

COMMENT~
	- takes array in esi
	- takes size of array in ecx
	- shifts all elements in array over
	  to loeft by 1
~
shiftL PROC USES eax ebx 
	mov eax, 0
	dec ecx
	mov ebx, ecx
	mov al, '0'
	inc ecx
	l1:
		mov ah, [esi][ebx]
		mov [esi][ebx], al
		dec ebx
		mov al, ah
	loop l1

	ret
shiftL ENDP

COMMENT~
	- continually calls readKey until 
	  input is a recognized operator
	- if input is math op or c button, op stores input
	- if input is e for exit, endC is set
~
getOp PROC
	l1:
		mov eax, 10
		call Delay
		call ReadKey
		cmp al, '+'
		je next
		cmp al, '-'
		je next
		cmp al, '*'
		je next
		cmp al, '='
		je next
		cmp al, 'C'
		je next
		cmp al, 'e'
		je n2
	jmp l1

	n2:
	mov endC, 1
	jmp return 

	next:
		mov op, al
	return:
	ret
getOp ENDP

COMMENT~
	- takes offset of arr in edi
	- checks if array only stores char zeros
	- if so, eax = 1
	- if not eax = 0
~
isEmpty PROC USES ecx edi
	mov ecx, 4
	printDig:
		mov eax, [edi]
		cmp al, '0'
		jne notEmpty
		inc edi
	loop printDig
	mov eax, 1
	jmp return

	notEmpty:
	mov eax, 0

	return:
	ret
isEmpty ENDP

COMMENT~
	- takes esi as 1st operand
	- takes edi as 2nd operand
	- add edi to esi
	- returns sum in esi location
	- if sum is too large to fit
	  in 4 bytes, isErr is set
~
addAscii PROC USES eax ecx
	mov eax, 0
	mov ecx, 4
	clc 
	pushfd

	addDig:
		dec ecx
		mov al, [esi][ecx]
		popfd
		adc al, [edi][ecx]
		aaa
		pushfd
		or ax, 30h
		mov [esi][ecx], al
		inc ecx
	loop addDig

	popfd
	jnc return
	mov isErr, 1
	return:
	ret
addAscii ENDP

COMMENT~
	- takes esi as first operand
	- takes edi as second operand
	- subtracts edi from esi
	- returns result in esi location
	- both numbers must have size of 4 bytes
	- if edi > esi, isErr is set
~
subAscii PROC USES eax ecx
	mov eax, 0
	mov ecx, 4
	clc
	pushfd

	subDig:
		dec ecx
		mov al, [esi][ecx]
		popfd
		sbb al, [edi][ecx]
		aas
		pushfd
		or ax, 30h
		mov [esi][ecx], al
		inc ecx
	loop subDig

	popfd
	jnc return
	mov isErr, 1
	return:
	ret
subAscii ENDP

COMMENT~
	- takes esi as first operand offset
	- takes edi as second operand offset
	- multiplies two ascii numbers 
	- returns the product in first op
	  location
	- both numbers must have a size of 4 bytes
	- product must fit in 4 bytes, otherwise
	  isErr is set
~
multAscii PROC USES eax ecx 
	call checkDigit
	cmp eax, 6
	jb cont
	mov isErr,1
	jmp return

	cont:
	mov eax, 0
	add edi, 3
	add esi, 3
	mov placeO, 3

	mov ecx, 4
	outer:
	mov al, placeO
	mov placeI, al
	mov al, [edi]
	aaa
	mov ebx, eax


	PUSH ecx
	movzx ecx, placeI
	inc ecx
	PUSH edi
	PUSH esi
	inner:
		mov al, [esi]			; num1
		aaa
		mul bx					; num1 * num2
		aam
		or ax, 3030h

		PUSH ebx
		movzx ebx, placeI
		cmp bl, 0
		je checkErr
		mov temp2[ebx] - 1, ah
		next:
		mov temp2[ebx], al		; move ascii product into temp
		POP ebx

		PUSH esi
		mov esi, OFFSET temp
		mov edi, OFFSET temp2
		call addAscii			; adds products from placements
		call clearArr
		POP esi
		dec esi
		dec placeI
		mov eax, 0
	loop inner
	POP esi
	POP edi
	POP ecx
	dec edi
	dec placeO
	loop outer

	mov esi, OFFSET temp
	mov edi, OFFSET num1
	mov ecx, 4
	cld
	rep movsb
	jmp return

	checkErr:
		cmp ah, 30h
		je	next
		mov isErr, 1
		POP ebx
		POP esi
		POP edi
		POP ecx
		mov edi, OFFSET temp2
		call clearArr

	return:
	mov edi, OFFSET temp
	call clearNum
	ret
multAscii ENDP

COMMENT~
	- edi must hold offset of array
	- moves 4 zeros into array
~
clearArr PROC USES eax ecx
	mov ecx, 4
	mov al, 0
	cld
	rep stosb
	ret
clearArr ENDP

COMMENT~
	- edi must hold offset of array
	- moves 4 char zeros into array
~
clearNum PROC USES eax ecx
	mov ecx, 4
	mov al, '0'
	cld 
	rep stosb
	ret
clearNum ENDP

COMMENT~
	- esi & edi must hold offset of arrays
	- returns total number of digits in both
	  arrays in eax
~
checkDigit PROC USES ebx esi
	call getSz
	mov bl, al
	mov esi, edi
	call getSz
	add al, bl
	ret
checkDigit ENDP

COMMENT~
	- esi must hold offset of array
	- returns number of digits in array
	  in eax
~
getSz PROC USES ebx ecx esi
	mov ecx, 4
	mov eax, 4
	mov ebx, 0
	l1:
		mov bl, [esi]
		cmp bl, '0'
		jne return
		dec eax
		inc esi
	loop l1

	return:
	ret
getSz ENDP

end main
