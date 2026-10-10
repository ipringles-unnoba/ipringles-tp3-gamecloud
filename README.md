# TP3 - Aplicaciones en la Nube (GameCloud)

Repositorio con la resolución del TP3 de Administración Avanzada de Redes y Servidores.

## Requisitos previos
- Docker y Docker Compose
- AWS CLI
- PowerShell (Windows)

## Instrucciones para reproducir la práctica

1. **Levantar el emulador local (MiniStack):**
   \`\`\`powershell
   docker-compose up -d
   \`\`\`

2. **Configurar credenciales de AWS (ficticias):**
   \`\`\`powershell
   `$env:AWS_ACCESS_KEY_ID="test"
   `$env:AWS_SECRET_ACCESS_KEY="test"
   `$env:AWS_DEFAULT_REGION="us-east-1"
   \`\`\`

3. **Ejecutar el script de despliegue:**
   \`\`\`powershell
   cd scripts
   .\01_deploy.ps1
   \`\`\`

4. **Probar la aplicación:**
   - Ingresar desde el navegador a: `http://localhost:4566/gamecloud-web/index.html`
   - Opcionalmente, ejecutar el script de pruebas automatizadas:
     \`\`\`powershell
     .\02_test.ps1
     \`\`\`