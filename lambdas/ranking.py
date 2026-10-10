import json
import boto3
import os
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLA_PUNTAJES', 'Puntajes')
table = dynamodb.Table(table_name)

# Helper para convertir los números Decimal de DynamoDB a int de Python
def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError

def handler(event, context):
    query_params = event.get('queryStringParameters') or {}
    juego_filtro = query_params.get('juego')

    try:
        if juego_filtro:
            # Consultar un juego específico
            from boto3.dynamodb.conditions import Key
            response = table.query(
                KeyConditionExpression=Key('juego').eq(juego_filtro)
            )
            items = response.get('Items', [])
            items.sort(key=lambda x: x.get('puntaje', 0), reverse=True)
            resultado = {juego_filtro: items[:10]}
        else:
            # Consultar toda la tabla (Scan) y agrupar
            response = table.scan()
            items = response.get('Items', [])
            juegos = {}
            for item in items:
                j = item['juego']
                if j not in juegos:
                    juegos[j] = []
                juegos[j].append(item)
            
            resultado = {}
            for j, lista in juegos.items():
                lista.sort(key=lambda x: x.get('puntaje', 0), reverse=True)
                resultado[j] = lista[:10]
                
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(resultado, default=decimal_default)
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps(str(e))}
