#!/bin/bash

logFile=/root/scripts/pjsip-expire.log

mapfile -t pjsipRegistrations < <(docker exec astproxy asterisk -rx 'pjsip show registrations' | grep exp)

printf "$(date) - Quantidade de extensoes: ${#pjsipRegistrations[@]}\n" >> ${logFile}

if pgrep -x "heplify" > /dev/null
then
	printf "$(date) - Processo heplify esta em execucao\n\n" >> ${logFile}
else
	printf "$(date) - Processo heplify NAO esta em execucao\n" >> ${logFile}
	printf "$(date) - Executando processo...\n\n" >> ${logFile}
	sudo bash /root/scripts/heplify-start.sh
fi

for peer in "${pjsipRegistrations[@]}"
do
	extension=$(echo -e ${peer} | awk '{ print $2 }')
	expireValue=$(echo -e ${peer} | awk -F "exp." '{ print $2 }' | awk -F "s)" '{ print $1 }')
	if [[ ${expireValue} -gt 40 ]]
	then
		printf "$(date) - ATENÇÃO: A extensao ${extension} esta com valor de expire acima do esperado (40)\n" >> ${logFile}
		printf "$(date) - Executando comando: docker exec -it astproxy asterisk -rx 'pjsip send unregister ${extension}'\n" >> ${logFile}
		docker exec astproxy asterisk -rx "pjsip send unregister '${extension}'"
		printf "$(date) - Executando comando: docker exec -it astproxy asterisk -rx 'pjsip send register ${extension}'\n" >> ${logFile}
		docker exec astproxy asterisk -rx "pjsip send register '${extension}'"
	else
		printf "$(date) - A extensao ${extension} NAO esta com o valor de expire acima do esperado (40)\n" >> ${logFile}
		printf "$(date) - Valor: ${expireValue}\n\n" >> ${logFile}
	fi
done
