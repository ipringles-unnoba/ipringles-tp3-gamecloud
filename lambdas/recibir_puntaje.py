import json
import boto3
import os

sqs = boto3.client('sqs')
cola_url = os.environ.get('COLA_PUNTAJES_URL')

def handler(event, context):
    try:
        body_str = event.get('body', '{}')
        body = json.loads(body_str)
        
        jugador = body.get('jugador')
        juego = body.get('juego')
        puntaje = body.get('puntaje')
        
        # Validar el formato de los datos
        if not jugador or not juego or puntaje is None or not isinstance(puntaje, int):
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Datos inválidos. Se requiere jugador, juego y puntaje (entero)."})
            }
        
        mensaje = {
            "jugador": str(jugador),
            "juego": str(juego),
            "puntaje": int(puntaje)
        }
        
        # Enviar a SQS
        sqs.send_message(
            QueueUrl=cola_url,
            MessageBody=json.dumps(mensaje)
        )
        
        return {
            "statusCode": 202,
            "body": json.dumps({"mensaje": "Puntaje encolado con éxito"})
        }
        
    except json.JSONDecodeError:
        return {"statusCode": 400, "body": json.dumps({"error": "Formato JSON inválido"})}
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
