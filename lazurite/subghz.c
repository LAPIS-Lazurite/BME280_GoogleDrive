#define SUBGHZ_CH			36				//�`�����l���^���g���ł�
#define SUBGHZ_PANID		0xABCD			//PANID�ł�
#define RX_ADDRESS			0xAC54			//��M�@�̃A�h���X�ł�

#define BLUE_LED			26				//���M���ɐFLED��_�������邽�߂�PIN�ł�

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
	
	// ���M����f�[�^�𐶐�����
	Print.init(tx_data,sizeof(tx_data));	//���M�p�f�[�^��������
	Print.p("BME280,");						//Raspberry Pi��BME280�̃f�[�^�ł��邱�Ƃ����ʂ��邽�߂Ɏg�p
	Print.d(temp_act,2);					//���x�f�[�^�������_2���ő��M
	Print.p(",");							//�f�[�^�̋�؂�������J���}
	Print.d(hum_act,2);						//���x�f�[�^�������_2���ő��M
	Print.p(",");							//�f�[�^�̋�؂�������J���}
	Print.d(press_act,2);					//�C���f�[�^
	Print.p(",");							//�f�[�^�̋�؂�������J���}
	Print.ln();								//���s�R�[�h(���g�p)
	
	// 920MHz�ő��M���A���̌�͖������W���[��������d�̓��[�h�ɂ���B
	SubGHz.begin(SUBGHZ_CH, SUBGHZ_PANID,  SUBGHZ_100KBPS, SUBGHZ_PWR_20MW);		// �������W���[���̐ݒ�
	digitalWrite(BLUE_LED,LOW);														// LED��_��
	SubGHz.send(SUBGHZ_PANID, RX_ADDRESS, &tx_data, Print.len(),NULL);				// send data
	digitalWrite(BLUE_LED,HIGH);													// LED������
	SubGHz.close();																	// �������W���[����ҋ@��Ԃɂ���
	
	Serial.print("TEMP : ");
    Serial.print_double(temp_act,2);
    Serial.print(" DegC  PRESS : ");
    Serial.print_double(press_act,2);
    Serial.print(" hPa  HUM : ");
    Serial.print_double(hum_act,2);
    Serial.println(" %");
	
	sleep(60000);
}
