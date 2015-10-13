#define SUBGHZ_CH			36				//チャンネル／周波数です
#define SUBGHZ_PANID		0xABCD			//PANIDです
#define RX_ADDRESS			0xAC54			//受信機のアドレスです

#define BLUE_LED			26				//送信時に青色LEDを点灯させるためのPINです

#define BME280_CSB 10

void setup()
{
	unsigned short myAddress;
	
	Serial.begin(115200);
	
	// Initializing Sub-GHz
	SubGHz.init();
	bme280.init(BME280_CSB);
	
	myAddress = SubGHz.getMyAddress();
	Serial.print("myAddress1 = ");
	Serial.println_long((long)myAddress,HEX);
	
	// initializing GPIO
	pinMode(BLUE_LED,OUTPUT);
	digitalWrite(BLUE_LED,HIGH);
	
}

unsigned char tx_data[128];
void loop()
{
    double temp_act = 0.0, press_act = 0.0,hum_act=0.0;
	
	bme280.read(&temp_act, &hum_act, &press_act);
	
	// 送信するデータを生成する
	Print.init(tx_data,sizeof(tx_data));	//送信用データを初期化
	Print.p("BME280,");						//Raspberry PiがBME280のデータであることを識別するために使用
	Print.d(temp_act,2);					//温度データを小数点2桁で送信
	Print.p(",");							//データの区切りを示すカンマ
	Print.d(hum_act,2);						//湿度データを小数点2桁で送信
	Print.p(",");							//データの区切りを示すカンマ
	Print.d(press_act,2);					//気圧データ
	Print.p(",");							//データの区切りを示すカンマ
	Print.ln();								//改行コード(未使用)
	
	// 920MHzで送信し、その後は無線モジュールを低消費電力モードにする。
	SubGHz.begin(SUBGHZ_CH, SUBGHZ_PANID,  SUBGHZ_100KBPS, SUBGHZ_PWR_20MW);		// 無線モジュールの設定
	digitalWrite(BLUE_LED,LOW);														// LEDを点灯
	SubGHz.send(SUBGHZ_PANID, RX_ADDRESS, &tx_data, Print.len(),NULL);				// send data
	digitalWrite(BLUE_LED,HIGH);													// LEDを消灯
	SubGHz.close();																	// 無線モジュールを待機状態にする
	
	Serial.print("TEMP : ");
    Serial.print_double(temp_act,2);
    Serial.print(" DegC  PRESS : ");
    Serial.print_double(press_act,2);
    Serial.print(" hPa  HUM : ");
    Serial.print_double(hum_act,2);
    Serial.println(" %");
	
	sleep(60000);
}
