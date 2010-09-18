/*
* DCC Driver Circuit Test
*/

int enable_pin = 12;
int drive_a_pin = 13;
int drive_b_pin = 14;

boolean state;

void setup() {
  state = false;
  pinMode(enable_pin, OUTPUT);
  pinMode(drive_a_pin, OUTPUT);
  pinMode(drive_b_pin, OUTPUT);
}
 
void loop() {
  drive(HIGH);
  delay(5000);
  drive(LOW);
}

void drive(boolean level) {
  digitalWrite(enable_pin, LOW);
  digitalWrite(drive_a_pin, level);
  digitalWrite(drive_b_pin, ~level);
  digitalWrite(enable_pin, HIGH);  
}

