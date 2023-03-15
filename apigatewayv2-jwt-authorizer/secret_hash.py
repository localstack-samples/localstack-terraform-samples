import base64
import hashlib
import hmac


def generate_secret_hash(client_id, client_secret, username):
    message = bytes(username + client_id, 'utf-8')
    secret = bytes(client_secret, 'utf-8')
    digest = hmac.new(secret, message, hashlib.sha256).digest()
    return base64.b64encode(digest).decode()


client_id = '2apep6q5j2lvnq7fiosbd3apnd'
client_secret = '177hh5h32l1qbifbiialent23ecq04o6g1c4smokghhqm74drspn'
username = 'user@domain.com'
secret_hash = generate_secret_hash(client_id, client_secret, username)

print(secret_hash)
