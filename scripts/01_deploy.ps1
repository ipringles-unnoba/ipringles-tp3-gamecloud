`$URL = "--endpoint-url=http://localhost:4566"

Write-Host "1. Creando Bucket S3..."
aws `$URL s3 mb s3://gamecloud-web
aws `$URL s3 website s3://gamecloud-web --index-document index.html
aws `$URL s3 sync ../web s3://gamecloud-web/

Write-Host "2. Creando Tabla DynamoDB..."
aws `$URL dynamodb create-table --table-name Puntajes --attribute-definitions AttributeName=juego,AttributeType=S AttributeName=jugador,AttributeType=S --key-schema AttributeName=juego,KeyType=HASH AttributeName=jugador,KeyType=RANGE --billing-mode PAY_PER_REQUEST

Write-Host "3. Creando Colas SQS..."
aws `$URL sqs create-queue --queue-name puntajes-dlq
aws `$URL sqs create-queue --queue-name puntajes --attributes '{"VisibilityTimeout": "30", "RedrivePolicy": "{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:puntajes-dlq\",\"maxReceiveCount\":\"3\"}"}'

Write-Host "4. Configurando IAM y Lambdas..."
aws `$URL iam create-role --role-name gamecloud-lambda-role --assume-role-policy-document file://../iam/trust-lambda.json
aws `$URL iam put-role-policy --role-name gamecloud-lambda-role --policy-name lambda-permisos --policy-document file://../iam/politica-lambdas.json

cd ../lambdas
Compress-Archive -Path ranking.py -DestinationPath ranking.zip -Force
Compress-Archive -Path recibir_puntaje.py -DestinationPath recibir_puntaje.zip -Force
Compress-Archive -Path procesar_puntaje.py -DestinationPath procesar_puntaje.zip -Force

aws `$URL lambda create-function --function-name ranking --runtime python3.12 --handler ranking.handler --role arn:aws:iam::000000000000:role/gamecloud-lambda-role --zip-file fileb://ranking.zip --environment Variables="{TABLA_PUNTAJES=Puntajes}"
aws `$URL lambda create-function --function-name recibir_puntaje --runtime python3.12 --handler recibir_puntaje.handler --role arn:aws:iam::000000000000:role/gamecloud-lambda-role --zip-file fileb://recibir_puntaje.zip --environment Variables="{COLA_PUNTAJES_URL=http://localhost:4566/000000000000/puntajes}"
aws `$URL lambda create-function --function-name procesar_puntaje --runtime python3.12 --handler procesar_puntaje.handler --role arn:aws:iam::000000000000:role/gamecloud-lambda-role --zip-file fileb://procesar_puntaje.zip --environment Variables="{TABLA_PUNTAJES=Puntajes}"
aws `$URL lambda create-event-source-mapping --function-name procesar_puntaje --batch-size 5 --event-source-arn arn:aws:sqs:us-east-1:000000000000:puntajes
cd ../scripts

Write-Host "5. Creando API Gateway..."
`$API_JSON = aws `$URL apigatewayv2 create-api --name gamecloud-api --protocol-type HTTP --cors-configuration AllowMethods="GET,POST",AllowOrigins="*" | ConvertFrom-Json
`$API_ID = `$API_JSON.ApiId

`$INT_RANKING = (aws `$URL apigatewayv2 create-integration --api-id `$API_ID --integration-type AWS_PROXY --integration-uri arn:aws:lambda:us-east-1:000000000000:function:ranking --payload-format-version 2.0 | ConvertFrom-Json).IntegrationId
`$INT_SCORES = (aws `$URL apigatewayv2 create-integration --api-id `$API_ID --integration-type AWS_PROXY --integration-uri arn:aws:lambda:us-east-1:000000000000:function:recibir_puntaje --payload-format-version 2.0 | ConvertFrom-Json).IntegrationId

aws `$URL apigatewayv2 create-route --api-id `$API_ID --route-key "GET /ranking" --target "integrations/`$INT_RANKING"
aws `$URL apigatewayv2 create-route --api-id `$API_ID --route-key "POST /scores" --target "integrations/`$INT_SCORES"

aws `$URL lambda add-permission --function-name ranking --statement-id apigw-ranking --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:000000000000:`$API_ID/*/*/ranking"
aws `$URL lambda add-permission --function-name recibir_puntaje --statement-id apigw-scores --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:us-east-1:000000000000:`$API_ID/*/*/scores"

aws `$URL apigatewayv2 create-stage --api-id `$API_ID --stage-name "`$default" --auto-deploy --default-route-settings ThrottlingBurstLimit=200,ThrottlingRateLimit=100

"window.GAMECLOUD_API = `"http://${API_ID}.execute-api.localhost:4566`";" | Set-Content -Encoding ascii ../web/config.js
aws `$URL s3 cp ../web/config.js s3://gamecloud-web/config.js

Write-Host "Despliegue finalizado. Sitio disponible en http://localhost:4566/gamecloud-web/index.html"