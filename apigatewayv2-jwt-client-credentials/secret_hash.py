import base64
import hashlib
import hmac


def generate_secret_hash(client_id, client_secret, username):
    message = bytes(username + client_id, 'utf-8')
    secret = bytes(client_secret, 'utf-8')
    digest = hmac.new(secret, message, hashlib.sha256).digest()
    return base64.b64encode(digest).decode()


client_id = 'l11z7081zypz7s86ysrfnedw9d'
client_secret = '964a2653'
username = 'user@domain.com'
secret_hash = generate_secret_hash(client_id, client_secret, username)

print(secret_hash)
