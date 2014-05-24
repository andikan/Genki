int NUM_IR = 8;

int PhotoPin = A0;
int value[8];
int mapping[8] = {0, 1, 2, 7, 6, 3, 5, 4};

int S0 = 10;
int S1 = 9;
int S2 = 8;

void setup(){
  Serial.begin(19200);
  pinMode(A0, INPUT);
  pinMode(S0, OUTPUT);
  pinMode(S1, OUTPUT);
  pinMode(S2, OUTPUT);
}

void loop(){
  for (int i = 0; i < NUM_IR; i++){
    digitalWrite(S0, bitRead(i, 0));
    digitalWrite(S1, bitRead(i, 1));
    digitalWrite(S2, bitRead(i, 2));
    value[mapping[i]] = analogRead(PhotoPin);
  }
  
  for (int i = 0; i <NUM_IR; i++){
    Serial.print(value[i]); Serial.print(',');
  }
  Serial.print('\n');
  
  delay(20);
}
