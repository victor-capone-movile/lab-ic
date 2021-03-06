#!/bin/bash

#	Instalação:
#	chmod +x test.sh
#
#	Configuração:
#	Alterar o nome da turma
#
#	Modo de uso:
#	./test.sh turma xx

turma="$1"
code="$1/lab$2"
dir="$1/$2.tests"
i=1;

# Se o diretorio nao existe, baixe os arquivos e crie o diretorio

if ( [ -d $dir ] ); then
	echo -e "\033[33m W \033[0m Usando diretorio \033[33m$dir\033[0m local"
else
	echo -e "\033[33m W \033[0m Baixando testes..."
	# Cria o diretorio e baixa o zip
	$(mkdir $dir)
	$(curl -silent -LOk https://susy.ic.unicamp.br:9999/$turma/$2/aux/testes.zip)

	echo -e "\033[33m W \033[0m Descompactando arquivos..."

	# Descompacta os arquivos e deleta o zip
	$(unzip -q testes.zip -d $dir > /dev/null 2>&1)
	$(rm testes.zip)

fi


# Compila
echo -e "\033[31m I \033[0m Compilando $code.c"
$(gcc $code.c -o $code -lm >> $dir/compilation)

# Para cada arquivo em $dir com final .in
errors=$(wc -c $dir/compilation | cut -d" " -f1)
if [ $errors -ge 1 ]; then
	echo "\033[31m W \033[0m Houveram erros na compilação"
	echo "\033[33m+--------------------------------------------------------+"
	cat $dir/compilation
	rm -f $dir/compilation
else

	echo -e "\033[31m I \033[0m Rodando testes"

	for filename in $(pwd)/$dir/*.in; do

		# Retira a extensao do nome do arquivo
		file="${filename%.*}"

		# Itera pelos testes
		printf "\033[33m R \033[0m Teste \033[1m%02d\033[0m... " $i

		# Cria a saida de acordo com a entrada
		$(./$code < $file.in > $file.out)

		# Compara com o resultado esperado e
		# diz se o programa passou ou nao

		$(diff $file.out $file.res > $dir/thediff 2>&1)

		if [ $? != 0 ] 
		then
			echo -e "\033[31m FAIL \033[0m"
			echo -e " \033[1m+--------------------------------------------------------+"
			echo -e "\033[32m EXPECTED\n \033[0m $(cat $dir/thediff | grep '>')"
			echo -e "\033[31m ACTUAL\n \033[0m $(cat $dir/thediff | grep '<')"
			echo -e " \033[1m+--------------------------------------------------------+"
		else
			echo -e "\033[32m OK"
		fi
		# Remove os arquivo de saida
		$(rm $file.out)
		$(rm $dir/thediff)
		# i += 1
		i=`expr $i + 1`
	done
fi
rm -f -r $dir
