// LRS-Net | Base Camp Node — RX  (updated: WiFi AP + WebSocket + G:/C: protocol)
// Hardware: ESP32 + RYLR998 LoRa (Serial2) + SSD1306 OLED (I2C)
//
// NEW Libraries to install via Arduino Library Manager:
//   - ESPAsyncWebServer  (by me-no-dev)
//   - AsyncTCP           (by me-no-dev)  ← dependency of above
//   - ArduinoJson        (by Benoit Blanchon)  ← for clean WS messages
//
// Phone connects to WiFi: SSID="LRS-Net"  pass="basecamp1"
// App WebSocket endpoint: ws://192.168.4.1/ws

#include <Wire.h>
#include <U8g2lib.h>
#include <WiFi.h>
#include <ESPAsyncWebServer.h>
#include <ArduinoJson.h>

// ── WiFi AP credentials ───────────────────────────────────────
const char* AP_SSID = "LRS-Net";
const char* AP_PASS = "basecamp1";

// ── LoRa UART ────────────────────────────────────────────────
#define RXD2  16
#define TXD2  17

// ── LEDs ─────────────────────────────────────────────────────
#define LED_BLUE   25
#define LED_GREEN  26

// ── Link timeout ─────────────────────────────────────────────
#define TX_TIMEOUT_MS  10000

// ── OLED ─────────────────────────────────────────────────────
U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE);

// ── Web server + WebSocket ────────────────────────────────────
AsyncWebServer server(80);
AsyncWebSocket ws("/ws");

// ── Parsed data ───────────────────────────────────────────────
String s_txId, s_lat, s_lon, s_fix, s_alt, s_course, s_date, s_time, s_rssi, s_snr;
bool          txOnline        = false;
unsigned long lastRxTime      = 0;

bool          blueLedState    = false;
unsigned long lastBlinkBlue   = 0;
bool          greenLedOn      = false;
unsigned long greenPulseStart = 0;
unsigned long lastDisplayRefresh = 0;

// ── AT command helper ─────────────────────────────────────────
void sendCmd(const String& cmd) {
  Serial2.println(cmd);
  delay(100);
  while (Serial2.available()) Serial.print(char(Serial2.read()));
}

// ── Send LoRa chat message to hiker ──────────────────────────
void sendChat(const String& text) {
  String payload = "C:" + text;
  sendCmd("AT+SEND=1," + String(payload.length()) + "," + payload);
  Serial.println("[CHAT->Hiker] " + text);
}

// ── Broadcast GPS JSON to all WebSocket clients ───────────────
void broadcastGPS() {
  StaticJsonDocument<256> doc;
  doc["type"]   = "gps";
  doc["lat"]    = s_lat;
  doc["lon"]    = s_lon;
  doc["fix"]    = s_fix;
  doc["alt"]    = s_alt;
  doc["course"] = s_course;
  doc["date"]   = s_date;
  doc["time"]   = s_time;
  doc["rssi"]   = s_rssi;
  doc["snr"]    = s_snr;
  String out;
  serializeJson(doc, out);
  ws.textAll(out);
}

// ── Broadcast chat message to all WebSocket clients ───────────
void broadcastChat(const String& text, const String& from) {
  StaticJsonDocument<128> doc;
  doc["type"] = "chat";
  doc["from"] = from;
  doc["text"] = text;
  String out;
  serializeJson(doc, out);
  ws.textAll(out);
}

// ── WebSocket event handler ───────────────────────────────────
void onWsEvent(AsyncWebSocket* server, AsyncWebSocketClient* client,
               AwsEventType type, void* arg, uint8_t* data, size_t len) {
  if (type == WS_EVT_DATA) {
    String msg = String((char*)data).substring(0, len);
    // Expect JSON: {"type":"chat","text":"Hello hiker"}
    StaticJsonDocument<128> doc;
    if (!deserializeJson(doc, msg)) {
      String text = doc["text"].as<String>();
      sendChat(text);                          // forward over LoRa
      broadcastChat(text, "base");             // echo back to all clients
    }
  }
}

// ── OLED ─────────────────────────────────────────────────────
void resetDisplayVars() {
  s_txId = s_lat = s_lon = s_fix = s_alt = "--";
  s_course = s_date = s_time = s_rssi = s_snr = "--";
}

void updateDisplay() {
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_5x7_tr);
  u8g2.drawStr(0,  7, txOnline ? "STATUS: RECEIVING   " : "STATUS: WAITING TX..");
  u8g2.drawStr(0, 15, ("Lat:  " + s_lat + " N").c_str());
  u8g2.drawStr(0, 23, ("Lon:  " + s_lon + " E").c_str());
  String fixLabel = (s_fix=="3") ? "3D" : (s_fix=="0") ? "DFLT" : s_fix;
  u8g2.drawStr(0, 31, ("Fix:" + fixLabel + "  Alt:" + s_alt + "m").c_str());
  u8g2.drawStr(0, 39, ("Course: " + s_course + " deg").c_str());
  u8g2.drawStr(0, 47, ("Date: " + s_date).c_str());
  u8g2.drawStr(0, 55, ("UTC:  " + s_time).c_str());
  u8g2.drawStr(0, 63, ("RSSI:" + s_rssi + "dBm SNR:" + s_snr).c_str());
  u8g2.sendBuffer();
}

// ─────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2);

  pinMode(LED_BLUE,  OUTPUT); digitalWrite(LED_BLUE,  LOW);
  pinMode(LED_GREEN, OUTPUT); digitalWrite(LED_GREEN, LOW);

  // OLED splash
  u8g2.begin();
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_6x10_tr);
  u8g2.drawStr(16, 18, "=== LRS-Net ===");
  u8g2.drawStr(16, 34, "Base Camp Node");
  u8g2.drawStr(10, 50, "Starting WiFi...");
  u8g2.sendBuffer();

  // WiFi AP
  WiFi.softAP(AP_SSID, AP_PASS);
  Serial.print("AP IP: "); Serial.println(WiFi.softAPIP());

  // WebSocket
  ws.onEvent(onWsEvent);
  server.addHandler(&ws);

  // Minimal HTTP root — just tells user to open the app
  server.on("/", HTTP_GET, [](AsyncWebServerRequest* req) {
    req->send(200, "text/plain", "LRS-Net Base Camp. Connect via the app.");
  });

  server.begin();
  Serial.println("WebSocket ready at ws://192.168.4.1/ws");

  // LoRa config
  delay(2000);
  sendCmd("AT+ADDRESS=2");      delay(1000);
  sendCmd("AT+NETWORKID=5");    delay(1000);
  sendCmd("AT+BAND=865000000"); delay(1000);
  sendCmd("AT+BAND?");          delay(1000);
  sendCmd("AT+PARAMETER?");     delay(1000);
  sendCmd("AT+MODE?");          delay(1000);

  resetDisplayVars();
  lastRxTime = millis();
  updateDisplay();
  Serial.println("Ready. Listening for Hiker Node (addr=1)");
}

// ─────────────────────────────────────────────────────────────
void loop() {
  unsigned long now = millis();
  ws.cleanupClients();   // housekeep stale WS connections

  // TX link timeout
  if (txOnline && (now - lastRxTime > TX_TIMEOUT_MS)) {
    txOnline = false;
    Serial.println("[LINK] TX offline");
    updateDisplay();
  }

  // LED management (unchanged from original)
  if (!txOnline) {
    if (now - lastBlinkBlue >= 500) {
      blueLedState = !blueLedState;
      digitalWrite(LED_BLUE, blueLedState ? HIGH : LOW);
      lastBlinkBlue = now;
    }
    if (greenLedOn) { digitalWrite(LED_GREEN, LOW); greenLedOn = false; }
  } else {
    if (blueLedState) { digitalWrite(LED_BLUE, LOW); blueLedState = false; }
    if (greenLedOn && (now - greenPulseStart >= 200)) {
      digitalWrite(LED_GREEN, LOW); greenLedOn = false;
    }
  }

  // ── Receive LoRa ─────────────────────────────────────────────
  if (Serial2.available()) {
    String msg = Serial2.readString();
    msg.trim();

    if (msg.startsWith("+RCV=")) {
      // +RCV=<addr>,<len>,<payload>,...,<rssi>,<snr>
      // Find payload: between 2nd and (last-1)th comma
      int c1 = msg.indexOf(',');
      int c2 = msg.indexOf(',', c1 + 1);
      // rssi and snr are last two comma-separated fields
      int cLast  = msg.lastIndexOf(',');
      int c2Last = msg.lastIndexOf(',', cLast - 1);

      s_txId  = msg.substring(5, c1);
      s_rssi  = msg.substring(c2Last + 1, cLast);
      s_snr   = msg.substring(cLast + 1);
      String payload = msg.substring(c2 + 1, c2Last);

      // ── Route by prefix ──────────────────────────────────────
      if (payload.startsWith("G:")) {
        // GPS packet — parse 7 fields after "G:"
        String data = payload.substring(2);
        const int FC = 6;
        int pos[FC + 1];
        pos[0] = 0;
        bool ok = true;
        for (int i = 1; i <= FC; i++) {
          pos[i] = data.indexOf(',', pos[i-1] + 1);
          if (pos[i] == -1) { ok = false; break; }
        }
        if (ok) {
          s_lat    = data.substring(0,         pos[1]);
          s_lon    = data.substring(pos[1]+1,  pos[2]);
          s_fix    = data.substring(pos[2]+1,  pos[3]);
          s_alt    = data.substring(pos[3]+1,  pos[4]);
          s_course = data.substring(pos[4]+1,  pos[5]);
          s_date   = data.substring(pos[5]+1,  pos[6]);
          s_time   = data.substring(pos[6]+1);

          txOnline   = true;
          lastRxTime = now;
          digitalWrite(LED_GREEN, HIGH);
          greenLedOn = true; greenPulseStart = now;

          Serial.println("[GPS] Lat:" + s_lat + " Lon:" + s_lon + " Fix:" + s_fix);
          updateDisplay();
          broadcastGPS();
        } else {
          Serial.println("[WARN] Malformed G: packet");
        }

      } else if (payload.startsWith("C:")) {
        // Chat message from hiker
        String text = payload.substring(2);
        Serial.println("[CHAT<-Hiker] " + text);
        broadcastChat(text, "hiker");

      } else {
        Serial.println("[LoRa] Unknown prefix: " + payload);
      }

    } else {
      Serial.println("[LoRa] " + msg);
    }
  }

  if (!txOnline && (now - lastDisplayRefresh >= 1000)) {
    lastDisplayRefresh = now;
    updateDisplay();
  }

  delay(10);
}
