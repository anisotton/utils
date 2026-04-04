#!/bin/bash
DB_NAME=$1
DUMP_FILE=$2

if [ -z "$DB_NAME" ]; then
    read -p "Digite o nome do banco: " DB_NAME
fi

if [ -z "$DUMP_FILE" ]; then
    read -p "Digite o caminho do dump.sql: " DUMP_FILE
fi

echo "Verificando se o banco '$DB_NAME' existe..."
DB_EXISTS=$(mysql -h 127.0.0.1 -P 3306 -u root -e "SHOW DATABASES LIKE '$DB_NAME';" | grep "$DB_NAME")

if [ -z "$DB_EXISTS" ]; then
    echo "Banco '$DB_NAME' não encontrado. Criando agora..."
    mysql -h 127.0.0.1 -P 3306 -u root -e "CREATE DATABASE $DB_NAME;"
    echo "Banco '$DB_NAME' criado com sucesso!"
else
    echo "Banco '$DB_NAME' já existe."
fi

echo "Restaurando dump '$DUMP_FILE' no banco '$DB_NAME'..."
mysql -h 127.0.0.1 -P 3306 -u root "$DB_NAME" < "$DUMP_FILE"

if [ $? -eq 0 ]; then
    echo "Restauração concluída com sucesso!"
else
    echo "Erro na restauração do banco!"
fi
