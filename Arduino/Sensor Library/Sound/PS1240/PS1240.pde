#include <Wire.h>
#include <Sensing.h>
#include <Packet.h>
/*
PreDefines|	PacketType	| DataType
TYPEBOOL	1			  Bool
TYPEINT		2			  Int
TYPEFLOAT	3			  Float
TYPELONG	4			  Long int
TYPEBYTE	5			  Byte
TYPETIME	6			  unsigned long
*/

// User Section: Defines ---------- ---------- ---------- ---------- 
#define PACKET_TYPE 2			// Use the above table as reference
#define DATA_TYPE	int

#define DATA_UNIT	"knock"		// 5 char max

#define ADDRESS_TYPE	false	// True = Preset, False = pin based
#define ADDRESS			2		// Preset Value 
#define ADDRESS_PINS	8,9,10	// Digital Pins to Address off of 
// ---------- ---------- ---------- ---------- ---------- ---------- 

Packet<DATA_TYPE> g_packet;

unsigned long g_timeout;
int g_stage;

// User Section: Sensor Setup	    ---------- ---------- ---------- 
void input()
{
	g_packet.SetReading(analogRead(0));
	g_packet.SetStatus(true);	
}
// ---------- ---------- ---------- ---------- ---------- ---------- 

void setup()
{
#if ADDRESS_TYPE
	SensingNodePreset(ADDRESS);
#else
	SensingNodeAddress(ADDRESS_PINS);
#endif
	g_packet.SetUnit(DATA_UNIT);
}

void loop()
{
	input();
}

//////////////////////////////////////////////////////////////////////////
// Packet Sender
void SendPacket()
{
	// Tell hub the datatype
	if (g_stage == 0){
		Wire.send( PACKET_TYPE );
		g_timeout = millis() + 100;

		// IF TYPENUL, do not stage
		if (PACKET_TYPE != TYPENULL)
			g_stage = 1;
	}
	// Tell hub data
	else if (g_stage == 1) 
	{
		if (g_timeout > millis())
			Wire.send((uint8_t *)&g_packet, sizeof(g_packet));
		g_stage = 0;
	}
	// Tell Hub no data
	else if (g_stage == 3)
	{
		Wire.send( TYPENULL );
	}
}
// Initializer: Preset Address
void SensingNodePreset(unsigned int addr)
{
	g_stage = 0;
	Wire.begin((int)addr);
	Wire.onRequest( SendPacket );
}
// Initializer: Pin Based Address
void SensingNodeAddress(unsigned int pin0, unsigned int pin1, unsigned int pin2)
{
	g_stage = 0;
	// Activate Pins
	pinMode(pin0, INPUT);
	pinMode(pin1, INPUT);
	pinMode(pin2, INPUT);

	//activate internal pullup resistors
	digitalWrite(pin0, HIGH); 
	digitalWrite(pin1, HIGH);
	digitalWrite(pin2, HIGH);

	bool p0 = digitalRead(pin0), p1 = digitalRead(pin1), p2 = digitalRead(pin2);

	unsigned int plugAddr=0;

	if (!digitalRead(pin0))
		plugAddr += 1;

	if(!digitalRead(pin1))
		plugAddr += 2;

	if(!digitalRead(pin2))
		plugAddr += 4;

	Serial.print("[pinAddr]: ");
	Serial.println(plugAddr);

	Wire.begin((int)plugAddr + I2C_ADDRESS_BASE);
	Wire.onRequest( SendPacket );
}