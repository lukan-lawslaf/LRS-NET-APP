// LRS-Net | Hiker Node — TX  (updated: G:/C: protocol)
// Hardware: ESP32 + Neo-6M GPS (Serial2) + RYLR998 LoRa (Serial1)

#include <TinyGPSPlus.h>

#define GPS_RX_PIN   16
#define GPS_TX_PIN   17
#define LORA_RX_PIN   4
#define LORA_TX_PIN   5

#define DEFAULT_LAT     28.1446f
#define DEFAULT_LON     76.4842f
#define DEFAULT_ALT    235.0f
#define DEFAULT_COURSE   0.0f
#define DEFAULT_FIX      0

#define TX_INTERVAL_MS  5000

TinyGPSPlus gps;

void sendCmd(const String& cmd) {
  Serial1.println(cmd);
  delay(500);
  while (Serial1.available()) Serial.print(char(Serial1.read()));
}

void setup() {
  Serial.begin(115200);
  Serial2.begin(9600,  SERIAL_8N1, GPS_RX_PIN,  GPS_TX_PIN);
  Serial1.begin(115200, SERIAL_8N1, LORA_RX_PIN, LORA_TX_PIN);
  delay(3000);

  Serial.println("=== LRS-Net | Hiker Node (TX) ===");

  sendCmd("AT+ADDRESS=1");      delay(1000);
  sendCmd("AT+NETWORKID=5");    delay(1000);
  sendCmd("AT+BAND=865000000"); delay(1000);
  sendCmd("AT+BAND?");          delay(1000);
  sendCmd("AT+PARAMETER?");     delay(1000);
  sendCmd("AT+MODE?");          delay(1000);

  Serial.println("LoRa ready. Waiting for GPS fix...");
}

void loop() {
  static unsigned long lastTx = 0;

  // Feed GPS
  while (Serial2.available() > 0) gps.encode(Serial2.read());

  // ── Receive incoming LoRa (chat from base camp) ──────────────
  if (Serial1.available()) {
    String incoming = Serial1.readString();
    incoming.trim();
    if (incoming.startsWith("+RCV=")) {
      // +RCV=<addr>,<len>,<payload>,<rssi>,<snr>
      // Find 3rd comma (start of payload after addr,len)
      int c1 = incoming.indexOf(',');
      int c2 = incoming.indexOf(',', c1 + 1);
      int c3 = incoming.lastIndexOf(',');  // rssi starts here — work backwards
      int c4 = incoming.lastIndexOf(',', c3 - 1); // snr field
      String payload = incoming.substring(c2 + 1, c4);
      if (payload.startsWith("C:")) {
        Serial.println("[CHAT] Base Camp: " + payload.substring(2));
      }
    } else {
      Serial.println("[LoRa] " + incoming);
    }
  }

  // ── Transmit GPS every 5 s ────────────────────────────────────
  if (millis() - lastTx >= TX_INTERVAL_MS) {
    lastTx = millis();

    float lat, lon, alt, course;
    int   fix;
    char  dateStr[12], timeStr[10];

    if (gps.location.isValid()) {
      lat    = gps.location.lat();
      lon    = gps.location.lng();
      alt    = gps.altitude.isValid() ? gps.altitude.meters() : DEFAULT_ALT;
      course = gps.course.isValid()   ? gps.course.deg()      : DEFAULT_COURSE;
      fix    = 3;
      if (gps.date.isValid())
        snprintf(dateStr, sizeof(dateStr), "%02d/%02d/%04d",
                 gps.date.day(), gps.date.month(), gps.date.year());
      else strcpy(dateStr, "--/--/----");
      if (gps.time.isValid())
        snprintf(timeStr, sizeof(timeStr), "%02d:%02d:%02d",
                 gps.time.hour(), gps.time.minute(), gps.time.second());
      else strcpy(timeStr, "--:--:--");
      Serial.println("[GPS] Fix OK");
    } else {
      lat = DEFAULT_LAT; lon = DEFAULT_LON; alt = DEFAULT_ALT;
      course = DEFAULT_COURSE; fix = DEFAULT_FIX;
      strcpy(dateStr, "--/--/----"); strcpy(timeStr, "--:--:--");
      Serial.print("[GPS] No fix ("); Serial.print(gps.satellites.value()); Serial.println(" sats)");
    }

    // ── G: prefix added here ──────────────────────────────────
    char payload[110];
    snprintf(payload, sizeof(payload),
             "G:%.6f,%.6f,%d,%.1f,%.1f,%s,%s",
             lat, lon, fix, alt, course, dateStr, timeStr);

    String data = String(payload);
    Serial.print("[TX] "); Serial.println(data);
    sendCmd("AT+SEND=2," + String(data.length()) + "," + data);
  }
}
