`$URL = "--endpoint-url=http://localhost:4566"
`$API_ID = (aws `$URL apigatewayv2 get-apis | ConvertFrom-Json).Items[0].ApiId

Write-Host "Enviando puntajes validos..."
'{"jugador":"pepe","juego":"doom","puntaje":1500}' | Set-Content -Encoding ascii temp.json
curl.exe -i -X POST "http://`$API_ID.execute-api.localhost:4566/scores" -H "Content-Type: application/json" -d "@temp.json"
'{"jugador":"maria","juego":"mario","puntaje":3000}' | Set-Content -Encoding ascii temp.json
curl.exe -i -X POST "http://`$API_ID.execute-api.localhost:4566/scores" -H "Content-Type: application/json" -d "@temp.json"

Write-Host "Consultando ranking..."
curl.exe -s "http://`$API_ID.execute-api.localhost:4566/ranking"

Remove-Item temp.json