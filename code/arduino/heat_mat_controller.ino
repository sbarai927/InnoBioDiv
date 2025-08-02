#include <OneWire.h>               // OneWire library for temperature sensor
#include <DallasTemperature.h>     // Dallas DS18B20 sensor library
#include <SoftwareSerial.h>        // Software serial for ESP8266 communication

// Pin and network configuration
#define ONE_WIRE_BUS 2            // DS18B20 data pin connected to Arduino pin 2
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
SoftwareSerial esp8266(4, 5);     // RX=4, TX=5 for ESP8266 module
#define relay_pin 3               // Relay control pin on Arduino (digital pin 3)

// WiFi credentials and ThingSpeak settings
String AP   = "Optimus";                // WiFi SSID (Access Point name)
String PASS = "3523567370717583";       // WiFi password
String API  = "7C8MLRFZPP8A3OD3";       // ThingSpeak write API Key
String HOST = "api.thingspeak.com";     // ThingSpeak API host URL
String PORT = "80";                     // HTTP port for ThingSpeak

// Globals for ESP8266 communication tracking
int countTrueCommand;
int countTimeCommand;
boolean found = false;

// Variables for temperature and relay state
int threshold = 640;    // DS18B20 raw value threshold (~640 corresponds to 40°C):contentReference[oaicite:10]{index=10}
float temp;             // latest temperature reading (raw or converted)

/**
 * Initialize serial connections and WiFi on startup
 */
void setup() {
  Serial.begin(9600);         // Serial monitor
  pinMode(relay_pin, OUTPUT); // Relay output
  esp8266.begin(115200);      // ESP8266 at 115200 baud
  // Connect to WiFi network via ESP8266 AT commands
  sendCommand("AT", 5, "OK");
  sendCommand("AT+CWMODE=1", 5, "OK");
  sendCommand("AT+CWJAP=\"" + AP + "\",\"" + PASS + "\"", 10, "OK");
}

/**
 * Main loop: read temperature, control relay, and send data to cloud.
 */
void loop() {
  // Request temperature from sensor
  sensors.requestTemperatures();
  float currentC = sensors.getTempCByIndex(0);
  Serial.print("Temperature is: ");
  Serial.print(currentC);
  Serial.println(" °C");
  
  // Prepare data string for ThingSpeak (fields: temperature and relay status):contentReference[oaicite:11]{index=11}
  int relayState = (temp > threshold ? 0 : 1);  // determine relay state (using last raw temp reading)
  String getData = "GET /update?api_key=" + API 
                   + "&field1=" + currentC 
                   + "&field2=" + relayState;
  // Send data via ESP8266 (AT commands sequence)
  sendCommand("AT+CIPMUX=1", 5, "OK");
  sendCommand("AT+CIPSTART=0,\"TCP\",\"" + HOST + "\"," + PORT, 10, "OK");
  sendCommand("AT+CIPSEND=0," + String(getData.length() + 4), 4, ">");
  esp8266.println(getData);
  delay(100);
  countTrueCommand++;
  sendCommand("AT+CIPCLOSE=0", 5, "OK");

  // Manual raw reading of DS18B20 (alternative method to get `temp` in 1/16 °C units)
  byte addr[8];
  if (!oneWire.search(addr)) {
    oneWire.reset_search();
    delay(250);
    return;
  }
  oneWire.reset();
  oneWire.select(addr);
  oneWire.write(0x44, 1);       // start temperature conversion
  delay(100);
  oneWire.reset();
  oneWire.select(addr);
  oneWire.write(0xBE);          // read scratchpad
  byte data[9];
  for (byte i = 0; i < 9; i++) {
    data[i] = oneWire.read();
  }
  // Combine bytes into raw temperature value and control the relay based on threshold
  temp = (data[1] << 8) + data[0];  // raw temperature (16-bit)
  if (temp > threshold) {
    digitalWrite(relay_pin, LOW);   // turn OFF heating mat (reached target temp)
  } else {
    digitalWrite(relay_pin, HIGH);  // turn ON heating mat
  }
}

/**
 * Helper function to return the current relay status as 0 or 1.
 * (0 = OFF, 1 = ON)
 */
int datarelay() {
  if (temp > threshold) {
    return 0;  // relay OFF
  } else {
    return 1;  // relay ON
  }
}

/**
 * Send an AT command to the ESP8266 and wait for a specific reply.
 * Prints the status of each command to Serial for debugging.
 */
void sendCommand(String command, int maxTime, char readReply[]) {
  Serial.print(countTrueCommand);
  Serial.print(". at command => ");
  Serial.println(command);
  // Send command to ESP8266
  found = false;
  countTimeCommand = 0;
  while (countTimeCommand < (maxTime * 1)) {  // (maxTime * 1) yields loop count in 0.1s units
    esp8266.println(command);
    if (esp8266.find(readReply)) {  // got the expected reply
      found = true;
      break;
    }
    countTimeCommand++;
  }
  // Report status
  if (found == true) {
    Serial.println("Connection successful");
    countTrueCommand++;
  } else {
    Serial.println("No Connection");
    countTrueCommand = 0;
  }
}
