
#define BME280_CSB 10

void setup()
{
	
	Serial.begin(115200);
	bme280.init(BME280_CSB);
}


void loop()
{
    double temp_act = 0.0, press_act = 0.0,hum_act=0.0;
    
	bme280.read(&temp_act, &hum_act, &press_act);
	
    Serial.print("TEMP : ");
    Serial.print_double(temp_act,2);
    Serial.print(" DegC  PRESS : ");
    Serial.print_double(press_act,2);
    Serial.print(" hPa  HUM : ");
    Serial.print_double(hum_act,2);
    Serial.println(" %");
	
	sleep(1000);
}

