;Pedro Lago Mondadori 00301506
        assume cs:codigo,ds:dados,es:dados,ss:pilha

CR      EQU    0DH ; constante - codigo ASCII do caractere "carriage return"
LF      EQU    0AH ; constante - codigo ASCII do caractere "line feed"
BACK 	EQU    08H ; constante - codigo ASCII do caractere "backspace"
SPACE   EQU    20H ; constante - codigo ASCII do caractere "space"

; definicao do segmento de dados do programa
dados    segment
nome_cartao  	db		' *********** Nome: Pedro Lago Mondadori ********** Cartao: 00301506 ***********',CR,LF,'$'
pede_arquivo 	db		' nome do arquivo:','$'
erro_abertura   db 		'Erro ao abrir o arquivo','$'
erro_criacao    db 		'Erro ao criar o arquivo','$'
erro_leitura    db      'Erro ao ler arquivo','$'
string_arq		db      'Arquivo ','$'
total_ladr      db      ' - Total de ladrilhos por cor:','$'
o_arquivo       db      'O arquivo ','$'
contem_a        db      ' contem a seguinte quantidade de ladrilhos:',CR,LF,'$'
preto			db		'Preto: ','$'
azul			db		'Azul: ','$'
verde			db		'Verde: ','$'
ciano			db		'Ciano: ','$'
vermelho		db		'Vermelho: ','$' 
magenta			db		'Magenta: ','$'
marrom			db		'Marrom: ','$'
cinza_claro		db		'Cinza claro: ','$'
cinza_escuro	db		'Cinza escuro: ','$'
azul_claro		db		'Azul claro: ','$'
verde_claro		db		'Verde claro: ','$'
ciano_claro		db		'Ciano claro: ','$'
vermelho_claro	db		'Vermelho claro: ','$'
magenta_claro   db		'Magenta claro: ','$'
amarelo			db		'Amarelo: ','$'
barraN			db		CR,LF,'$'
arq_in_nome	 	 		db 	256 	dup	(?)		;nome do arquivo de entrada
arq_out_nome    		db 	256 	dup (?)		;nome do arquivo de saida
arq_in_handler			dw	0					;handler do arquivo de entrada
arq_out_handler			dw	0					;handler do arquivo de saida
arq_buffer			    db  10 		dup (?)		;buffer de leitura do arquivo
largura					db  0					;largura da parede
altura					db  0					;altura da parede
cursor_y				dw  0					;posicao y do cursor
cursor_x				dw  0					;posicao x do cursor
cor_pixel				db  0					;variavel usada para cor
cont					dw  0					;contador auxiliar
cont2					dw  0					;contador auxiliar
cont_cores				db  16		dup (0)		;vetor que guarda a quantidade de ladrilhos de cada cor. indice = cor
centena					db  0
dezena					db  0
unidade					db  0
dados    ends

; definicao do segmento de pilha do programa
pilha   segment stack ; permite inicializacao automatica de SS:SP
        dw     128 dup(?)
pilha   ends

; definicao do segmento de codigo do programa
codigo  segment
inicio:  ; CS e IP sao inicializados com este endereco
        mov    ax,dados ; inicializa DS
        mov    ds,ax    ; com endereco do segmento DADOS
        mov    es,ax    ; idem em ES
		
;TRATAMENTO DO NOME DO ARQUIVO
		call reset_all
		call limpa_buffer
pede_nome:
		call limpa_tela			;limpa a tela
		lea dx,nome_cartao  	;mensagem com o nome do aluno e o cartao
		call printf
		lea dx,pede_arquivo
		call printf	

		call pede_nome_arq
		
		lea bx,arq_in_nome		;testa se a tecla digitada foi apenas enter
		cmp byte ptr[bx],0
		je encerra_enter
	
		call sufixo				;verifica .par
		
		mov al,0				;modo de leitura
		mov ah,3dh				;abre arquivo de entrada
		lea dx,arq_in_nome
		int 21h
		mov arq_in_handler,ax   ;salva o handler do arquivo de entrada
		jnc	abre_saida
				
		lea dx,erro_abertura 	;mensagem de erro na abertura do arquivo de entrada
		call printf
		lea bx,arq_in_nome
		mov byte ptr[bx],0		;limpa o nome do arquivo do arquivo de entrada
		
laco_kbhit1:
		call kbhit
		cmp al,0
		jnz seta_cursor
		jmp laco_kbhit
		
seta_cursor:	
		mov ah,2				;seta a posicao do cursor
		mov dh,1
		mov dl,17
		mov bh,0
		int 10h
		jmp pede_nome

abre_saida:
		call cria_nome_saida	;cria nome do arquivo de saida
		mov cx,0
		mov ah,3ch				;cria arquivo de saida
		lea dx,arq_out_nome
		int 21h
		mov arq_out_handler,ax	;salva o handler do arquivo de saida
		jnc le_parede
		
		lea dx,erro_criacao 	;mensagem de criacao do arquivo de saida
		call printf
		lea bx,arq_out_nome
		mov byte ptr[bx],0		;limpa o nome do arquivo de saida
		mov bx,arq_in_handler
		call fecha_arq			;fecha arquivo de entrada
		jmp seta_cursor
encerra_enter:
		mov ax,4c00h            ; funcao retornar ao DOS no AH
        int 21h                 ; chamada do DOS
		
;COMECA A LEITURA DO ARQUIVO DA PAREDE
le_parede:
		call limpa_tela
		
		mov al,12h				;modo grafico 480x640, 16 cores
		mov ah,0
		int 10h
		
le_antes_virgula:
		mov bx,arq_in_handler	;handler do arquivo
		call getchar			;le altura no arquivo
		jc erro_leitura_arq		
			
		cmp dl,','				;se o caractere for virgula le largura
		jz le_depois_virgula
		
		sub dl,48				;transforma em decimal
		mov al,altura			
		shl al,1
		shl altura,3			;multiplica por 10 10*x = 8*x + 2*x
		add altura,al			;para somar com o proximo digito lido do arquivo
		add altura,dl
		jmp le_antes_virgula
		
le_depois_virgula:
		mov bx,arq_in_handler
		call getchar
		jc erro_leitura_arq
		
		cmp dl,CR
		jz desenha_interface
		
		sub dl,48
		mov al,largura
		shl al,1
		shl largura,3
		add largura,al
		add largura,dl
		jmp le_depois_virgula
		
erro_leitura_arq:
		lea dx,erro_leitura
		call printf
		

desenha_interface:
		lea dx,nome_cartao  	;mensagem com o nome do aluno e o cartao
		call printf
	
;BORDA AMARELA	
		mov bx,0
		mov dx,20
		mov cx,0
		mov cor_pixel,0eh
		mov cont,640
		call linha_h
		mov cont,376
		call linha_v
		add cx,639
		mov cont,376
		call linha_v
		sub cx,640
		add dx,376
		mov cont,640
		call linha_h
		
		mov dh,25
		mov dl,0
		mov bh,0
		mov ah,2
		int 10h
		
		lea dx,string_arq
		call printf
		call cria_string_nome
		lea dx,arq_in_nome
		call printf
		lea dx,total_ladr
		call printf
		
		mov cursor_x,8
		mov cursor_y,28
;FIM BORDA AMARELA

		
le_ladrilhos:	
		mov bx,arq_in_handler
		call getchar
		jc erro_leitura_arq
		
		cmp ax,0
		jz fim_arq
		cmp dl, LF
		jz le_ladrilhos
		cmp dl, CR
		jz nova_linha
		
		call converte_cor
		
		mov al,dl
		call inc_ladr
		call quadrado
		add cursor_x,24
	
		jmp le_ladrilhos
nova_linha:
		add cursor_y,24
		mov cursor_x,8
		jmp le_ladrilhos
fim_arq:
		mov bx,arq_in_handler
		call fecha_arq
		
		call printa_nr_ladr
		call printa_quadrados
		
		call escreve_saida
		
		mov bx,arq_out_handler
		call fecha_arq
				
laco_kbhit:
		call kbhit
		cmp al,0
		jnz roda_dnv
		jmp laco_kbhit
roda_dnv:
		jmp inicio
; retorno ao DOS com codigo de retorno 0 no AL (fim normal)
fim:	
        mov ax,4c00h           ; funcao retornar ao DOS no AH
        int 21h                ; chamada do DOS
		
;-----------------------------SUBROTINAS----------------------------

;===================================================================
;reseta todas as variaveis
;===================================================================
reset_all proc near
		mov arq_in_nome,0 	 		
		mov arq_out_nome,0   		
		mov arq_in_handler,0							
		mov arq_out_handler,0							
		mov arq_buffer,0	   
		mov largura,0								
		mov altura,0								
		mov cursor_y,0				
		mov cursor_x,0			
		mov cor_pixel,0				
		mov cont,0
		mov cont2,0
		lea bx,cont_cores
		mov cx,15
laco_reseta:
		mov byte ptr[bx],0
		inc bx
		loop laco_reseta	
		mov ax,0
		mov bx,0
		mov cx,0
		mov dx,0
		ret
reset_all endp
;===================================================================
;Subrotina de limpar buffer
;===================================================================
limpa_buffer proc near
		mov ah,0ch
		mov al,0
		int 21h
		ret
limpa_buffer endp
;===================================================================
;Escreve uma string na tela
;===================================================================
printf	proc	near
		push ax
		mov ah,9
		int 21h
		pop ax
		ret
printf	endp
;===================================================================
;limpa a tela do terminal
;===================================================================
limpa_tela proc near
		push ax
		mov ah,0h
		mov al,3h
		int 10h
		pop ax
		ret
limpa_tela endp
;===================================================================
;recebe como input do usuario o nome do arquivo que dever ser aberto
;e salva num vetor
;===================================================================
pede_nome_arq proc near
		push ax
		push dx
		push di
		
		lea di,arq_in_nome	;endereco do buffer do nome do arquivo
entrada:
		mov ah,1
        int 21h				;le um caractere com eco
        cmp al,CR   		;eh enter?
        je continua			;sim -> nome foi digitado
		cmp al,BACK			;eh backspace?
		je backspace		;sim -> apaga caractere da tela e do buffer
        mov [di],al 		;coloca caractere digitado no buffer
        inc di				;incrementa ponteiro da string
        jmp entrada			;repete ate enter
backspace:
		mov bh,0
		mov ah,3h
		int 10h
		cmp dl,16
		ja continua_2
		mov dl,17
		mov dh,1
		mov ah,2
		int 10h
		jmp entrada
continua_2:
		dec di				;apaga caractere do buffer
		mov ah,2
		mov dl,SPACE		;imprime espaco na tela
		int 21h
		mov dl,BACK			;volta o cursor 1 posicao
		int 21h
		jmp entrada
continua: 
		mov byte ptr[di],0	;forma string ASCIZ com o nome do arquivo
        mov dl,LF   		;escreve LF na tela
        mov ah,2
        int 21h
		
		pop di
		pop dx
		pop ax
		ret
pede_nome_arq endp
;===================================================================
;trata o nome do arquivo. Testa se ha '.par' e adiciona o sufixo se
;nao houver
;===================================================================
sufixo proc near
		push bx
		lea bx,arq_in_nome
compara_caractere:
		cmp byte ptr[bx],'.'
		jz tem_sufixo
		cmp byte ptr[bx],0
		jz nao_tem
		inc bx
		jmp compara_caractere
nao_tem:
		mov byte ptr[bx],'.'
		inc bx
		mov byte ptr[bx],'p'
		inc bx
		mov byte ptr[bx],'a'
		inc bx
		mov byte ptr[bx],'r'
		inc bx
		mov byte ptr[bx],0
tem_sufixo:
		pop bx
		ret
sufixo endp
;===================================================================
;retira .par do nome do arquivo e adiciona .rel
;===================================================================
cria_nome_saida proc near
		push bx
		push si
		push cx
		
		lea bx,arq_in_nome
		lea si,arq_out_nome
compara_caractere_saida:
		cmp byte ptr[bx],'.'
		jz ponto
		mov cl,byte ptr[bx]
		mov byte ptr[si],cl
		inc bx
		inc si
		jmp compara_caractere_saida
ponto:
		mov byte ptr[si],'.'
		inc si
		mov byte ptr[si],'r'
		inc si
		mov byte ptr[si],'e'
		inc si
		mov byte ptr[si],'l'
		inc si
		mov byte ptr[si],0
		
		pop cx
		pop si
		pop bx
		ret
cria_nome_saida endp
;===================================================================
;funcao que fecha um arquivo
;===================================================================
fecha_arq proc near
		mov ah,3eh
		int 21h
fecha_arq endp
;===================================================================
;le um caractere de um arquivo e salva em dl
;===================================================================
getchar proc near
		push cx

		mov	ah,3fh
		mov	cx,1
		lea	dx,arq_buffer
		int	21h
		mov dl,arq_buffer
		
		pop cx
		ret
getchar endp
;===================================================================
;converte caracteres ascii para inteiros
;===================================================================
converte_cor proc near
		cmp dl,65
		jae eh_caractere
		jmp nao_eh_caractere
eh_caractere:
		sub dl,55
		ret
nao_eh_caractere:
		sub dl,48
		ret
converte_cor endp	
;===================================================================
;desenha uma linha horizontal/vertical na tela
;CX = coluna DX = linha AL = cor do pixel
;===================================================================
linha_h proc near
		push cx
		push dx
desenha:
		mov al,cor_pixel
		mov ah,0ch
		int 10h
		dec cont
		inc cx
		cmp cont,0
		jnz desenha
		
		pop dx
		pop cx
		ret
linha_h endp
linha_v proc near
		push cx
		push dx
desenha2:
		mov al,cor_pixel
		mov ah,0ch
		int 10h
		dec cont
		inc dx
		cmp cont,0
		jnz desenha2
		
		pop dx
		pop cx
		ret
linha_v endp
;===================================================================
;desenha um quadrado na tela
;===================================================================
quadrado proc near
		push ax
		mov cor_pixel,0fh
		mov bx,0
		mov cx,cursor_x
		mov dx,cursor_y
		
		mov cont,24
		call linha_h
		add dx,24
		mov cont,25
		call linha_h
		sub dx,24
		mov cont,24
		call linha_v
		add cx,24
		mov cont,24
		call linha_v
		
		pop ax
		mov cor_pixel,al
		mov cx,cursor_x
		inc cx
		mov dx,cursor_y
		inc dx
		mov cont2,23
desenha3:
		mov cont,23
		call linha_h
		inc dx
		dec cont2
		cmp cont2,0
		jnz desenha3
		ret
		
quadrado endp
;===================================================================
;incrementa os contadores de ladrilhos
;===================================================================
inc_ladr proc near
		push bx
		push ax
		
		lea bx,cont_cores
		cbw
		add bx,ax
		add byte ptr[bx],1
		
		pop ax
		pop bx
		ret
inc_ladr endp
;===================================================================
;ax = numero | separa em centena,dezena e unidade
;===================================================================
itoa proc near
		mov centena,0
		mov dezena,0
		mov unidade,0
laco:
		cmp ax,100
		jae executa_centena
		cmp ax,10
		jae executa_dezena
		mov unidade,al
		
		add centena,48
		add dezena,48
		add unidade,48
		ret
executa_centena:
		inc centena
		sub ax,100
		jmp laco
executa_dezena:
		inc dezena
		sub ax,10
		jmp laco
itoa endp
;===================================================================
;escreve 1 caractere no arquivo de saida
;===================================================================
fputchar proc near
		call itoa
		mov cx,1
		lea dx,centena
		call fprintf
		lea dx,dezena
		call fprintf
		lea dx,unidade
		call fprintf
		lea dx,barraN
		mov cx,2
		call fprintf
		ret
fputchar endp
;===================================================================
;escreve na legenda a quantidade de cada ladrilho da parede
;===================================================================
printa_nr_ladr proc near
		mov dh,28
		mov dl,3
		mov bh,0
		mov ah,2
		int 10h
		lea di,cont_cores
		mov cx,15		
laco_print:
		mov ah,0
		mov al,byte ptr[di]
		call itoa
		inc di
		mov ah,2
		mov dl,centena
		int 21h
		mov dl,dezena
		int 21h
		mov dl,unidade
		int 21h
		mov dl,SPACE
		int 21h
		int 21h
		loop laco_print
		ret
printa_nr_ladr endp
;===================================================================
;desenha a legenda formada por quadrados de todas as cores
;===================================================================
printa_quadrados proc near
		mov cursor_y,420
		mov cursor_x,22
		mov al,0
loop_quadrados:
		call quadrado
		add cursor_x,40
		inc al
		cmp al,15
		jnz loop_quadrados
		ret
printa_quadrados endp
;===================================================================
;al = numero a ser printado na tela
;===================================================================
printa_numero proc near
		push ax
		push bx
		push dx
						;ax/bl
		mov ah,0		;resto em ah
		mov bl,10		;resultado em al
		
		cmp al,9		;al > 9 ?
		jbe um_digito	;printa so um digito
		
		div bl
		
		mov bh,ah		;nao, salva resto
		mov dl,al		;dl = al para printar
		add dl,48       ;traduz para ascii
		mov ah,2
		int 21h			;printa resultado
		mov al,bh		;restaura resto em al
		jmp digito_2
um_digito:
		mov bh,al
		mov dl,0
		add dl,48
		mov ah,2
		int 21h
		mov al,bh
digito_2:
		mov dl,al
		add dl,48
		mov ah,2
		int 21h
		
		pop dx
		pop bx
		pop ax
		
		ret
printa_numero endp
;===================================================================
;adiciona '$' ao final do nome da parede para poder ser printado
;===================================================================
cria_string_nome proc near
		push bx
		lea bx,arq_in_nome
nao_achou:
		cmp byte ptr[bx],0
		jz fim_string
		inc bx
		jmp nao_achou
fim_string:
		mov byte ptr[bx],'$'
		
		pop bx
		ret
cria_string_nome endp
;===================================================================
;escreve uma string num arquivo | DX = endereco da string
;===================================================================
fprintf proc near
		push bx
		mov bx,arq_out_handler
		mov ah,40h
		int 21h
		pop bx
		ret
fprintf endp
;===================================================================
;constroi o arquivo de saida
;===================================================================
escreve_saida proc near	
		lea dx,o_arquivo
		mov cx,10
		call fprintf
		
		mov cx,0
		lea di,arq_in_nome
bytes_nome:
		cmp byte ptr[di],'$'
		jz printa_nome
		inc di
		inc cx
		jmp bytes_nome
printa_nome:
		lea dx,arq_in_nome
		call fprintf
		
		lea dx,contem_a
		mov cx,45
		call fprintf
		
lea di,cont_cores
		lea dx,preto
		mov cx,7
		call fprintf
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,azul
		mov cx,6
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,verde
		mov cx,7
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,ciano
		mov cx,7
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,vermelho
		mov cx,10
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,magenta
		mov cx,9
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,marrom
		mov cx,8
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,cinza_claro
		mov cx,13
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,cinza_escuro
		mov cx,14
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,azul_claro
		mov cx,12
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,verde_claro
		mov cx,13
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,ciano_claro
		mov cx,13
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,vermelho_claro
		mov cx,16
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,magenta_claro
		mov cx,15
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		lea dx,amarelo
		mov cx,9
		call fprintf
			inc di
			mov ah,0
			mov al,byte ptr[di]
			call fputchar
		ret
escreve_saida endp
;===================================================================
;Subrotina de Kbhit AL == 0 se nao houve caractere digitado
;===================================================================
kbhit    proc    near
		mov ah, 0bh
		int 21h
		ret
kbhit    endp
codigo  ends
; a diretiva a seguir indica o fim do codigo fonte (ultima linha do arquivo)
; e informa que o programa deve começar a execucao no rotulo "inicio"
        end    inicio 


