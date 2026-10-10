import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLA_PUNTAJES', 'Puntajes')
table = dynamodb.Table(table_name)

def handler(event, context):
    for record in event.get('Records', []):
        try:
            body = json.loads(record['body'])
            jugador = body['jugador']
            juego = body['juego']
            nuevo_puntaje = int(body['puntaje'])
            
            # Buscar si el jugador ya tiene un puntaje registrado en este juego
            response = table.get_item(
                Key={'juego': juego, 'jugador': jugador}
            )
            item = response.get('Item')
            
            # Si existe, verificar si superó su propio récord
            if item:
                puntaje_actual = int(item.get('puntaje', 0))
                if nuevo_puntaje > puntaje_actual:
                    table.put_item(Item={'juego': juego, 'jugador': jugador, 'puntaje': nuevo_puntaje})
                    print(f"Récord actualizado! {jugador} en {juego}: {nuevo_puntaje}")
                else:
                    print(f"No superado. El puntaje {nuevo_puntaje} no vence al actual {puntaje_actual} de {jugador}")
            else:
                # Si no existía, es su primer puntaje en este juego
                table.put_item(Item={'juego': juego, 'jugador': jugador, 'puntaje': nuevo_puntaje})
                print(f"Primer puntaje de {jugador} en {juego}: {nuevo_puntaje}")
                
        except Exception as e:
            print(f"Error procesando mensaje: {e}")
            # Lanzamos la excepción intencionalmente para que SQS sepa que falló
            # y reintente procesarlo (o lo envíe a la DLQ tras 3 intentos)
            raise e
