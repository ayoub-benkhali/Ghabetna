from fastapi_mail import FastMail,MessageSchema,ConnectionConfig,MessageType
from app.config import settings
conf=ConnectionConfig(
    MAIL_USERNAME=settings.MAIL_USERNAME,
    MAIL_PASSWORD=settings.MAIL_PASSWORD,
    MAIL_FROM=settings.MAIL_FROM,
    MAIL_PORT=settings.MAIL_PORT,
    MAIL_SERVER=settings.MAIL_SERVER,
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
    USE_CREDENTIALS=True
)
mail=FastMail(conf)

async def send_activation_email(to_email:str,full_name:str,activation_token:str)->None:
    activation_url=f"{settings.FRONTEND_URL}/activate?token={activation_token}"

    html_body=f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2E7D32;">Bienvenue sur Ghabetna 🌲</h2>
        <p>Bonjour <strong>{full_name}</strong>,</p>
        <p>Votre compte a été créé sur la plateforme Ghabetna.</p>
        <p>Cliquez sur le bouton ci-dessous pour activer votre compte et définir votre mot de passe :</p>
        <a href="{activation_url}"
           style="background-color: #2E7D32; color: white; padding: 12px 24px;
                  text-decoration: none; border-radius: 4px; display: inline-block; margin: 16px 0;">
            Activer mon compte
        </a>
        <p style="color: #666; font-size: 12px;">
            Ce lien expire dans 48 heures.<br>
            Si vous n'attendiez pas cet email, ignorez-le.
        </p>
    </div>
    """
    message=MessageSchema(
        subject="Activation de votre compte Ghabetna",
        recipients=[to_email],
        body=html_body,
        subtype=MessageType.html
    )
    await mail.send_message(message)
