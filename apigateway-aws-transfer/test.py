from ftplib import FTP, FTP_TLS

USERNAME="user1"
FTP_USER_DEFAULT_PASSWD="Password1"

def main():
    ftp = FTP()
    print('Connecting to AWS Transfer FTP server on local port %s' % "4510")
    ftp.connect('localhost', port=4510)
    result = ftp.login(USERNAME, FTP_USER_DEFAULT_PASSWD)
    assert 'Login successful.' in result

if __name__ == '__main__':
    main()
