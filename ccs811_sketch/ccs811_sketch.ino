// read Data from Sparkfun CCS811 Breakout on I2C
// based on https://learn.sparkfun.com/tutorials/ccs811-air-quality-breakout-hookup-guide#arduino-library-and-usage
// 01-2018
// jknofe
#include <SparkFunCCS811.h>
#define CCS811_ADDR 0x5B //Default I2C Address
CCS811 myCCS811(CCS811_ADDR);

typedef enum
{
    SENSOR_SUCCESS,
    SENSOR_ID_ERROR,
    SENSOR_I2C_ERROR,
    SENSOR_INTERNAL_ERROR
} status;

int count = 0;
int retCode = 0;

void setup()
{
	Serial.begin(9600); //This pipes to the serial monitor
	Serial.println("CCS811 Hello");

	retCode = myCCS811.begin();
	myCCS811.setDriveMode(3); // 1 - 1s;  2 - 10s;  3 - 60s
	myCCS811.setEnvironmentalData(42.0, 21.0);

}

void loop()
{
  // main loop delay
  delay(2500);
	count++;
	
	if(retCode != 0){
		printCCS811RetCode(retCode);
	}

	if (myCCS811.dataAvailable())
	{
		myCCS811.readAlgorithmResults();
    
		int tempCO2 = myCCS811.getCO2();
		Serial.print("CCS811 CO2[");
		Serial.print(tempCO2 * 0.0001, DEC);

		int tempVOC = myCCS811.getTVOC();
		Serial.print("]% VOC[");
		Serial.print(tempVOC, DEC);
		Serial.println("]ppb");

    // to do LED indicator with yellow RXLED
	}
	else if (myCCS811.checkForStatusError())
	{
		printSensorError();

	}
	
	// alive led indicator
	TXLED1;
	delay(75);
	TXLED0;
}

void printCCS811RetCode(status retCode){
	Serial.print("CCS811 Init Error Code: ");
	Serial.println(retCode, HEX);
}

//printSensorError gets, clears, then prints the errors
//saved within the error register.
void printSensorError()
{
  uint8_t error = myCCS811.getErrorRegister();

  if ( error == 0xFF ) //comm error
  {
    Serial.print("CCS811 Failed to get ERROR_ID register.");
  }
  else
  {
    Serial.print("CSS811 Error: ");
    if (error & 1 << 5) Serial.print("HeaterSupply");
    if (error & 1 << 4) Serial.print("HeaterFault");
    if (error & 1 << 3) Serial.print("MaxResistance");
    if (error & 1 << 2) Serial.print("MeasModeInvalid");
    if (error & 1 << 1) Serial.print("ReadRegInvalid");
    if (error & 1 << 0) Serial.print("MsgInvalid");
    Serial.println();
  }
}
