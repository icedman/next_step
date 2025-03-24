#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <Wire.h>

BLEServer *pServer = NULL;
BLECharacteristic *pTxCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;
uint8_t txValue = 0;
char txBuffer[100];
String txString = "BOM";

#define bleServerName "NEXT_STEP_SENSOR"

#define SERVICE_UUID "bd0b40d3-57c6-4dee-9910-22162b1025f7"
#define CHARACTERISTIC_UUID_RX "8aafe8bd-de3a-4887-a222-a708296aaa82"
#define CHARACTERISTIC_UUID_TX "a3610197-9dab-40fe-9df4-dddfc792f0ab"

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) { deviceConnected = true; };

  void onDisconnect(BLEServer *pServer) { deviceConnected = false; }
};

class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String rxValue = pCharacteristic->getValue();

    if (rxValue.length() > 0) {
      Serial.println("*********");
      Serial.print("Received Value: ");
      for (int i = 0; i < rxValue.length(); i++)
        Serial.print(rxValue[i]);

      Serial.println();
      Serial.println("*********");
    }
  }
};
// fb4d7bc8-5260-4246-8e88-0fa92d02f2be
// 0e51f53f-14f0-48a8-9f9d-d80dc1e7cb04
// c264db27-0c56-4a75-83f8-268ffc9d9c15
// 0d35b40c-451e-465e-acd3-ccceef11aae4
// 33e05e2c-ea50-465e-915c-0f7a66c2e5dd

#define TRIG_PIN                                                               \
  23 // ESP32 pin GPIO23 connected to Ultrasonic Sensor's TRIG pin
#define ECHO_PIN                                                               \
  22 // ESP32 pin GPIO22 connected to Ultrasonic Sensor's ECHO pin

#define TRIG_PIN_2                                                             \
  32 // ESP32 pin GPIO23 connected to Ultrasonic Sensor's TRIG pin
#define ECHO_PIN_2                                                             \
  33 // ESP32 pin GPIO22 connected to Ultrasonic Sensor's ECHO pin

#define LED_BUILTIN 2
#define DISTANCE_THRESHOLD 10

#define ENABLE_BLE 1
#define BLE_DELAY 500

int led = 0;
int wait = 0;

void setup() {

  pinMode(LED_BUILTIN, OUTPUT);

  // begin serial port
  Serial.begin(115200);

  // configure the trigger pin to output mode
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(TRIG_PIN_2, OUTPUT);
  // configure the echo pin to input mode
  pinMode(ECHO_PIN, INPUT);
  pinMode(ECHO_PIN_2, INPUT);

#if ENABLE_BLE
  // Create the BLE Device
  BLEDevice::init(bleServerName);

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic
  pTxCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);

  // BLE2902 needed to notify
  pTxCharacteristic->addDescriptor(new BLE2902());

  BLECharacteristic *pRxCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE);

  pRxCharacteristic->setCallbacks(new MyCallbacks());

  // Start the service
  pService->start();

  // Start advertising
  pServer->getAdvertising()->addServiceUUID(pService->getUUID());
  pServer->getAdvertising()->start();
  Serial.println("Waiting a client connection to notify…");
#endif
}

void loop() {
  float duration_us, distance_cm;
  float duration_us_2, distance_cm_2;

  distance_cm = 0;
  distance_cm_2 = 0;

  // generate 10-microsecond pulse to TRIG pin
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  // measure duration of pulse from ECHO pin
  duration_us = pulseIn(ECHO_PIN, HIGH);

  // calculate the distance
  distance_cm = 0.017 * duration_us;

  // generate 10-microsecond pulse to TRIG pin
  digitalWrite(TRIG_PIN_2, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN_2, LOW);

  // measure duration of pulse from ECHO pin
  duration_us_2 = pulseIn(ECHO_PIN_2, HIGH);

  // calculate the distance
  distance_cm_2 = 0.017 * duration_us_2;

  int new_led = 0;
  if ((distance_cm > 0 && distance_cm < DISTANCE_THRESHOLD)) {
    new_led = 1;

    // print the value to Serial Monitor
    Serial.print("distance 1: ");
    Serial.print(distance_cm);
    Serial.println(" cm");
  }

  if ((distance_cm_2 > 0 && distance_cm_2 < DISTANCE_THRESHOLD)) {
    new_led = 1;

    // print the value to Serial Monitor
    Serial.print("distance 2: ");
    Serial.print(distance_cm_2);
    Serial.println(" cm");
  }

  if (new_led != led) {
    led = new_led;
    if (led != 0) {
      digitalWrite(LED_BUILTIN, HIGH);
      // digitalWrite(BUZZER_PIN, HIGH);
    } else {
      digitalWrite(LED_BUILTIN, LOW);
      // digitalWrite(BUZZER_PIN, LOW);
    }
  }


#if ENABLE_BLE
  // disconnecting
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("start advertising");
    oldDeviceConnected = deviceConnected;
  }
  // connecting
  if (deviceConnected && !oldDeviceConnected) {
    // do stuff here on connecting
    oldDeviceConnected = deviceConnected;
  }

  // when a client is connected, sending data
  if (deviceConnected && wait > BLE_DELAY) {
    txString = String(String(distance_cm) + "cm|" + String(distance_cm_2) + String("cm\n"));

    txString.toCharArray(txBuffer, txString.length() + 1);
    pTxCharacteristic->setValue((unsigned char *)txBuffer, txString.length());
    pTxCharacteristic->notify();

    Serial.print(txString);

    wait = 0;
  }

  wait += 250;
#endif

  delay(250);
}
