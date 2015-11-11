
【概要】
Googleドライブへアクセスするための認証コードを取得し、
GoogleDrivieMonitorスクリプトを実行します。

【実行方法】
①https://console.developers.google.com/ ClientID、ClientSecretを取得する。
②gdrive_sample.rbを実行し、ClientID、ClientSecretをインプットする。
③下記のメニュー1～5を順番に実行します。

    1 Get OAuth2 code get URL.
    2 Get RefreshToken JSON.
    3 write 1 line to spredsheet
	4 create GoogleDriveMonitor
    5 execute GoogleDriveMonitor
    6 quit

【注意点】
SubGHzの無線チャネルが33chに固定されています。変更する場合は
gdrive_sample.rb ファイルを修正してから実行してください。
下記行：
    system("sudo insmod /home/pi/driver/sub-ghz/DRV_802154.ko ch=33")
                                                                ^^^
                                                                ↑を変更する。

